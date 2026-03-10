---
name: coderabbit-feedback
description: Use when CodeRabbit AI has posted review comments on a PR - interactively classify feedback by severity, discuss recommendations with user, apply agreed changes, and ensure mandatory commit and PR comment workflow with verification
---

# CodeRabbit Feedback

## Overview

Interactive processing of CodeRabbit AI review comments through user conversation: collect and classify feedback, discuss CRITICAL/MAJOR items for immediate action, analyze MINOR items with recommendations, and complete workflow with verified git commits and PR comments.

**Core principle:** Interactive severity-based workflow with user conversation (collect → discuss → apply together → verify completion).

## When to Use

**Use when:**
- CodeRabbit has posted review comments on your current PR
- You need to process AI feedback with user input
- You want to discuss which suggestions to apply
- You need guided review with recommendations and rationale

**Don't use when:**
- No PR exists or no CodeRabbit comments
- Uncommitted changes exist (must commit first)
- Fully automated processing without interaction is required

## Quick Reference

| Phase | Mode | Key Actions |
|-------|------|-------------|
| **Collection** | Auto | Pre-check → Discover PR → Collect 200 comments → Filter & Classify |
| **Discussion** | **Interactive** | Present items → Get user decisions → Analyze MINOR with rationale |
| **Application** | Auto | Apply agreed changes → Commit & Push |
| **Verification** | Auto | Post PR comment → Verify @coderabbitai resolve tag |

## Severity Classification

### CRITICAL (Immediate Discussion Required)
- **Security**: SQL injection, XSS, CSRF, auth bypass, sensitive data exposure
- **Data Loss**: Destructive operations, cascade deletes, corruption risks
- **Breaking Bugs**: Nil pointer errors, type crashes, unhandled exceptions
- **Critical Logic**: Payment errors, authorization failures, data integrity violations

### MAJOR (Important Discussion)
- **Performance**: N+1 queries, memory leaks, slow algorithms, missing indexes
- **Resource Issues**: File handle leaks, connection pool exhaustion, unbounded loops
- **Significant Bugs**: Wrong calculations, incorrect validations, race conditions
- **Production Impact**: High error rates, significant user impact, reliability issues

### MINOR (Analyze & Recommend)
- **Code Quality**: Variable naming, method extraction, DRY violations
- **Style**: Formatting preferences, comment style, code organization
- **Documentation**: Missing comments, outdated docs, unclear naming
- **Speculative**: "Could be", "might consider", optional improvements

### ALWAYS SKIP (Never Process)
- Comments with resolution markers: ✅☑️🟢 or "resolved", "fixed", "applied"
- Threads with `@coderabbitai resolve` command
- Developer confirmation replies: "Applied", "Done", "Fixed"
- Duplicate suggestions (process once only)

## Language Detection

**IMPORTANT: Detect and use user's preferred language for all communication.**

**Detection priority (check in order):**
1. **User's current messages** - What language is the user speaking in this conversation?
2. **Project context** - Check CLAUDE.md, README.md, recent commits for language patterns
3. **Git history** - `git log --oneline -5` to see commit message language
4. **Default** - If no clear indication, use **English**

**Apply detected language to:**
- All conversational messages with user
- PR comment content
- Reports and summaries
- Error messages and warnings
- Status updates

**Always keep in English:**
- Code examples
- Bash commands and scripts
- File paths
- Technical API calls

**Language variable usage in templates:**
```
[In user's language]  ← This marker means content should be in detected language
```

**Example detection:**
```
# User writes in Korean → Use Korean
# User writes in English → Use English
# User writes in Spanish → Use Spanish
# No clear signal → Use English (default)
```

## Mandatory Workflow Tracking

**IMMEDIATELY after discovering the PR, before collecting comments, create these tasks:**

```
TaskCreate: "Collect and classify CodeRabbit comments"
TaskCreate: "Discuss feedback with user"
TaskCreate: "Apply agreed changes"
TaskCreate: "Commit and push changes"
TaskCreate: "Post PR comment with @coderabbitai resolve"
TaskCreate: "Verify PR comment posted"
```

**Rules:**
- Create ALL tasks before starting comment collection
- Set each task to `in_progress` when starting it, `completed` when done
- Before reporting completion to the user, run `TaskList` and confirm zero pending tasks
- Never skip a task. If a task cannot be completed, explain why to the user instead of silently moving on.

