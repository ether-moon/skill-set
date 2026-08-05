#!/usr/bin/env python3
"""Validate a staged eval result against its preflight plan."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def load_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError(f"expected a JSON object: {path}")
    return value


def trace_payload(result_file: Path, trace_path: Any) -> dict[str, Any]:
    if not isinstance(trace_path, str) or not trace_path:
        return {"complete": False, "tool_calls": [], "agent_usage": None}
    relative = Path(trace_path)
    if relative.is_absolute() or ".." in relative.parts:
        return {"complete": False, "tool_calls": [], "agent_usage": None}
    resolved = result_file.parent / relative
    try:
        events = [json.loads(line) for line in resolved.read_text(encoding="utf-8").splitlines()]
    except (OSError, json.JSONDecodeError):
        return {"complete": False, "tool_calls": [], "agent_usage": None}
    complete = bool(events) and events[-1].get("type") == "result"
    result_events = [event for event in events if event.get("type") == "result"]
    complete = complete and len(result_events) == 1
    tool_calls: list[dict[str, Any]] = []
    for event in events:
        if event.get("type") != "assistant":
            continue
        for content in event.get("message", {}).get("content", []):
            if content.get("type") == "tool_use":
                tool_calls.append(
                    {
                        "name": content.get("name", ""),
                        "input": content.get("input"),
                    }
                )
    usage = result_events[0].get("usage") if len(result_events) == 1 else None
    return {"complete": complete, "tool_calls": tool_calls, "agent_usage": usage}


def result_cases(result: dict[str, Any]) -> dict[str, dict[str, Any]]:
    cases = result.get("cases")
    if result.get("schemaVersion") != 1 or not isinstance(cases, list):
        raise ValueError("evaluation result is not schema version 1")
    return {
        case["name"]: case
        for case in cases
        if isinstance(case, dict) and isinstance(case.get("name"), str)
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate", type=Path, required=True)
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--metadata", type=Path, required=True)
    parser.add_argument("--plan", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    candidate = load_json(args.candidate)
    baseline = load_json(args.baseline) if args.baseline else None
    metadata = load_json(args.metadata)
    plan = load_json(args.plan)
    candidate_cases = result_cases(candidate)
    baseline_cases = result_cases(baseline) if baseline else {}

    selected_cases = plan.get("selected_cases", [])
    planned_arms = plan.get("arms", [])
    trials = plan.get("trials")
    budget = plan.get("budget", {})
    reasons: list[str] = []
    if metadata.get("stage") != plan.get("stage"):
        reasons.append("metadata stage does not match the preflight plan")
    if metadata.get("arms") != planned_arms:
        reasons.append("metadata arms do not match the preflight plan")
    if sorted(candidate_cases) != sorted(selected_cases):
        reasons.append("candidate cases do not match the preflight plan")
    if "deletion-baseline" in planned_arms:
        if baseline is None or sorted(baseline_cases) != sorted(selected_cases):
            reasons.append("deletion-baseline cases do not match the preflight plan")
    elif baseline is not None:
        reasons.append("an unplanned deletion-baseline result was supplied")

    actual_arms: dict[str, tuple[Path, dict[str, dict[str, Any]], str]] = {
        "candidate": (args.candidate, candidate_cases, "with")
    }
    if candidate.get("suite", {}).get("ablation") == "with-without":
        actual_arms["no-plugin"] = (args.candidate, candidate_cases, "without")
    if baseline is not None:
        actual_arms["deletion-baseline"] = (args.baseline, baseline_cases, "with")
    if list(actual_arms) != planned_arms:
        reasons.append("result arms do not match the preflight plan")

    execution_calls = 0
    judge_calls = 0
    case_summaries: list[dict[str, Any]] = []
    for case_name in selected_cases:
        arm_summaries: dict[str, Any] = {}
        trace_evidence: dict[str, Any] = {}
        token_usage: dict[str, Any] = {}
        for arm_name, (result_file, cases, json_arm) in actual_arms.items():
            case = cases.get(case_name, {})
            runs = case.get("arms", {}).get(json_arm, [])
            if not isinstance(runs, list):
                runs = []
            execution_calls += len(runs)
            qualitative_graders = [
                grader
                for grader in case.get("graders", [])
                if isinstance(grader, dict) and grader.get("type") == "llm"
            ]
            judge_calls += len(qualitative_graders) * len(runs)
            if len(runs) != trials:
                reasons.append(
                    f"{case_name}/{arm_name} has {len(runs)} trials; planned {trials}"
                )
            traces = [trace_payload(result_file, run.get("tracePath")) for run in runs]
            if any(not trace["complete"] for trace in traces):
                reasons.append(f"{case_name}/{arm_name} has incomplete trace evidence")
            arm_summaries[arm_name] = {
                "runs": len(runs),
                "passed": bool(runs) and all(run.get("passed") is True for run in runs),
            }
            trace_evidence[arm_name] = [
                {"complete": trace["complete"], "tool_calls": trace["tool_calls"]}
                for trace in traces
            ]
            token_usage[arm_name] = [
                {
                    "agent": {
                        "available": trace["agent_usage"] is not None,
                        "usage": trace["agent_usage"],
                    }
                }
                for trace in traces
            ]
        case_summaries.append(
            {
                "name": case_name,
                "arms": arm_summaries,
                "trace_evidence": trace_evidence,
                "token_usage": token_usage,
            }
        )

    if budget.get("cases") != len(selected_cases):
        reasons.append("planned case count does not match selected cases")
    if budget.get("arms") != len(planned_arms):
        reasons.append("planned arm count does not match selected arms")
    if budget.get("trials") != trials:
        reasons.append("planned trial count does not match stage trials")
    if budget.get("execution_calls") != execution_calls:
        reasons.append("actual execution calls do not match the preflight plan")
    if budget.get("judge_calls") != judge_calls:
        reasons.append("actual judge calls do not match the preflight plan")
    if budget.get("optimizer_calls") != 0:
        reasons.append("the runner did not execute planned optimizer calls")
    if budget.get("other_calls") != 0:
        reasons.append("the runner did not execute planned other model calls")
    if budget.get("total_calls") != execution_calls + judge_calls:
        reasons.append("actual total calls do not match the preflight plan")

    plan_match = not reasons
    candidate_passed = bool(case_summaries) and all(
        case["arms"].get("candidate", {}).get("passed") is True
        for case in case_summaries
    )
    if not plan_match:
        status = "invalid"
    elif candidate_passed and candidate.get("partial") is not True:
        status = "passed"
    else:
        status = "failed"
    summary = {
        "schema_version": 1,
        "status": status,
        "coverage_status": "partial",
        "plan_match": plan_match,
        "reasons": reasons,
        "stage": plan.get("stage"),
        "arms": planned_arms,
        "trials": trials,
        "cases": case_summaries,
        "actual_calls": {
            "execution_calls": execution_calls,
            "judge_calls": judge_calls,
        },
        "acceptance": {
            "complete": False,
            "current_stage": plan.get("stage"),
            "current_stage_passed": status == "passed",
            "note": "A staged run is partial evidence and never represents whole-suite acceptance.",
        },
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
