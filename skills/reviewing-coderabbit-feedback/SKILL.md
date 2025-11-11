---
name: reviewing-coderabbit-feedback
description: Use when CodeRabbit AI has posted review comments on a PR and you need to classify, apply critical fixes, and report results - automatically processes unresolved feedback by severity with mandatory commit and PR comment workflow
---

# Reviewing CodeRabbit Feedback

## Overview

Automates processing of CodeRabbit AI review comments: classify by severity, auto-apply critical/major issues, report minor suggestions, and ensure complete workflow execution with git commits and PR comments.

**Core principle:** Severity-based automatic execution with guaranteed workflow completion (analyze → apply → commit → report → comment).

## When to Use

**Use when:**
- CodeRabbit has posted review comments on your current PR
- You need to process AI feedback systematically by severity
- You want automatic application of critical and major issues
- You need to ensure complete workflow (no orphaned changes)

**Don't use when:**
- No PR exists or no CodeRabbit comments
- Uncommitted changes exist (must commit first)
- Manual review of each suggestion is required

## Quick Reference

| Phase | Steps | Mandatory |
|-------|-------|-----------|
| **Analysis** | Pre-check → Discover PR → Collect comments → Filter & Classify | Yes |
| **Application** | Auto-apply CRITICAL/MAJOR → Skip MINOR/resolved | Yes |
| **Completion** | Commit & Push → Generate Report → Post PR Comment | **ALWAYS** |

## Severity Classification

### CRITICAL (Auto-Apply Immediately)
- **Security**: SQL injection, XSS, CSRF, auth bypass, sensitive data exposure
- **Data Loss**: Destructive operations, cascade deletes, corruption risks
- **Breaking Bugs**: Nil pointer errors, type crashes, unhandled exceptions
- **Critical Logic**: Payment errors, authorization failures, data integrity violations

### MAJOR (Auto-Apply Immediately)
- **Performance**: N+1 queries, memory leaks, slow algorithms, missing indexes
- **Resource Issues**: File handle leaks, connection pool exhaustion, unbounded loops
- **Significant Bugs**: Wrong calculations, incorrect validations, race conditions
- **Production Impact**: High error rates, significant user impact, reliability issues

### MINOR (Report Only - Do Not Apply)
- **Code Quality**: Variable naming, method extraction, DRY violations
- **Style**: Formatting preferences, comment style, code organization
- **Documentation**: Missing comments, outdated docs, unclear naming
- **Speculative**: "Could be", "might consider", optional improvements

### ALWAYS SKIP (Never Process)
- Comments with resolution markers: ✅☑️🟢 or "resolved", "fixed", "applied"
- Threads with `@coderabbitai resolve` command
- Developer confirmation replies: "Applied", "Done", "Fixed"
- Duplicate suggestions (process once only)

## Workflow

### Phase 1: Analysis & Application

1. **Pre-check**: Verify clean working directory
   ```bash
   git status --porcelain
   # If output exists: "⚠️ 커밋되지 않은 변경사항이 있습니다. 먼저 변경사항을 커밋해주세요." → STOP
   ```

2. **Setup Tracking**: Create TodoWrite todos for ALL workflow steps
   ```markdown
   - [ ] Pre-check git status
   - [ ] Discover PR and collect comments
   - [ ] Filter and classify feedback by severity
   - [ ] Apply CRITICAL/MAJOR changes
   - [ ] Commit and push changes
   - [ ] Generate structured report
   - [ ] Post PR resolution comment
   ```

3. **Discover PR**: Find current PR from branch
   ```bash
   BRANCH=$(git branch --show-current)
   gh pr list --head "$BRANCH" --json number,title,url
   ```

4. **Collect Comments**: Get CodeRabbit feedback (recent-first)
   ```bash
   # Method 1: GraphQL (optimized for recent comments)
   gh api graphql -f query='query($owner:String!, $repo:String!, $number:Int!) {
     repository(owner:$owner, name:$repo) {
       pullRequest(number:$number) {
         comments(last:50) {
           nodes { author { login } body createdAt }
         }
       }
     }
   }' -F owner=OWNER -F repo=REPO -F number=PR_NUMBER | \
   jq '.data.repository.pullRequest.comments.nodes | sort_by(.createdAt) | reverse'

   # Method 2: Simple (with post-sort)
   gh pr view PR_NUMBER --json comments | \
   jq '.comments | sort_by(.createdAt) | reverse | .[:30]'
   ```

5. **Filter**: Process only unresolved CodeRabbit comments
   - Filter for author containing "coderabbitai" or "bot"
   - Exclude bodies with: "resolved", "fixed", "applied", "@coderabbitai resolve"
   - Check entire thread for resolution markers
   - Sort by recency (newest first)

6. **Classify**: Assign severity to each actionable item
   - Extract file path, line number, and specific change
   - Match against severity criteria (CRITICAL > MAJOR > MINOR)
   - Skip summaries without actionable items