### Phase 1: Collection

1. **Discover PR**: Find current PR from branch
   ```bash
   BRANCH=$(git branch --show-current)
   gh pr list --head "$BRANCH" --json number,title,url
   ```

4. **Collect Comments with Pagination** (up to 200 comments):

   **Method 1: GraphQL with Pagination (Recommended)**
   ```bash
   get_all_comments() {
     local pr_number=$1
     local owner=$2
     local repo=$3
     local cursor=""
     local has_next=true
     local all_comments="[]"

     while [ "$has_next" = "true" ]; do
       local query='query($owner:String!, $repo:String!, $number:Int!, $cursor:String) {
         repository(owner:$owner, name:$repo) {
           pullRequest(number:$number) {
             comments(first:100, after:$cursor) {
               pageInfo { hasNextPage endCursor }
               nodes {
                 id
                 author { login }
                 body
                 createdAt
                 replies(first:10) {
                   nodes { author { login } body createdAt }
                 }
               }
             }
           }
         }
       }'

       local result=$(gh api graphql -f query="$query" \
         -F owner="$owner" -F repo="$repo" -F number="$pr_number" \
         ${cursor:+-F cursor="$cursor"})

       local page_comments=$(echo "$result" | jq '.data.repository.pullRequest.comments.nodes')
       all_comments=$(echo "$all_comments" | jq ". + $page_comments")

       has_next=$(echo "$result" | jq -r '.data.repository.pullRequest.comments.pageInfo.hasNextPage')
       cursor=$(echo "$result" | jq -r '.data.repository.pullRequest.comments.pageInfo.endCursor')

       [ "$has_next" = "false" ] && break
       [ $(echo "$all_comments" | jq 'length') -ge 200 ] && break
     done

     echo "$all_comments" | jq 'sort_by(.createdAt) | reverse | .[:200]'
   }
   ```

   **Method 2: REST API with Pagination (Alternative)**
   ```bash
   get_all_comments_rest() {
     local pr_number=$1
     local page=1
     local per_page=100
     local all_comments="[]"

     while [ $page -le 2 ]; do  # Max 2 pages = 200 comments
       local result=$(gh api "repos/$OWNER/$REPO/issues/$pr_number/comments?per_page=$per_page&page=$page")

       [ "$(echo "$result" | jq 'length')" -eq 0 ] && break

       all_comments=$(echo "$all_comments" | jq ". + $result")
       ((page++))
     done

     echo "$all_comments" | jq 'sort_by(.created_at) | reverse | .[:200]'
   }
   ```

5. **Filter**: Process only unresolved CodeRabbit comments
   - Filter for author containing "coderabbitai" or "bot"
   - Exclude bodies with: "resolved", "fixed", "applied", "@coderabbitai resolve"
   - Check entire thread (including replies) for resolution markers
   - Sort by recency (newest first)

6. **Classify**: Assign severity to each actionable item
   - Extract file path, line number, and specific change
   - Match against severity criteria (CRITICAL > MAJOR > MINOR)
   - Skip summaries without actionable items

### Phase 2: Interactive Discussion

**Step 2.1 - Present Summary and CRITICAL/MAJOR Items:**

```
[In user's language]

Found feedback: 23 items total
- CRITICAL: 2 items (security vulnerability 1, data loss risk 1)
- MAJOR: 5 items (performance issues 3, significant bugs 2)
- MINOR: 16 items (code quality improvements)

## Items Requiring Immediate Attention (CRITICAL/MAJOR 7 items)

### CRITICAL
1. `auth/login.ts:45` - SQL Injection vulnerability
   - Issue: User input directly in query
   - Suggestion: Use prepared statements
   - Risk: ⚠️ High (security)

2. `data/sync.ts:89` - Data loss risk
   - Issue: Sequential deletes without transaction
   - Suggestion: Add transaction wrapper
   - Risk: ⚠️ High (data integrity)

### MAJOR
3. `api/users.ts:123` - N+1 query problem
   - Issue: Individual queries in loop
   - Suggestion: Use eager loading for batch retrieval
   - Impact: Performance (currently 101 queries for 100 items)

4. `cache/redis.ts:56` - Memory leak
   - Issue: Missing connection close
   - Suggestion: Add close() in finally block
   - Impact: Resource exhaustion

[...more items]

How would you like to proceed?
- [1] Apply all (recommended - CRITICAL/MAJOR are mandatory fixes)
- [2] Review individually (confirm each item)
- [3] See details first
- [4] Start with MINOR analysis
```

