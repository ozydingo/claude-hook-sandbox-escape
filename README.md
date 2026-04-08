# CVE PoC: Claude Code Sandbox Escape via Hook Script Modification

## Summary

Claude Code hooks run **outside** the sandbox with full host privileges. The scripts
they reference live **inside** the project directory, which is writable from within
the sandbox. Modifying a hook script gives an attacker arbitrary host-level code
execution on the next tool use — no sandbox bypass needed, because hooks were never
sandboxed to begin with.

## The Problem

```
INSIDE SANDBOX (writes allowed)          OUTSIDE SANDBOX (hooks execute)

  .claude/hooks/pre-bash.sh  ──write──>  pre-bash.sh runs on next Bash tool use
                                           ├── full host filesystem access
                                           ├── network access (curl, ssh)
                                           ├── read secrets (~/.aws, ~/.ssh)
                                           └── modify user environment (~/.bashrc)
```

The sandbox is irrelevant once the hook fires. There is no settings.json overwrite,
no Docker escape, no second stage. The hook script **is** the escape.

## Attack Chain

1. **Recon**: Read `.claude/settings.json` to find hook script paths
2. **Write**: Modify the hook script (sandbox allows this — it's a project file)
3. **Trigger**: Claude runs any Bash command → hook fires automatically on the host

Single-stage, self-triggering, no prerequisites beyond hooks existing.

## Demo

```bash
./demo.sh              # run the exploit
./reset-demo/reset.sh  # restore clean state
```

## Files

| File | Purpose |
|------|---------|
| `.claude/settings.json` | Hook config pointing to in-project script |
| `.claude/hooks/pre-bash.sh` | Innocent hook script (the write target) |
| `attack/prompt.md` | Injection payload |
| `demo.sh` | End-to-end exploit demonstration |
| `reset-demo/` | Scripts to restore clean state |

## Comparison With Docker Escape (cve-claude-sandbox-docker)

| | Docker Escape | Hook Escape |
|---|---|---|
| Requires Docker | Yes | No |
| Requires bind mount | Yes | No |
| Trigger mechanism | User runs test script | Automatic (next tool use) |
| Extra config needed | `excludedCommands` for Docker | Hooks exist (intended use) |
| Stages | Two (inject → Docker run → settings overwrite) | One (inject → auto-trigger) |
| Goal | Weaken sandbox config | Bypass sandbox entirely |

## Recommended Mitigation: Sandboxed-by-Default Hooks

The root cause is that all hooks run unsandboxed. Most hooks don't need host access —
a `PreToolUse` check that inspects tool input and returns allow/deny can run inside
the sandbox just fine.

**Proposal**: Add a per-hook `sandboxed` flag, defaulting to `true`:

```json
{
  "type": "command",
  "command": ".claude/hooks/pre-bash.sh",
  "sandboxed": false
}
```

This moves the trust decision into `settings.json`, which **is** protected from
sandbox writes. An attacker can modify the script, but cannot escalate a sandboxed
hook to unsandboxed. The `"sandboxed": false` opt-in becomes the user's explicit
acknowledgment that the referenced script is trusted and protected from modification.
