# 🤖 Kepler Agent Directives (VKS Kiosk)

Welcome **Kepler** (GitKraken Agentic Development Environment).
This file provides Kepler-specific context and directives for the ks_kiosk repository.

---

## 🧭 Project Identity
- **Repository:** ks_kiosk — Unified VKS Kiosk & Data Transfer Station Appliance
- **Domain:** Cisco/Kiosk (Videokonferenzsystem)
- **Sister Repos:** [ks_cisco_dx80_mod](file:///C:/GitHub/vks_cisco_dx80_mod) ⟷ [ks_cisco_dx80_base](file:///C:/GitHub/vks_cisco_dx80_base)

---

## 🔗 Repository Cross-Reference Map
Always refer to [REPOSITORY_MAP.md](file:///C:/GitHub/REPOSITORY_MAP.md) for the full map.

### 📌 Placement Rules
1. **Core Scripts** (reusable, generic): Stay in this repo (ks_kiosk/).
2. **Live Node Configs** (IPs, tokens, hostnames): Go in llm_stack_config/hosts/{hostname}_config.yaml.
3. **Backups**: READ-ONLY. Never mutate backup repositories.

---

## 📁 Key Source Locations
| Path | Purpose |
|------|---------|
| Linux/ | Bash build scripts (make_vks, make_live_iso, make_install, data_transfer_station) |
| Linux/overlay.py | XFCE4 overlay / kiosk lock layer |
| scripts/system/ | VM test scripts, system utilities |
| Windows/ | Windows-side build scripts |
| Raspi/ | Raspberry Pi kiosk scripts |
| infra/ | Infrastructure templates |
| docs/ | Project documentation |

---

## ⚙️ Kepler ACP Session Notes
- **LLM Routing:** Kepler uses ACP. The agent LLM endpoint is set via OPENAI_BASE_URL in the environment.
  Source ~/.kepler-env before launching sessions to point agents at the local LLM Stack:
  `ash
  source ~/.kepler-env  # sets OPENAI_BASE_URL, OPENAI_API_KEY, KEPLER_ORCHESTRATOR
  `
- **Sync Config:** Run python C:/GitHub/llm_stack_config/scripts/sync_agent_harnesses.py to regenerate ~/.kepler-env and ~/.kepler-server/config.json.
- **Agent Binaries Available:** gy (Antigravity), claude (Claude Code), opencode

---

## 🚫 What NOT to Do
- Do NOT hardcode IPs, API keys, or hostnames in build scripts.
- Do NOT commit to *_backup* repos.
- Do NOT mix kiosk-specific logic with generic LLM stack code.

---

## 🔗 Full Agent Matrix
See [GEMINI.md](file:///C:/GitHub/vks_kiosk/GEMINI.md) for the complete agent/harness cross-reference matrix valid across all AI agents working on this repository.
