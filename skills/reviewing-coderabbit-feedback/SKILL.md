---
name: reviewing-coderabbit-feedback
description: Use when CodeRabbit AI has posted review comments on a PR - interactively classify feedback by severity, discuss recommendations with user, apply agreed changes, and ensure mandatory commit and PR comment workflow with verification
---

# Reviewing CodeRabbit Feedback

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

## Interactive Workflow

### Phase 1: Collection & Classification (Automatic)

1. **Pre-check**: Verify clean working directory
   ```bash
   git status --porcelain
   # If output exists: "⚠️ 커밋되지 않은 변경사항이 있습니다. 먼저 변경사항을 커밋해주세요." → STOP
   ```

2. **Setup Tracking**: Create TodoWrite todos for ALL workflow steps
   ```markdown
   - [ ] Pre-check git status
   - [ ] Discover PR and collect comments (with pagination)
   - [ ] Filter and classify feedback by severity
   - [ ] Discuss CRITICAL/MAJOR with user
   - [ ] Analyze MINOR and provide recommendations
   - [ ] Apply agreed changes
   - [ ] Commit and push changes
   - [ ] Post PR comment with verification
   ```

3. **Discover PR**: Find current PR from branch
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
발견된 피드백: 총 23건
- CRITICAL: 2건 (보안 취약점 1, 데이터 손실 위험 1)
- MAJOR: 5건 (성능 이슈 3, 중요한 버그 2)
- MINOR: 16건 (코드 품질 개선)

## 즉시 처리가 필요한 항목 (CRITICAL/MAJOR 7건)

### CRITICAL
1. `auth/login.ts:45` - SQL Injection 취약점
   - 문제: 사용자 입력을 직접 쿼리에 사용
   - 제안: Prepared statement 사용
   - 위험도: ⚠️ 높음 (보안)

2. `data/sync.ts:89` - 데이터 손실 위험
   - 문제: 트랜잭션 없이 연속 삭제 수행
   - 제안: 트랜잭션 래핑 추가
   - 위험도: ⚠️ 높음 (데이터 무결성)

### MAJOR
3. `api/users.ts:123` - N+1 쿼리 문제
   - 문제: 루프 내 개별 쿼리 실행
   - 제안: Eager loading으로 일괄 조회
   - 영향: 성능 (현재 100개 항목에 101번 쿼리)

4. `cache/redis.ts:56` - 메모리 누수
   - 문제: 연결 종료 누락
   - 제안: finally 블록에 close() 추가
   - 영향: 리소스

[...계속]

이 항목들을 어떻게 처리하시겠습니까?
- [1] 모두 적용 (권장 - CRITICAL/MAJOR는 필수 수정 사항)
- [2] 개별 선택 (각 항목별로 확인)
- [3] 상세 정보 먼저 보기
- [4] MINOR 항목 분석부터 시작
```

**Step 2.2 - Individual Selection Mode (Option 2):**

```
각 항목별로 검토하겠습니다.

[1/7] CRITICAL: `auth/login.ts:45` - SQL Injection 취약점

현재 코드:
```typescript
const user = await db.query(
  `SELECT * FROM users WHERE email = '${email}'`
);
```

제안 변경:
```typescript
const user = await db.query(
  'SELECT * FROM users WHERE email = $1',
  [email]
);
```

**CodeRabbit 분석:**
- SQL Injection 공격 가능
- 악의적 입력으로 전체 데이터 유출 위험

**위험도:** ⚠️ CRITICAL (즉시 수정 필요)

적용하시겠습니까? [Y/n/skip]
> Y

✅ 적용 예정 목록에 추가

[2/7] CRITICAL: `data/sync.ts:89` - 데이터 손실 위험
[...]
```

**Step 2.3 - MINOR Analysis & Recommendations:**

```
✅ CRITICAL/MAJOR 항목 7건 선택 완료

이제 MINOR 권장사항 16건을 분석하겠습니다.
각 항목을 검토하여 적용 여부를 제안해 드리겠습니다.

[분석 중...]

## MINOR 권장사항 분석 완료

### ✅ 적용 권장 (4건)
명확한 개선 효과가 있는 항목들입니다.

1. `utils/format.ts:34` - 변수명 명확화 (`data` → `formattedUserData`)
   - 근거: 타입 추론 개선, 가독성 향상, 스코프 내 다른 data 변수와 충돌 가능
   - 영향: 매우 낮음 (변수명만 변경, 5줄)
   - 예상 효과: 코드 이해도 증가, 유지보수 용이
   - 권장: ✅ 적용

