#!/usr/bin/env python3
# [AI-EDIT] Agent: Antigravity | Model: Claude Sonnet 4.6 | Date: 2026-09-11 11:47 | Reason: Local-model auto-debug for VKS Kiosk VM testing
"""
infra/auto_debug.py
-------------------
Reads a VM log file, queries the local llama.cpp model (Qwen 2.5 Coder)
for debugging suggestions, and writes them to logs/debug_suggestions_<target>.md.

Defaults (read from ../.env):
    LLM_ENDPOINT  = http://localhost:8080
    LLM_MODEL     = qwen2.5-coder-7b-instruct-q4_k_m.gguf
    VM_KIOSK_USER = Kiosk
    VM_ROOT_USER  = root

Usage:
    python infra/auto_debug.py <log_file> <kiosk_target>

Exits 0 on success (suggestions written), 1 if the model call fails.
"""
import os
import sys
import json
import pathlib
import urllib.request
import urllib.error
import socket

# ---------------------------------------------------------------------------
# Load .env (simple parser - no external deps required)
# ---------------------------------------------------------------------------
_ENV = {}
_ENV_PATH = pathlib.Path(__file__).parent.parent / ".env"
if _ENV_PATH.exists():
    for line in _ENV_PATH.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        _ENV[k.strip()] = v.strip().strip('"').strip("'")

def _env(key: str, default: str) -> str:
    return os.environ.get(key, _ENV.get(key, default))

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
LLM_ENDPOINT   = _env("LLM_ENDPOINT",  "http://localhost:8000")
LLM_MODEL      = _env("LLM_MODEL",     "C:\\AI-Stack\\Models\\Hermes-3-Llama-3.1-8B.Q4_K_M.gguf")
KIOSK_USER     = _env("VM_KIOSK_USER", "Kiosk")
ROOT_USER      = _env("VM_ROOT_USER",  "root")

LOGS_DIR = pathlib.Path(__file__).parent.parent / "logs"
LOGS_DIR.mkdir(exist_ok=True)

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main() -> int:
    if len(sys.argv) < 3:
        print("Usage: python infra/auto_debug.py <log_file> <kiosk_target>")
        return 1

    log_file   = pathlib.Path(sys.argv[1])
    target     = sys.argv[2]
    out_file   = LOGS_DIR / f"debug_suggestions_{target}.md"

    if not log_file.exists():
        print(f"[auto_debug] ERROR: log file not found: {log_file}")
        return 1

    log_content = log_file.read_text(encoding="utf-8", errors="replace")

    # Trim to last 8000 chars so we stay within context window
    if len(log_content) > 8000:
        log_content = "...[truncated]...\n" + log_content[-8000:]

    prompt = (
        f"You are a senior Linux/Hyper-V DevOps engineer.\n"
        f"Analyse the following VM boot/install log for the kiosk variant **{target}**.\n"
        f"Default login accounts used during this test:\n"
        f"  - Kiosk user: `{KIOSK_USER}` (password: Kiosk)\n"
        f"  - Root user:  `{ROOT_USER}` (password: Master)\n\n"
        f"Identify any errors, warnings, or anomalies.\n"
        f"For each issue found, provide:\n"
        f"  1. A short description of the problem.\n"
        f"  2. The likely root cause.\n"
        f"  3. A concrete fix command or configuration change.\n\n"
        f"If no issues are found, confirm that the log looks healthy.\n\n"
        f"--- LOG START ---\n{log_content}\n--- LOG END ---"
    )

    payload = json.dumps({
        "model":       LLM_MODEL,
        "messages":    [{"role": "user", "content": prompt}],
        "temperature": 0.2,
        "max_tokens":  1024,
        "stream":      False,
    }).encode("utf-8")

    url = LLM_ENDPOINT.rstrip("/") + "/v1/chat/completions"
    req = urllib.request.Request(
        url,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    print(f"[auto_debug] Querying local model: {LLM_MODEL} @ {url}")
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            result = json.loads(resp.read().decode("utf-8"))
        suggestion = result["choices"][0]["message"]["content"]
    except (urllib.error.URLError, TimeoutError, socket.timeout) as exc:
        print(f"[auto_debug] WARN: LLM endpoint unreachable or timed out - {exc}")
        suggestion = (
            "**Local model unreachable or timeout** - llama.cpp / Reasonix server did not respond in time.\n"
            "Start it with:\n"
            "```bash\n"
            f"./llama-server -m \"{_env('LLM_MODEL_PATH', 'C:/AI-Stack/Models/qwen2.5-coder-7b-instruct-q4_k_m.gguf')}\" "
            "--port 8080 --host 0.0.0.0\n"
            "```\n"
            "Manual log review required."
        )
    except Exception as exc:
        print(f"[auto_debug] ERROR: {exc}")
        return 1

    # Write suggestions
    md = (
        f"# Auto-Debug Suggestions - Kiosk Variant: `{target}`\n\n"
        f"> **Model:** `{LLM_MODEL}`\n"
        f"> **Log file:** `{log_file}`\n"
        f"> **Default credentials:** `{KIOSK_USER}:Kiosk` / `{ROOT_USER}:Master`\n\n"
        f"---\n\n"
        f"{suggestion}\n"
    )
    out_file.write_text(md, encoding="utf-8")
    print(f"[auto_debug] Suggestions written -> {out_file}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