**Step 2.2 - Individual Selection Mode (Option 2):**

```
[In user's language]

Reviewing each item individually.

[1/7] CRITICAL: `auth/login.ts:45` - SQL Injection vulnerability

Current code:
```typescript
const user = await db.query(
  `SELECT * FROM users WHERE email = '${email}'`
);
```

Suggested change:
```typescript
const user = await db.query(
  'SELECT * FROM users WHERE email = $1',
  [email]
);
```

**CodeRabbit Analysis:**
- SQL Injection attack possible
- Risk of full data breach with malicious input

**Severity:** ⚠️ CRITICAL (immediate fix required)

Apply this change? [Y/n/skip]
> Y

✅ Added to apply list

[2/7] CRITICAL: `data/sync.ts:89` - Data loss risk
[...]
```

**Step 2.3 - MINOR Analysis & Recommendations:**

```
[In user's language]

✅ CRITICAL/MAJOR selection complete (7 items)

Now analyzing 16 MINOR recommendations.
Reviewing each item to provide application recommendations.

[Analyzing...]

## MINOR Recommendations Analysis Complete

### ✅ Recommended to Apply (4 items)
Items with clear improvement benefits.

1. `utils/format.ts:34` - Variable name clarification (`data` → `formattedUserData`)
   - Rationale: Improved type inference, better readability, avoids conflicts with other data variables in scope
   - Impact: Very low (variable rename only, 5 lines)
   - Expected benefit: Increased code comprehension, easier maintenance
   - Recommendation: ✅ Apply

2. `api/response.ts:67` - Error handling improvement
   - Current: try-catch만 있고 에러 로깅 없음
   - Suggestion: logger.error() 추가
   - Rationale: 프로덕션 디버깅 시 에러 추적 불가능
   - Impact: 낮음 (1줄 추가)
   - Expected benefit: 문제 발생 시 빠른 원인 파악
   - recommended: ✅ applied / apply

3. `models/user.ts:123` - Remove type assertion
   - Current: `as User` 강제 캐스팅
   - Suggestion: 타입 가드 함수 사용
   - Rationale: 런타임 타입 불일치 위험
   - Impact: 중간 (타입 가드 함수 추가 필요, 10줄)
   - Expected benefit: 타입 안정성 증가
   - recommended: ✅ applied / apply

4. `services/notification.ts:45` - Extract magic number to constant
   - Current: `setTimeout(() => ..., 5000)`
   - Suggestion: `const RETRY_DELAY_MS = 5000`
   - Rationale: 의미 명확화, 재사용 가능
   - Impact: 매우 낮음 (상수 선언 1줄)
   - Expected benefit: 코드 가독성, 설정 변경 용이
   - recommended: ✅ applied / apply

### 🔄 선택 applied / apply (9items)
프로젝트 스타일이나 향후 확장성에 따라 결정할 사항들입니다.

5. `components/Button.tsx:89` - Function extraction suggestion
   - Current: 25줄 단일 함수
   - Suggestion: 3개 함수로 분리 (렌더링/이벤트/스타일)
   - Assessment: 현재도 충분히 읽기 쉬움, 분리 시 오버헤드 발생
   - recommended: 🔄 향후 기능 추가 시 고려 (현재는 Unnecessary)

6. `hooks/useAuth.ts:34` - Extract custom hook
   - Current: 동일 패턴 3곳에서 반복
   - Suggestion: useAuthCheck 훅으로 추출
   - Assessment: 추상화 이득 vs 복잡도 증가 trade-off
   - recommended: 🔄 4개 이상 반복 시 고려

7. `api/middleware.ts:78` - Detailed error messages
   - Current: "Invalid request"
   - Suggestion: "Invalid request: missing required field 'email'"
   - Assessment: 보안과 사용성 사이 균형 문제
   - recommended: 🔄 프로젝트 정책에 따라 결정

[... 더 많은 선택 applied / apply 항목]

### ❌ Unnecessary (3items)
applied / apply하지 않는 것이 더 좋은 항목들입니다.

14. `config/db.ts:12` - Add comments suggestion
    - Suggestion: 각 설정값에 주석 설명 추가
    - Assessment: 코드가 충분히 자명하며, Excessive comments은 유지보수 부담
    - Rationale:
      * 설정명이 명확 (`maxConnections`, `timeoutMs`)
      * 타입과 기본값이 문서화 역할
      * 주석은 *왜*를 설명해야 하는데 *무엇*을 반복
    - recommended: ❌ Unnecessary

15. `utils/array.ts:56` - Lodash 사용 제안
    - Current: 네이티브 map/filter 체이닝
    - Suggestion: Lodash chain 사용
    - Assessment: Unnecessary dependency 추가
    - Rationale:
      * 네이티브 메서드로 충분히 명확
      * 번들 사이즈 증가 (수십 KB)
      * 팀원 모두 네이티브 메서드에 익숙
    - recommended: ❌ Unnecessary

16. `tests/user.test.ts:123` - Add test cases 제안
    - Suggestion: 엣지 케이스 10개 추가
    - Assessment: 과도한 테스트, 실용성 낮음
    - Rationale:
      * 제안된 케이스들이 실제 발생 가능성 극히 낮음
      * 테스트 유지보수 비용 증가
      * 핵심 시나리오는 이미 커버
    - recommended: ❌ Unnecessary

---

## processing 방안 제안

**즉시 applied / apply recommended:** CRITICAL 2items + MAJOR 5items + MINOR applied / applyrecommended 4items = 11items
**Consider in future:** MINOR 선택applied / apply 9items
**applied / apply 안 함:** MINOR Unnecessary 3items

How would you like to proceed?
- [1] recommended사항 모두 applied / apply (11items) - 추천
- [2] CRITICAL/MAJOR만 applied / apply (7items)
- [3] 개별 선택 (원하는 항목만 선택)
- [4] 선택 applied / apply 항목도 함께 review
- [5] 전체 중단

> [사용자 선택 대기]
```

