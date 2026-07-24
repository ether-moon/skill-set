#!/usr/bin/env python3
"""Stateless preflight gate for model-evaluation plans."""

from __future__ import annotations

import argparse
import json
from dataclasses import asdict, dataclass


DEFAULT_MAX_CALLS = 4
DEFAULT_MAX_TOTAL_TOKENS = 100_000
FALLBACK_TOKENS_PER_CALL = 25_000


def non_negative_int(value: str) -> int:
    parsed = int(value)
    if parsed < 0:
        raise argparse.ArgumentTypeError("must be zero or greater")
    return parsed


def positive_int(value: str) -> int:
    parsed = int(value)
    if parsed <= 0:
        raise argparse.ArgumentTypeError("must be greater than zero")
    return parsed


@dataclass(frozen=True)
class BudgetPlan:
    cases: int
    arms: int
    trials: int
    execution_calls: int
    judge_calls: int
    optimizer_calls: int
    other_calls: int
    total_calls: int
    estimated_tokens_per_call: int
    estimate_source: str
    projected_tokens: int
    max_calls: int
    max_total_tokens: int
    max_total_tokens_is_runtime_hard_cap: bool
    allowed: bool
    reasons: list[str]


def plan_budget(
    *,
    cases: int,
    arms: int,
    trials: int,
    judge_calls: int,
    optimizer_calls: int,
    other_calls: int,
    estimated_tokens_per_call: int,
    estimate_source: str,
    max_calls: int,
    max_total_tokens: int,
) -> BudgetPlan:
    execution_calls = cases * arms * trials
    total_calls = execution_calls + judge_calls + optimizer_calls + other_calls
    projected_tokens = total_calls * estimated_tokens_per_call
    reasons: list[str] = []

    if total_calls > max_calls:
        reasons.append(f"model calls {total_calls} exceed limit {max_calls}")
    if projected_tokens > max_total_tokens:
        reasons.append(
            f"projected tokens {projected_tokens} exceed limit {max_total_tokens}"
        )

    return BudgetPlan(
        cases=cases,
        arms=arms,
        trials=trials,
        execution_calls=execution_calls,
        judge_calls=judge_calls,
        optimizer_calls=optimizer_calls,
        other_calls=other_calls,
        total_calls=total_calls,
        estimated_tokens_per_call=estimated_tokens_per_call,
        estimate_source=estimate_source,
        projected_tokens=projected_tokens,
        max_calls=max_calls,
        max_total_tokens=max_total_tokens,
        max_total_tokens_is_runtime_hard_cap=False,
        allowed=not reasons,
        reasons=reasons,
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Plan and gate model invocations before an evaluation. "
            "The token limit is a conservative preflight estimate, not a runtime hard cap."
        )
    )
    parser.add_argument("--cases", type=positive_int, required=True)
    parser.add_argument("--arms", type=positive_int, default=1)
    parser.add_argument("--trials", type=positive_int, default=1)
    parser.add_argument("--judge-calls", type=non_negative_int, default=0)
    parser.add_argument("--optimizer-calls", type=non_negative_int, default=0)
    parser.add_argument("--other-calls", type=non_negative_int, default=0)
    parser.add_argument(
        "--estimated-tokens-per-call",
        type=positive_int,
        help=(
            "Recent equivalent-trace p95 when available; otherwise the planner "
            f"uses the {FALLBACK_TOKENS_PER_CALL}-token fallback."
        ),
    )
    parser.add_argument("--max-calls", type=positive_int, default=DEFAULT_MAX_CALLS)
    parser.add_argument(
        "--max-total-tokens",
        "--max-tokens",
        dest="max_total_tokens",
        type=positive_int,
        default=DEFAULT_MAX_TOTAL_TOKENS,
    )
    parser.add_argument("--json", action="store_true")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    estimated_tokens_per_call = (
        args.estimated_tokens_per_call or FALLBACK_TOKENS_PER_CALL
    )
    estimate_source = (
        "recent_equivalent_trace_p95"
        if args.estimated_tokens_per_call is not None
        else "fallback"
    )
    plan = plan_budget(
        cases=args.cases,
        arms=args.arms,
        trials=args.trials,
        judge_calls=args.judge_calls,
        optimizer_calls=args.optimizer_calls,
        other_calls=args.other_calls,
        estimated_tokens_per_call=estimated_tokens_per_call,
        estimate_source=estimate_source,
        max_calls=args.max_calls,
        max_total_tokens=args.max_total_tokens,
    )

    if args.json:
        print(json.dumps(asdict(plan), indent=2, sort_keys=True))
    else:
        print(f"allowed={str(plan.allowed).lower()}")
        print(
            f"execution_calls={plan.execution_calls} total_calls={plan.total_calls} "
            f"max_calls={plan.max_calls}"
        )
        print(
            f"projected_tokens={plan.projected_tokens} "
            f"max_total_tokens={plan.max_total_tokens} "
            f"estimated_tokens_per_call={plan.estimated_tokens_per_call} "
            f"estimate_source={plan.estimate_source}"
        )
        print("max_total_tokens_note=preflight estimate; not a runtime hard cap")
        if plan.reasons:
            for reason in plan.reasons:
                print(f"reason={reason}")
        else:
            print("reasons=none")

    return 0 if plan.allowed else 2


if __name__ == "__main__":
    raise SystemExit(main())
