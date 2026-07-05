# my-toolkit

개인용 Claude Code 플러그인 마켓플레이스. statusline으로 시작해서 필요할 때마다 skill/hook/agent/command를 하나씩 추가한다.

## 설치

```powershell
claude plugin marketplace add "D:\claude\my-toolkit"
claude plugin install my-toolkit@my-toolkit-marketplace
```

## 구성

- `statusline/statusline.ps1` — Claude Code 상태줄 스크립트. `~/.claude/statusline-command.ps1`이 launcher 역할을 하며 여기 설치된 버전을 자동으로 찾아 실행한다.
- `skills/claude-md-improver/` — CLAUDE.md 파일 감사·개선 스킬.
- `commands/revise-claude-md.md` — 세션 학습 내용을 CLAUDE.md에 반영하는 커맨드.
- `skills/grill-me/` — 계획/설계를 집요하게 인터뷰해 결정 트리를 하나씩 해소하는 스킬.
- `skills/grill-with-docs/` — 프로젝트 도메인 모델·문서(CONTEXT.md, ADR)에 대비해 grilling하고 결정을 문서에 반영하는 스킬.

## 새 기능 추가하는 법

1. `skills/<name>/SKILL.md`, `hooks/hooks.json`, `agents/<name>.md`, `commands/<name>.md` 중 필요한 위치에 파일 추가
2. `.claude-plugin/plugin.json`의 `version` 값을 올림 (권장)
3. `claude plugin marketplace update my-toolkit-marketplace` 실행