**Step 2.4 - Individual Selection for MINOR (Option 3 or 4):**

```
> 3

개별 선택 모드로 진행하겠습니다.
먼저 CRITICAL/MAJOR부터 확인합니다. (강력 recommended)

[CRITICAL/MAJOR 7items 개별 확인... 위의 2.2 과정]

이제 MINOR applied / apply recommended 항목을 확인하시겠습니까? [Y/n]
> Y

[recommended 1/4] `utils/format.ts:34` - 변수명 명확화

현재 코드:
```typescript
function formatUser(raw: any) {
  const data = {
    name: raw.userName,
    email: raw.userEmail
  };
  return data;
}
```

제안 변경:
```typescript
function formatUser(raw: any) {
  const formattedUserData = {
    name: raw.userName,
    email: raw.userEmail
  };
  return formattedUserData;
}
```

**analysis / analyzing:**
- ✅ 가독성 향상 확실
- ✅ 영향 범위 최소 (5줄)
- ✅ 부작용 없음
- ✅ 다른 data 변수와 구분 명확

applied / apply하시겠습니까? [Y/n/skip/detail]
> Y

✅ applied / apply 목록에 추가

[recommended 2/4] `api/response.ts:67` - Error handling improvement
[...]
```

**Step 2.5 - Final Confirmation:**

```
## 최종 processing 요약

✅ applied / apply 예정: 11items
- CRITICAL: 2items
  * auth/login.ts:45 - SQL Injection 수정
  * data/sync.ts:89 - 트랜잭션 추가
- MAJOR: 5items
  * api/users.ts:123 - N+1 쿼리 해결
  * cache/redis.ts:56 - 메모리 누수 수정
  * [...3items 더]
- MINOR (applied / apply recommended): 4items
  * utils/format.ts:34 - 변수명 명확화
  * api/response.ts:67 - 에러 로깅 추가
  * models/user.ts:123 - 타입 가드 사용
  * services/notification.ts:45 - Extract magic number to constant

🔄 skipped - Consider in future: 9items
- components/Button.tsx:89 - 함수 분리 (현재 복잡도 적정)
- hooks/useAuth.ts:34 - 커스텀 훅 (반복 3회, 4회부터 고려)
- [...7items 더]

❌ skipped - Unnecessary: 3items
- config/db.ts:12 - Excessive comments (코드가 자명)
- utils/array.ts:56 - Unnecessary dependency 추가
- tests/user.test.ts:123 - 과도한 엣지 케이스

---

Proceed as planned?
- [1] 예, 진행 (11items applied / apply)
- [2] review 내용 수정 (추가/제거)
- [3] 전체 중단

> [사용자 선택 대기]
```