2. `api/response.ts:67` - 에러 핸들링 개선
   - 현재: try-catch만 있고 에러 로깅 없음
   - 제안: logger.error() 추가
   - 근거: 프로덕션 디버깅 시 에러 추적 불가능
   - 영향: 낮음 (1줄 추가)
   - 예상 효과: 문제 발생 시 빠른 원인 파악
   - 권장: ✅ 적용

3. `models/user.ts:123` - 타입 단언 제거
   - 현재: `as User` 강제 캐스팅
   - 제안: 타입 가드 함수 사용
   - 근거: 런타임 타입 불일치 위험
   - 영향: 중간 (타입 가드 함수 추가 필요, 10줄)
   - 예상 효과: 타입 안정성 증가
   - 권장: ✅ 적용

4. `services/notification.ts:45` - 매직 넘버 상수화
   - 현재: `setTimeout(() => ..., 5000)`
   - 제안: `const RETRY_DELAY_MS = 5000`
   - 근거: 의미 명확화, 재사용 가능
   - 영향: 매우 낮음 (상수 선언 1줄)
   - 예상 효과: 코드 가독성, 설정 변경 용이
   - 권장: ✅ 적용

### 🔄 선택 적용 (9건)
프로젝트 스타일이나 향후 확장성에 따라 결정할 사항들입니다.

5. `components/Button.tsx:89` - 함수 분리 제안
   - 현재: 25줄 단일 함수
   - 제안: 3개 함수로 분리 (렌더링/이벤트/스타일)
   - 평가: 현재도 충분히 읽기 쉬움, 분리 시 오버헤드 발생
   - 권장: 🔄 향후 기능 추가 시 고려 (현재는 불필요)

6. `hooks/useAuth.ts:34` - 커스텀 훅 추출
   - 현재: 동일 패턴 3곳에서 반복
   - 제안: useAuthCheck 훅으로 추출
   - 평가: 추상화 이득 vs 복잡도 증가 trade-off
   - 권장: 🔄 4개 이상 반복 시 고려

7. `api/middleware.ts:78` - 에러 메시지 상세화
   - 현재: "Invalid request"
   - 제안: "Invalid request: missing required field 'email'"
   - 평가: 보안과 사용성 사이 균형 문제
   - 권장: 🔄 프로젝트 정책에 따라 결정

[... 더 많은 선택 적용 항목]

### ❌ 불필요 (3건)
적용하지 않는 것이 더 좋은 항목들입니다.

14. `config/db.ts:12` - 주석 추가 제안
    - 제안: 각 설정값에 주석 설명 추가
    - 평가: 코드가 충분히 자명하며, 과도한 주석은 유지보수 부담
    - 근거:
      * 설정명이 명확 (`maxConnections`, `timeoutMs`)
      * 타입과 기본값이 문서화 역할
      * 주석은 *왜*를 설명해야 하는데 *무엇*을 반복
    - 권장: ❌ 불필요

15. `utils/array.ts:56` - Lodash 사용 제안
    - 현재: 네이티브 map/filter 체이닝
    - 제안: Lodash chain 사용
    - 평가: 불필요한 의존성 추가
    - 근거:
      * 네이티브 메서드로 충분히 명확
      * 번들 사이즈 증가 (수십 KB)
      * 팀원 모두 네이티브 메서드에 익숙
    - 권장: ❌ 불필요

16. `tests/user.test.ts:123` - 테스트 케이스 추가 제안
    - 제안: 엣지 케이스 10개 추가
    - 평가: 과도한 테스트, 실용성 낮음
    - 근거:
      * 제안된 케이스들이 실제 발생 가능성 극히 낮음
      * 테스트 유지보수 비용 증가
      * 핵심 시나리오는 이미 커버
    - 권장: ❌ 불필요

---

## 처리 방안 제안

**즉시 적용 권장:** CRITICAL 2건 + MAJOR 5건 + MINOR 적용권장 4건 = 11건
**향후 고려:** MINOR 선택적용 9건
**적용 안 함:** MINOR 불필요 3건

어떻게 진행하시겠습니까?
- [1] 권장사항 모두 적용 (11건) - 추천
- [2] CRITICAL/MAJOR만 적용 (7건)
- [3] 개별 선택 (원하는 항목만 선택)
- [4] 선택 적용 항목도 함께 검토
- [5] 전체 중단

> [사용자 선택 대기]
```

**Step 2.4 - Individual Selection for MINOR (Option 3 or 4):**

```
> 3

개별 선택 모드로 진행하겠습니다.
먼저 CRITICAL/MAJOR부터 확인합니다. (강력 권장)

