# Tests & Validation Protocols: VKS-Kiosk & Data Transfer Station

## 1. Test Architecture Overview

The testing suite for `vks_kiosk` enforces automated validation across static, unit, and end-to-end integration layers:

| Layer | Scope | Tooling | Execution Command |
| :--- | :--- | :--- | :--- |
| **Static & Linting** | Shell syntax, Python bytecode compilation | `bash -n`, `py_compile` | `just lint` |
| **Unit Tests** | On-screen overlay, Tkinter mtime caching, fallback handling | Python `unittest` | `just test-unit` |
| **E2E VM Testing** | Hyper-V VM provisioning, ISO mount & boot validation | `pyinfra` on `HyperVHost2023` | `just test-vm` |
| **Host Deployment** | In-place declarative appliance configuration on host `mx` | `pyinfra` on `mx` | `just deploy-mx` |

---

## 2. Running Unit Tests

Execute all discovery unit tests across Linux, Windows, and Raspberry Pi modules:

```bash
just test-unit
# Or directly via Python:
python -m unittest discover -s Linux -p "test_*.py"
python -m unittest discover -s Windows -p "test_*.py"
python -m unittest discover -s Raspi -p "test_*.py"
```

### Verified Test Cases:
- `test_read_text_success`: Asserts that valid version text is read and trimmed.
- `test_read_text_exception`: Asserts that missing files degrade gracefully to `"keine Datei"`.
- `test_read_text_caching`: Asserts that `os.path.getmtime` prevents unnecessary disk I/O on unchanged files.
- `test_update`: Asserts periodic GUI label refresh via Tkinter event loop.

---

## 3. Automated VM & Deployment Testing

```bash
# Automated Hyper-V test VM setup & verification
just test-vm

# In-place deployment on host mx
just deploy-mx
```