### Phase 3: Application & Completion (Automatic with Verification)

**Step 3.1 - Apply Changes:**

```
changes을 applied / apply하겠습니다.

[1/11] CRITICAL: auth/login.ts:45 - SQL Injection 수정
✅ complete / completed

[2/11] CRITICAL: data/sync.ts:89 - 트랜잭션 추가
✅ complete / completed

[3/11] MAJOR: api/users.ts:123 - N+1 쿼리 해결
✅ complete / completed

[...]

[11/11] MINOR: services/notification.ts:45 - 상수화
✅ complete / completed

✅ 모든 changes applied / apply complete / completed (11/11)
```

**Step 3.2 - Commit & Push:**

```
changes을 commit하고 push합니다.

commit 메시지: "fix: Apply CodeRabbit feedback

- CRITICAL: SQL injection, transaction safety
- MAJOR: N+1 queries, memory leaks, resource handling
- MINOR: Code quality improvements

Applied 11 items (2 critical, 5 major, 4 minor recommended)"

[실행] git add .
✅ Staged 6 files

[실행] git commit -m "..."
✅ Commit created: a1b2c3d

[실행] git push
✅ Pushed to origin/coderabbit-review-skill

모든 changes이 commit되고 push되었습니다.
```

**Step 3.3 - Generate & Review PR Comment:**

```
PR에 post할 코멘트를 작성했습니다.

---
@coderabbitai resolve

## CodeRabbit 피드백 processing complete / completed

### applied / apply complete / completed (11items)

**CRITICAL (2items)**
- `auth/login.ts:45` - SQL Injection 취약점 수정 (Prepared statement applied / apply)
- `data/sync.ts:89` - 트랜잭션 추가로 데이터 손실 위험 제거

**MAJOR (5items)**
- `api/users.ts:123` - N+1 쿼리 해결 (eager loading으로 101→1 쿼리 감소)
- `cache/redis.ts:56` - 메모리 누수 수정 (finally 블록 추가)
- `services/payment.ts:234` - 결제 실패 시 롤백 로직 추가
- `api/search.ts:89` - 인덱스 누락 경고 해결 (복합 인덱스 추가)
- `workers/job.ts:156` - 무한 루프 위험 제거 (최대 재시도 횟수 설정)

**MINOR - applied / apply recommended (4items)**
- `utils/format.ts:34` - 변수명 명확화 (data → formattedUserData)
- `api/response.ts:67` - 에러 로깅 추가
- `models/user.ts:123` - 타입 가드 사용으로 안정성 향상
- `services/notification.ts:45` - Extract magic number to constant

### review complete / completed - applied / apply 안 함 (12items)

**Consider in future 항목 (9items)**
- `components/Button.tsx:89` - Function extraction suggestion (현재 복잡도 적정)
- `hooks/useAuth.ts:34` - Extract custom hook (반복 3회, 4회부터 고려)
- `api/middleware.ts:78` - Detailed error messages (보안 정책 review 필요)
- `utils/validator.ts:45` - 정규식 성능 최적화 (현재 사용량에서 영향 미미)
- `components/Modal.tsx:123` - 접근성 속성 추가 (다음 스프린트 일괄 applied / apply 예정)
- `services/cache.ts:67` - 캐시 무효화 전략 개선 (아키텍처 논의 후 결정)
- `api/pagination.ts:34` - 커서 기반 페이지네이션 (현재 offset 방식 충분)
- `tests/integration/api.test.ts:89` - 테스트 격리 개선 (리팩토링 시 함께 진행)
- `docs/api.md:12` - API 문서 업데이트 (다음 릴리스 전 일괄 작업)

**Unnecessary (3items)**
- `config/db.ts:12` - Excessive comments 추가 (코드가 충분히 자명함)
- `utils/array.ts:56` - Lodash 사용 제안 (Unnecessary dependency, 네이티브로 충분)
- `tests/user.test.ts:123` - 극단적 엣지 케이스 테스트 (실용성 낮음)

### Statistics
- Total 23items review
- applied / apply: 11items (CRITICAL 2 + MAJOR 5 + MINOR 4)
- Consider in future: 9items
- Unnecessary: 3items

---

이 코멘트를 PR에 post하시겠습니까?
- [1] 예, post
- [2] 내용 수정
- [3] post 안 함 (recommended하지 않음)

> [사용자 선택 대기]
```

