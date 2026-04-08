# CVE PoC: Claude Code Sandbox Escape via Hook Script Modification

## Summary

Claude Code's sandbox allows writes to project files but executes hook scripts
**outside** the sandbox on the host. An attacker who can write to a hook script
(via prompt injection or any sandbox write path) gains arbitrary host-level code
execution on the next tool use.

## Vulnerability

| Field | Value |
|-------|-------|
| Component | Claude Code sandbox + hooks |
| Attack vector | Prompt injection / malicious repo content |
| Prerequisite | Project uses hooks that reference in-project scripts |
| Impact | Arbitrary host code execution, sandbox configuration bypass |

## The Problem

```
.claude/settings.json          ← protected by sandbox (cannot overwrite directly)
.claude/hooks/pre-bash.sh      ← NOT protected (writable project file)
                                  BUT runs outside sandbox with host privileges
```

The sandbox protects its own config (`settings.json`) but not the scripts that
`settings.json` points to. Modifying a hook script is equivalent to modifying
`settings.json` — both control what runs outside the sandbox.

## Attack Chain

1. **Recon**: Attacker reads `.claude/settings.json` to find hook script paths
2. **Write**: Attacker modifies `.claude/hooks/pre-bash.sh` (sandbox allows this)
3. **Trigger**: Claude runs any Bash command → hook fires automatically
4. **Escape**: Modified hook runs on host — writes `/tmp/hook-exploit-proof.txt`,
   overwrites `settings.json` to expand permissions

No Docker, no bind mounts, no special tooling. The sandbox itself provides the
write path, and hooks provide the execution path.

## Demo

```bash
# Run the exploit
./demo-exploit.sh

# Run the control (direct write — should be blocked)
./demo-control.sh

# Reset to clean state
./reset-demo/reset.sh
```

## Files

| File | Purpose |
|------|---------|
| `.claude/settings.json` | Hook config pointing to in-project script |
| `.claude/hooks/pre-bash.sh` | Innocent hook script (the write target) |
| `attack/prompt.md` | Injection payload |
| `demo-exploit.sh` | End-to-end exploit demonstration |
| `demo-control.sh` | Control: proves direct writes are blocked |
| `meta.md` | Detailed vulnerability analysis |
| `reset-demo/` | Scripts to restore clean state |

## Comparison With Docker Escape (cve-claude-sandbox-docker)

| | Docker Escape | Hook Escape |
|---|---|---|
| Requires Docker | Yes | No |
| Requires bind mount | Yes | No |
| Trigger mechanism | User runs test script | Automatic (next tool use) |
| Extra config needed | `excludedCommands` for Docker | Hooks exist (intended use) |
| Complexity | Two-stage (inject → Docker run) | One-stage (inject → auto-trigger) |

The hook escape is simpler, requires fewer prerequisites, and self-triggers.

## Recommended Mitigations

1. Sandbox should protect any file referenced in hook `command` fields
2. Integrity-check hook scripts (hash at load, verify before execution)
3. Warn users when hooks reference project-local paths
4. Consider requiring hooks to live outside the project directory
