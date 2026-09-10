# AI Rebuild & Architecture Directive: system / system

> Purpose: Use this prompt to instruct an AI Agent (Antigravity, Jules, Claude, etc.) to reconstruct, refactor, or cleanly extend this component from scratch.

---

## Component Specification
- Component / Script: system.ps1
- Category: system
- Language / Runtime: PowerShell 5.1 / 7+
- Architecture Role: Idempotent automation script operating within the system domain.

## Rebuild Requirements
1. Idempotency: Safe to execute multiple times without side effects.
2. Error Handling: Strict error catching (Set-StrictMode, try/catch).
3. No Hardcoded Secrets: Load secrets from .env or environment.json.
4. Parameter Validation: Validate all arguments; support interactive & unattended modes.
5. Metafile Maintenance: Keep README.md, help.md, examples/, preconfigs/, CHANGELOG.md, SOURCES.md updated.

---

## Example AI Prompt
```markdown
Please review and rebuild the script system.ps1 in folder system:
1. Ensure full compliance with the Universal Agent Framework standards.
2. Maintain complete backwards compatibility for existing parameters.
3. Validate and update accompanying help, examples, and test coverage.
```