**Step 3.4 - Edit Mode (Option 2):**

```
> 2

코멘트를 어떻게 수정하시겠습니까?
- [1] applied / apply 항목 설명 추가/수정
- [2] items너뛴 항목 설명 추가/수정
- [3] 직접 편집 (전체 텍스트)
- [4] 취소하고 그대로 post

> 1

applied / apply 항목 중 수정할 항목의 번호나 파일명을 입력하세요:
(예: "1", "auth/login.ts:45", 또는 "done"으로 complete / completed)

> api/users.ts:123

현재 설명:
"N+1 쿼리 해결 (eager loading으로 101→1 쿼리 감소)"

새 설명을 입력하세요: (빈 줄 입력 시 현재 유지)
> N+1 쿼리 해결 (includes를 사용한 eager loading으로 성능 개선)

✅ 업데이트 complete / completed

다음 항목? (번호/파일명 또는 "done")
> done

수정된 코멘트를 확인하시겠습니까? [Y/n]
> Y

[수정된 코멘트 전체 다시 표시]

post하시겠습니까? [Y/n/edit]
> Y
```

**Step 3.5 - Post & Verify:**

```
PR 코멘트를 post하고 검증합니다.

[실행] gh pr comment 123 --body "..."
✅ 코멘트 post 성공

[대기] GitHub API 동기화 중... (2초)

[검증 1/3] 최신 코멘트 조회 중...
✅ 코멘트 확인

[검증 2/3] @coderabbitai resolve 태그 존재 확인...
✅ 태그 확인

[검증 3/3] 코멘트 내용 무결성 확인...
✅ 모든 섹션 포함 확인

---

✅ 모든 단계 complete / completed! 🎉

## 최종 요약
- ✅ 11items 코드 변경 applied / apply
- ✅ changes commit 및 push (a1b2c3d)
- ✅ PR 코멘트 post 및 검증
- ✅ CodeRabbit 해결 마킹 complete / completed

processing 내용:
- CRITICAL: 2items (보안 취약점, 데이터 손실 위험 해결)
- MAJOR: 5items (성능 및 중요 버그 수정)
- MINOR: 4items (코드 품질 개선)

Consider in future 항목 9items은 적절한 시점에 review하시면 됩니다.
```

## PR Comment Requirement

The PR comment with `@coderabbitai resolve` is mandatory for closing the feedback loop.

**Post comment:**
```bash
gh pr comment "$PR_NUMBER" --body "$COMMENT_BODY"
```

**Verify comment posted:**
```bash
# Wait for API sync
sleep 2
# Confirm comment exists and contains resolve tag
LAST_COMMENT=$(gh pr view "$PR_NUMBER" --json comments --jq '.comments[-1].body')
echo "$LAST_COMMENT" | grep -q "@coderabbitai resolve" && echo "Verified" || echo "FAILED - retry"
```

**After verification, mark tasks as completed:**
```
TaskUpdate: "Post PR comment with @coderabbitai resolve" -> completed
TaskUpdate: "Verify PR comment posted" -> completed
```

Run `TaskList` to confirm all tasks are completed before reporting success to the user.

## Common Mistakes

### Skipping Pagination
**Problem:** Missing comments when PR has 100+ comments
**Fix:** Use GraphQL/REST pagination to collect up to 200 comments

### Not Providing Rationale
**Problem:** User doesn't understand why suggestions are categorized
**Fix:** Include 1-2 line rationale for each MINOR item classification

### Auto-Applying Without Discussion
**Problem:** Applying changes user didn't explicitly approve
**Fix:** Present summary, get user decision, then apply only agreed items

### Incomplete Error Recovery
**Problem:** Stopping workflow when single item fails
**Fix:** Skip failed item with explanation, continue with others, complete remaining tasks

## Success Criteria

- All tasks created at Phase 1 start
- All unresolved comments collected (up to 200 with pagination)
- Each item classified by severity (CRITICAL/MAJOR/MINOR)
- CRITICAL/MAJOR items discussed with user
- MINOR items analyzed with clear rationale
- Only user-approved changes applied
- Changes committed and pushed
- PR comment posted with @coderabbitai resolve
- All tasks show `completed` in TaskList