[CRITICAL/MAJOR 7건 개별 확인... 위의 2.2 과정]

이제 MINOR 적용 권장 항목을 확인하시겠습니까? [Y/n]
> Y

[권장 1/4] `utils/format.ts:34` - 변수명 명확화

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

**분석:**
- ✅ 가독성 향상 확실
- ✅ 영향 범위 최소 (5줄)
- ✅ 부작용 없음
- ✅ 다른 data 변수와 구분 명확

적용하시겠습니까? [Y/n/skip/detail]
> Y

✅ 적용 목록에 추가

[권장 2/4] `api/response.ts:67` - 에러 핸들링 개선
[...]
```

**Step 2.5 - Final Confirmation:**

```
## 최종 처리 요약

✅ 적용 예정: 11건
- CRITICAL: 2건
  * auth/login.ts:45 - SQL Injection 수정
  * data/sync.ts:89 - 트랜잭션 추가
- MAJOR: 5건
  * api/users.ts:123 - N+1 쿼리 해결
  * cache/redis.ts:56 - 메모리 누수 수정
  * [...3건 더]
- MINOR (적용 권장): 4건
  * utils/format.ts:34 - 변수명 명확화
  * api/response.ts:67 - 에러 로깅 추가
  * models/user.ts:123 - 타입 가드 사용
  * services/notification.ts:45 - 매직 넘버 상수화

🔄 건너뜀 - 향후 고려: 9건
- components/Button.tsx:89 - 함수 분리 (현재 복잡도 적정)
- hooks/useAuth.ts:34 - 커스텀 훅 (반복 3회, 4회부터 고려)
- [...7건 더]

❌ 건너뜀 - 불필요: 3건
- config/db.ts:12 - 과도한 주석 (코드가 자명)
- utils/array.ts:56 - 불필요한 의존성 추가
- tests/user.test.ts:123 - 과도한 엣지 케이스

---

이대로 진행하시겠습니까?
- [1] 예, 진행 (11건 적용)
- [2] 검토 내용 수정 (추가/제거)
- [3] 전체 중단

> [사용자 선택 대기]
```

### Phase 3: Application & Completion (Automatic with Verification)

**Step 3.1 - Apply Changes:**

```
변경사항을 적용하겠습니다.

[1/11] CRITICAL: auth/login.ts:45 - SQL Injection 수정
✅ 완료

[2/11] CRITICAL: data/sync.ts:89 - 트랜잭션 추가
✅ 완료

[3/11] MAJOR: api/users.ts:123 - N+1 쿼리 해결
✅ 완료

[...]

[11/11] MINOR: services/notification.ts:45 - 상수화
✅ 완료

✅ 모든 변경사항 적용 완료 (11/11)
```

**Step 3.2 - Commit & Push:**

```
변경사항을 커밋하고 푸시합니다.

커밋 메시지: "fix: Apply CodeRabbit feedback

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

모든 변경사항이 커밋되고 푸시되었습니다.
```

**Step 3.3 - Generate & Review PR Comment:**

```
PR에 게시할 코멘트를 작성했습니다.

---
@coderabbitai resolve

## CodeRabbit 피드백 처리 완료

### 적용 완료 (11건)

**CRITICAL (2건)**
- `auth/login.ts:45` - SQL Injection 취약점 수정 (Prepared statement 적용)
- `data/sync.ts:89` - 트랜잭션 추가로 데이터 손실 위험 제거

**MAJOR (5건)**
- `api/users.ts:123` - N+1 쿼리 해결 (eager loading으로 101→1 쿼리 감소)
- `cache/redis.ts:56` - 메모리 누수 수정 (finally 블록 추가)
- `services/payment.ts:234` - 결제 실패 시 롤백 로직 추가
- `api/search.ts:89` - 인덱스 누락 경고 해결 (복합 인덱스 추가)
- `workers/job.ts:156` - 무한 루프 위험 제거 (최대 재시도 횟수 설정)

**MINOR - 적용 권장 (4건)**
- `utils/format.ts:34` - 변수명 명확화 (data → formattedUserData)
- `api/response.ts:67` - 에러 로깅 추가
- `models/user.ts:123` - 타입 가드 사용으로 안정성 향상
- `services/notification.ts:45` - 매직 넘버 상수화

### 검토 완료 - 적용 안 함 (12건)

