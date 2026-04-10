# RESEARCH FINDINGS: apr (Automated Plan Reviser Pro) - TOON Integration Analysis

**Date**: 2026-01-25
**Bead**: bd-jdy
**Researcher**: Claude Code Agent (cc)

## 1. Project Overview

| Attribute | Value |
|-----------|-------|
| **Language** | Bash |
| **CLI Framework** | Pure Bash with Oracle browser automation |
| **Script Size** | ~6,904 lines |
| **Tier** | 4 (Additional Tool) |
| **Directory** | `/dp/automated_plan_reviser_pro` |

### Purpose
apr (Automated Plan Reviser Pro) automates iterative specification refinement using GPT Pro Extended Reasoning via Oracle. It manages multiple revision rounds, tracks convergence, and generates integration prompts.

## 2. TOON Integration Status: COMPLETE

**TOON support is fully implemented in apr robot mode.**

### CLI Flags
```
-f, --format FORMAT   Robot output format: json or toon
```

### Environment Variable Precedence
```
CLI flag > APR_OUTPUT_FORMAT > TOON_DEFAULT_FORMAT > "json" (default)
```

### Implementation Details

| Location | Implementation |
|----------|----------------|
| Line 5250 | `ROBOT_FORMAT="json"` default |
| Lines 5253-5277 | `robot_resolve_output_format()` |
| Lines 5279-5292 | `robot_try_load_toon_sh()` helper |
| Lines 5294-5303 | `robot_json_to_toon()` encoding |
| Lines 5335-5348 | TOON output in `robot_json()` |

### TOON Encoding Flow
```bash
# File: /dp/automated_plan_reviser_pro/apr
robot_json_to_toon() {
    local json="$1"
    if ! robot_try_load_toon_sh; then
        return 1
    fi
    if ! toon_available >/dev/null 2>&1; then
        return 1
    fi
    printf '%s' "$json" | toon_encode
}
```

### Graceful Degradation
```bash
if [[ "${ROBOT_FORMAT:-json}" == "toon" ]]; then
    local toon_out
    if toon_out="$(robot_json_to_toon "$result" 2>/dev/null)"; then
        printf '%s' "$toon_out"
    else
        echo "[toon] warn: tru/toon.sh not available; outputting JSON" >&2
        ...
    fi
fi
```

## 3. Robot Mode Commands

| Command | Description | TOON Support |
|---------|-------------|--------------|
| `robot status` | System overview (config, workflows, oracle) | ✓ |
| `robot workflows` | List all workflows with descriptions | ✓ |
| `robot init` | Initialize .apr directory | ✓ |
| `robot validate` | Pre-run validation | ✓ |
| `robot run` | Execute revision round | ✓ |
| `robot show` | View round content | ✓ |
| `robot diff` | Compare rounds | ✓ |
| `robot integrate` | Get Claude integration prompt | ✓ |
| `robot history` | List revision rounds | ✓ |
| `robot stats` | Show analytics metrics | ✓ |
| `robot help` | Robot mode help | ✓ |

## 4. Output Analysis

### JSON Output Example (status)
```json
{
  "ok": true,
  "code": "ok",
  "data": {
    "configured": false,
    "default_workflow": "",
    "workflow_count": 0,
    "workflows": [],
    "oracle_available": true,
    "oracle_method": "global",
    "config_dir": ".apr",
    "apr_home": "/home/ubuntu/.local/share/apr"
  },
  "hint": "Run 'apr robot init' to initialize, then 'apr setup' to create workflow",
  "meta": {
    "v": "1.2.2",
    "ts": "2026-01-25T05:50:52Z"
  }
}
```

### TOON Output Example (status)
```yaml
ok: true
code: ok
data:
  configured: false
  default_workflow: ""
  workflow_count: 0
  workflows[0]:
  oracle_available: true
  oracle_method: global
  config_dir: .apr
  apr_home: /home/ubuntu/.local/share/apr
hint: "Run 'apr robot init' to initialize, then 'apr setup' to create workflow"
meta:
  v: 1.2.2
  ts: "2026-01-25T05:51:30Z"
```

## 5. Token Savings Estimate

| Command | JSON Tokens (est.) | TOON Tokens (est.) | Savings |
|---------|-------------------|-------------------|---------|
| `robot status` | ~250 | ~150 | 40% |
| `robot workflows` | ~400 | ~240 | 40% |
| `robot history` | ~500 | ~300 | 40% |
| `robot stats` | ~600 | ~360 | 40% |

## 6. Standard Response Envelope

All robot commands use a consistent envelope:
```json
{
  "ok": true|false,
  "code": "ok|error_code",
  "data": {...},
  "hint": "optional hint message",
  "meta": {
    "v": "1.2.2",
    "ts": "ISO-8601 timestamp"
  }
}
```

## 7. Environment Variables

| Variable | Purpose |
|----------|---------|
| `APR_OUTPUT_FORMAT` | Tool-specific output format (json/toon) |
| `TOON_DEFAULT_FORMAT` | Suite-wide default format |
| `TOON_SH_PATH` | Path to toon.sh library |
| `APR_HOME` | Data directory |
| `APR_VERBOSE` | Enable verbose mode |

## 8. Implementation Quality

### Strengths
- Comprehensive robot mode with 11 subcommands
- `--format toon` flag with proper precedence
- Environment variable support (APR-specific and suite-wide)
- Graceful fallback with stderr warning
- Consistent response envelope
- Well-documented in built-in help

### Architecture
```
apr (bash)
  └── robot_json() builds JSON response
      └── robot_json_to_toon() loads toon.sh
          └── toon_encode pipes through tru
              └── TOON output to stdout
```

## 9. Acceptance Criteria Status

- [x] `--format toon` flag implemented
- [x] TOON encoding via toon.sh/tru
- [x] Environment variable support (APR_OUTPUT_FORMAT, TOON_DEFAULT_FORMAT)
- [x] Documented in robot help
- [x] Graceful fallback to JSON
- [x] All 11 robot commands support TOON
- [x] Consistent response envelope

## 10. Conclusion

**TOON integration for apr is COMPLETE.**

The implementation is excellent:
- Comprehensive robot mode for agent automation
- Uses shared `toon.sh` library pattern
- Has proper precedence for format selection
- Graceful degradation with warning
- Consistent envelope structure

**bd-3pa (Integrate TOON into apr) should be marked COMPLETE** - no additional implementation work is required.

## 11. Related Beads

- **bd-jdy**: This research bead - Complete
- **bd-3pa**: Integrate TOON into apr - Should be verified/closed
- **bd-1y9**: Research orchestration parent bead
