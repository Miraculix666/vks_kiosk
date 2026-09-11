# 🤖 vks_kiosk Agent Directives

Part of the **VKS Kiosk & Cisco Video** stack.
- **Purpose:** Unified VKS Kiosk build scripts, Data Transfer Station, Cisco DX80 integration.
- **Sister Repos:** [vks_cisco_dx80_mod](file:///C:/GitHub/vks_cisco_dx80_mod), [vks_cisco_dx80_base](file:///C:/GitHub/vks_cisco_dx80_base)

---

## 🌐 Universal Multi-OS, Multi-Client, Multi-Agent/Harness Mandate
> **Axiom:** Work **Multi-OS**, **Multi-Client**, and **Multi-Agent/Harness**: as universal as possible, as specific as needed.

1. **Multi-OS Parity (Windows & Linux/POSIX):**
   - Provide dual-scripting symmetry: Windows (.ps1) and Linux/POSIX (.sh / Justfile).
   - Bash scripts must use LF line endings. Use python -c or WSL for on-Windows generation.

2. **Multi-Agent & Multi-Harness Ubiquity:**
   - Universal support for: Antigravity, Jules, Claude Code, Hermes, OpenCode, Aider, Goose, Continue, CodeGPT, OpenHands, **Kepler**, **Herdr**.
   - Per-agent directive files: GEMINI.md (Antigravity), CLAUDE.md (Claude Code), KEPLER.md (Kepler), JULES_EXECUTION_DIRECTIVE.md (Jules).

3. **Universal First, Specific as Needed:**
   - Reusable build scripts in Linux/, Windows/, Raspi/.
   - Host-specific configs (IPs, tokens) isolated in llm_stack_config/hosts/{hostname}_config.yaml.

---

## 🔗 Related & Sister Repositories
- [vks_cisco_dx80_mod](file:///C:/GitHub/vks_cisco_dx80_mod): Cisco DX80 CE firmware macros & UI modifications.
- [vks_cisco_dx80_base](file:///C:/GitHub/vks_cisco_dx80_base): Cisco DX80 base firmware.
- [vks_kiosk](file:///C:/GitHub/vks_kiosk): VKS Kiosk deployment and web interface (this repo).