**향후 고려 항목 (9건)**
- `components/Button.tsx:89` - 함수 분리 제안 (현재 복잡도 적정)
- `hooks/useAuth.ts:34` - 커스텀 훅 추출 (반복 3회, 4회부터 고려)
- `api/middleware.ts:78` - 에러 메시지 상세화 (보안 정책 검토 필요)
- `utils/validator.ts:45` - 정규식 성능 최적화 (현재 사용량에서 영향 미미)
- `components/Modal.tsx:123` - 접근성 속성 추가 (다음 스프린트 일괄 적용 예정)
- `services/cache.ts:67` - 캐시 무효화 전략 개선 (아키텍처 논의 후 결정)
- `api/pagination.ts:34` - 커서 기반 페이지네이션 (현재 offset 방식 충분)
- `tests/integration/api.test.ts:89` - 테스트 격리 개선 (리팩토링 시 함께 진행)
- `docs/api.md:12` - API 문서 업데이트 (다음 릴리스 전 일괄 작업)

**불필요 (3건)**
- `config/db.ts:12` - 과도한 주석 추가 (코드가 충분히 자명함)
- `utils/array.ts:56` - Lodash 사용 제안 (불필요한 의존성, 네이티브로 충분)
- `tests/user.test.ts:123` - 극단적 엣지 케이스 테스트 (실용성 낮음)

### 통계
- 총 23건 검토
- 적용: 11건 (CRITICAL 2 + MAJOR 5 + MINOR 4)
- 향후 고려: 9건
- 불필요: 3건

---

이 코멘트를 PR에 게시하시겠습니까?
- [1] 예, 게시
- [2] 내용 수정
- [3] 게시 안 함 (권장하지 않음)

> [사용자 선택 대기]
```

**Step 3.4 - Edit Mode (Option 2):**

```
> 2

코멘트를 어떻게 수정하시겠습니까?
- [1] 적용 항목 설명 추가/수정
- [2] 건너뛴 항목 설명 추가/수정
- [3] 직접 편집 (전체 텍스트)
- [4] 취소하고 그대로 게시

> 1

적용 항목 중 수정할 항목의 번호나 파일명을 입력하세요:
(예: "1", "auth/login.ts:45", 또는 "done"으로 완료)

> api/users.ts:123

현재 설명:
"N+1 쿼리 해결 (eager loading으로 101→1 쿼리 감소)"

새 설명을 입력하세요: (빈 줄 입력 시 현재 유지)
> N+1 쿼리 해결 (includes를 사용한 eager loading으로 성능 개선)

✅ 업데이트 완료

다음 항목? (번호/파일명 또는 "done")
> done

수정된 코멘트를 확인하시겠습니까? [Y/n]
> Y

[수정된 코멘트 전체 다시 표시]

게시하시겠습니까? [Y/n/edit]
> Y
```

**Step 3.5 - Post & Verify:**

```
PR 코멘트를 게시하고 검증합니다.

[실행] gh pr comment 123 --body "..."
✅ 코멘트 게시 성공

[대기] GitHub API 동기화 중... (2초)

[검증 1/3] 최신 코멘트 조회 중...
✅ 코멘트 확인

[검증 2/3] @coderabbitai resolve 태그 존재 확인...
✅ 태그 확인

[검증 3/3] 코멘트 내용 무결성 확인...
✅ 모든 섹션 포함 확인

---

✅ 모든 단계 완료! 🎉

## 최종 요약
- ✅ 11건 코드 변경 적용
- ✅ 변경사항 커밋 및 푸시 (a1b2c3d)
- ✅ PR 코멘트 게시 및 검증
- ✅ CodeRabbit 해결 마킹 완료

처리 내용:
- CRITICAL: 2건 (보안 취약점, 데이터 손실 위험 해결)
- MAJOR: 5건 (성능 및 중요 버그 수정)
- MINOR: 4건 (코드 품질 개선)