7. **Auto-Apply**: Immediately apply CRITICAL and MAJOR without approval
   - Use Edit/MultiEdit tools for code changes
   - Skip MINOR items (report only)
   - Continue on failure (revert and document)

### Phase 2: Mandatory Completion

**⚠️ CRITICAL: NEVER SKIP THIS PHASE - NO EXCEPTIONS ⚠️**

8. **Commit & Push**:
   ```bash
   git add .
   git commit -m "fix: Apply CodeRabbit feedback (CRITICAL/MAJOR)"
   git push
   ```

9. **Generate Report** (Korean):
   ```markdown
   ## CodeRabbit 피드백 처리 완료

   **적용 (X건)**
   - `file.rb:123` - 변경 내용 요약

   **건너뜀 (Y건)**
   - `file.py:789` - MINOR: 코드 스타일 (권장사항)

   **통계**: 총 Z건 | 적용 X건 | 건너뜀 Y건
   ```

10. **Post PR Comment**:
    ```bash
    gh pr comment PR_NUMBER --body "@coderabbitai resolve

    ## CodeRabbit 피드백 처리 완료

    **적용 (X건)**
    - \`file.rb:123\` - 변경 내용 요약

    **통계**: 총 Z건 | 적용 X건 | 건너뜀 Y건"
    ```

11. **Final Verification**:
    - Confirm all TodoWrite items marked completed
    - Output: "✅ 모든 단계 완료: 커밋, 리포트, PR 코멘트"

## PR Comment Template

**MANDATORY FORMAT:**

```markdown
@coderabbitai resolve

## CodeRabbit 피드백 처리 완료

**적용 (X건)**
- `file.rb:123` - 변경 내용 요약
- `file.js:456` - 변경 내용 요약

**건너뜀 (Y건)**
- `file.py:789` - MINOR: 코드 스타일 (권장사항)
- `file.ts:012` - 이미 해결됨

**통계**: 총 Z건 | 적용 X건 | 건너뜀 Y건
```

**Rules:**
1. Line 1 MUST be: `@coderabbitai resolve`
2. Use backticks for file paths: `` `file.ext:line` ``
3. One line per item (concise descriptions)
4. Include statistics at end
5. Korean output for all user-facing text

## Error Handling

| Condition | Action |
|-----------|--------|
| **Uncommitted changes** | Output "⚠️ 커밋되지 않은 변경사항이 있습니다. 먼저 변경사항을 커밋해주세요." → STOP |
| **No PR found** | Try multiple discovery methods, prompt user if all fail |
| **No CodeRabbit comments** | Report "CodeRabbit 피드백이 없습니다" → STOP (no Phase 2) |
| **All resolved** | Report "모든 CodeRabbit 피드백이 이미 해결되었습니다" → STOP (no Phase 2) |
| **No actionable items** | Report summary → STOP (no Phase 2) |
| **Response size limit** | Sort by createdAt DESC → limit to 30 most recent |
| **Apply failures** | Revert, document, continue with others, STILL complete Phase 2 |
| **Push failures** | Retry once, if fails report error but MUST post PR comment |
| **Comment posting fails** | Retry twice, if fails mark as critical failure |

**⚠️ Partial completion is better than no completion - NEVER skip Phase 2 regardless of errors**

## Common Mistakes

### ❌ Skipping Phase 2
**Problem:** Applying changes but not committing/commenting
**Fix:** Phase 2 is MANDATORY - changes without commits are incomplete work

### ❌ Processing Resolved Items
**Problem:** Re-applying already fixed suggestions
**Fix:** Check ENTIRE thread for resolution markers before processing

### ❌ Applying Minor Changes
**Problem:** Auto-applying style/documentation suggestions
**Fix:** Only auto-apply CRITICAL/MAJOR, report MINOR as recommendations

### ❌ Not Sorting by Recency
**Problem:** Processing old comments when hitting size limits
**Fix:** Always sort by createdAt DESC, then limit to recent 30

### ❌ Asking for Approval
**Problem:** Requesting user confirmation for severity-appropriate changes
**Fix:** This is fully automatic - classify severity and proceed

## Success Criteria

- ✅ All CRITICAL and MAJOR issues applied without user interaction
- ✅ All MINOR issues reported as recommendations (not applied)
- ✅ All Phase 2 steps completed (commit exists, report generated, PR comment posted)
- ✅ Final verification confirms all mandatory steps complete
- ❌ If ANY Phase 2 step missing, entire task considered FAILED
- ❌ If asked user for approval, process FAILED (fully automatic)

## Real-World Impact

**Before this skill:**
- Manual classification of 20+ CodeRabbit comments took 15+ minutes
- Risk of orphaned changes (applied but not committed)
- Inconsistent severity assessment
- Missing PR comments left feedback threads unresolved

**After this skill:**
- Automatic processing in 2-3 minutes
- Guaranteed workflow completion (no orphaned changes)
- Consistent severity-based classification
- All threads resolved with proper `@coderabbitai resolve` comments
