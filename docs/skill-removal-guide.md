# Skill Removal Guide - 하위 호환성 이슈 없이 스킬 제거하기

Claude Code에서 스킬을 안전하게 제거하는 단계별 가이드입니다.

## 제거 전 확인 사항

스킬을 제거하기 전에 다음을 확인하세요:

1. **의존성 확인**: 다른 스킬이나 명령어에서 참조하는지 확인
2. **사용 현황**: 실제로 사용되고 있는지 확인
3. **대체 방안**: 기능이 다른 곳으로 이동했는지 확인

## 단계별 제거 프로세스

### 1단계: Deprecation 표시 (선택사항, 점진적 제거 시)

스킬을 즉시 제거하지 않고 점진적으로 제거하려면 먼저 deprecated로 표시합니다.

**SKILL.md에 deprecation notice 추가:**

```markdown
---
name: understanding-code-context
description: [DEPRECATED] Use when understanding external libraries...
---

# Understanding Code Context

> **⚠️ DEPRECATED**: This skill has been deprecated and will be removed in a future version.
> 
> **Migration**: Use Context7 tools directly instead of this skill.
```

### 2단계: 모든 참조 제거

다음 위치에서 스킬 참조를 제거합니다:

#### 2.1. `using-skill-set/SKILL.md`에서 제거

```markdown
### understanding-code-context
**Use when**: ...
```

이 섹션 전체를 제거합니다.

#### 2.2. `using-skill-set/session-start.sh`에서 제거

스크립트에서 스킬 이름을 제거합니다:

```bash
# 제거 전
skills=(
  "managing-git-workflow"
  "understanding-code-context"  # 이 줄 제거
  "browser-automation"
  ...
)

# 제거 후
skills=(
  "managing-git-workflow"
  "browser-automation"
  ...
)
```

#### 2.3. 프로젝트 문서에서 제거

- `README.md`: 스킬 설명 제거
- `AGENTS.md`: 스킬 목록에서 제거
- 기타 문서에서 언급 제거

### 3단계: 스킬 디렉토리 제거

**방법 1: 전체 디렉토리 삭제 (권장)**

```bash
rm -rf plugins/skill-set/skills/understanding-code-context
```

**방법 2: SKILL.md만 제거 (디렉토리 구조 유지 시)**

```bash
rm plugins/skill-set/skills/understanding-code-context/SKILL.md
```

> **참고**: Claude Code는 `skills/` 디렉토리 내의 모든 `SKILL.md` 파일을 자동으로 로드합니다. 
> - 디렉토리를 삭제하거나
> - `SKILL.md` 파일을 제거하면
> 
> 스킬이 자동으로 제거됩니다.

### 4단계: CHANGELOG 업데이트

`CHANGELOG.md`에 제거 사항을 명확히 기록합니다:

```markdown
## [1.0.3] - 2025-01-10

### Removed

- **understanding-code-context**: Removed deprecated skill
  - Functionality replaced by direct Context7 tool usage
  - See migration guide in CHANGELOG for details

### Migration Guide

If you were using `understanding-code-context` skill:

**Before:**
```
Use the understanding-code-context skill to find library docs
```

**After:**
```
Use Context7 tools directly:
1. resolve-library-id "library-name"
2. get-library-docs context7CompatibleLibraryID="/org/project"
```
```

### 5단계: 버전 업데이트

`plugin.json`의 버전을 업데이트합니다:

```json
{
  "version": "1.0.3"
}
```

### 6단계: 테스트

제거 후 다음을 확인합니다:

1. **플러그인 로드 확인**: 스킬이 더 이상 로드되지 않는지 확인
2. **다른 스킬 영향 확인**: 다른 스킬이 정상 작동하는지 확인
3. **명령어 영향 확인**: 관련 명령어가 없는지 확인

## 즉시 제거 (Deprecation 없이)

즉시 제거하려면 위의 2-6단계만 수행하면 됩니다.

## 주의사항

1. **Git 커밋**: 모든 변경사항을 명확한 커밋 메시지와 함께 커밋합니다
   ```bash
   git add -A
   git commit -m "Remove understanding-code-context skill"
   ```

2. **Breaking Change**: 스킬 제거는 breaking change이므로 major 버전 업데이트를 고려하세요

3. **사용자 알림**: 플러그인을 사용하는 사용자들에게 변경사항을 알려야 합니다

## 참고 자료

- [Claude Code Skills Documentation](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview)
- [Keep a Changelog](https://keepachangelog.com/) - CHANGELOG 작성 가이드
- [Semantic Versioning](https://semver.org/) - 버전 관리 가이드