향후 고려 항목 9건은 적절한 시점에 검토하시면 됩니다.
```

## The Iron Law: PR Comment is MANDATORY

**PR comment with @coderabbitai resolve is NOT optional.**

### Triple Verification System

1. **Create Dedicated TodoWrite Item:**
   ```
   - [ ] Post @coderabbitai resolve comment to PR (MANDATORY)
   ```

2. **Post Comment:**
   ```bash
   gh pr comment "$PR_NUMBER" --body "$(cat <<'COMMENT_EOF'
   @coderabbitai resolve

   ## CodeRabbit 피드백 처리 완료
   [내용...]
   COMMENT_EOF
   )"
   ```

3. **Immediate Verification (3 Checks):**
   ```bash
   # Check 1: Command succeeded
   if [ $? -ne 0 ]; then
     echo "❌ CRITICAL: Comment post failed"
     # Retry logic
   fi

   # Wait for API sync
   sleep 2

   # Check 2: Comment exists
   LAST_COMMENT=$(gh pr view "$PR_NUMBER" --json comments --jq '.comments[-1].body')

   # Check 3: Contains resolve tag
   if ! echo "$LAST_COMMENT" | grep -q "@coderabbitai resolve"; then
     echo "❌ CRITICAL: PR comment missing @coderabbitai resolve tag"
     # Retry logic
   else
     echo "✅ VERIFIED: PR comment posted with @coderabbitai resolve"
   fi
   ```

4. **Retry Logic:**
   ```bash
   post_pr_comment_with_verification() {
     local pr_number=$1
     local comment_body=$2
     local max_attempts=3
     local attempt=1

     while [ $attempt -le $max_attempts ]; do
       echo "[Attempt $attempt/$max_attempts] Posting PR comment..."

       if gh pr comment "$pr_number" --body "$comment_body"; then
         sleep 2

         local last_comment=$(gh pr view "$pr_number" --json comments --jq '.comments[-1].body')
         if echo "$last_comment" | grep -q "@coderabbitai resolve"; then
           echo "✅ SUCCESS: PR comment verified"
           return 0
         fi
       fi

       echo "⚠️  Attempt $attempt failed, retrying..."
       ((attempt++))
       sleep 3
     done

     echo "❌ CRITICAL FAILURE: Failed after $max_attempts attempts"
     return 1
   }
   ```

### Why This Matters

- CodeRabbit tracks resolution through these comments
- Without comment, feedback thread stays open indefinitely
- Team members can't see what was addressed
- Automated workflows depend on resolution markers
- GitHub PR timeline needs closure for audit trail

### Success Checklist

Before marking workflow complete, verify ALL:
- [ ] `gh pr comment` command executed
- [ ] Command exit code = 0
- [ ] Waited 2 seconds for API sync
- [ ] Latest PR comment retrieved successfully
- [ ] Comment contains "@coderabbitai resolve"
- [ ] Comment contains summary of applied changes
- [ ] Comment contains summary of skipped items
- [ ] TodoWrite item marked completed
- [ ] Output: "✅ VERIFIED: PR comment posted"

**No shortcuts. No assumptions. Verify every time.**

## Red Flags - Signs You're Skipping Verification

**STOP immediately if you think:**
- "I'll just post the comment, verification is overkill"
- "The command succeeded, that's enough"
- "I'll check manually later"
- "User can verify in the PR"
- "Let me mark this todo as done..."

**ALL OF THESE ARE FAILURES - VERIFY THE COMMENT**

## Common Mistakes

### ❌ Skipping Pagination
**Problem:** Missing comments when PR has 100+ comments
**Fix:** Use GraphQL/REST pagination to collect up to 200 comments

### ❌ Not Providing Rationale
**Problem:** User doesn't understand why suggestions are categorized as recommended/optional/unnecessary
**Fix:** Include 1-2 line rationale for each MINOR item classification

### ❌ Skipping PR Comment Verification
**Problem:** Assuming comment was posted without verification
**Fix:** Always run triple-verification (command success + API sync + tag check)

### ❌ Auto-Applying Without Discussion
**Problem:** Applying changes user didn't explicitly approve
**Fix:** Present summary, get user decision, then apply only agreed items

### ❌ Incomplete Error Recovery
**Problem:** Stopping workflow when single item fails
**Fix:** Skip failed item with explanation, continue with others, complete Phase 3

## Success Criteria

- ✅ Collected all unresolved comments (up to 200 with pagination)
- ✅ Classified each item by severity (CRITICAL/MAJOR/MINOR)
- ✅ Discussed CRITICAL/MAJOR items with user
- ✅ Analyzed MINOR items with clear rationale
- ✅ Applied only user-approved changes
- ✅ Committed and pushed all changes
- ✅ Posted PR comment with @coderabbitai resolve
- ✅ Verified comment posting with triple-check system
- ✅ All TodoWrite items marked completed

## Real-World Impact

**Before this skill:**
- Manual classification of 20+ CodeRabbit comments took 15+ minutes
- Unclear why certain suggestions weren't applied
- Risk of missing important items due to pagination limits
- Inconsistent PR comment posting
- No verification that CodeRabbit received resolution

**After this skill:**
- Interactive guided review in 5-7 minutes
- Clear rationale for each classification decision
- Complete coverage up to 200 comments with pagination
- Guaranteed PR comment posting with triple verification
- User feels confident about decisions with analysis support
