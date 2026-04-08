# Vulnerability Analysis: Hook Scripts as Sandbox Escape

## Core Design Flaw

Claude Code hooks are designed to run **outside** the sandbox — they need host access
to enforce policies, run linters, etc. But the scripts they reference can live **inside**
the project directory, which is writable from inside the sandbox.

This creates a **write-to-execute bridge** across the sandbox boundary:

```
INSIDE SANDBOX                    OUTSIDE SANDBOX
(writes allowed to project)       (hooks execute with host privileges)
                                  
  Edit .claude/hooks/pre-bash.sh ──> pre-bash.sh runs on next tool use
                                       ├── arbitrary host code execution
                                       └── can overwrite settings.json
```

## Why This Is Worse Than The Docker Escape

The Docker escape (cve-claude-sandbox-docker) requires:
1. Docker to be installed and running
2. A bind mount to be configured  
3. A build/test script to trigger execution inside Docker

The hook escape requires **nothing extra**:
1. No Docker needed
2. No special configuration beyond hooks existing (which is their intended use)
3. Self-triggering — Claude's next tool use fires the hook automatically

## The Fundamental Problem

The sandbox treats `.claude/settings.json` as protected (it controls the sandbox itself),
but does NOT protect hook scripts referenced by settings.json. These scripts have the
same privilege level as settings.json when they execute — they run on the host and can
modify settings.json freely.

Any file referenced by a hook's `command` field should be treated with the same
protection level as `settings.json` itself.

## Attack Surface

An attacker only needs to:
1. Read `.claude/settings.json` to find hook script paths
2. Write to any of those scripts (allowed by sandbox — they're project files)
3. Wait for the hook to trigger (automatic on next matching tool use)

## Affected Configurations

Any project where:
- `hooks` are defined in `.claude/settings.json` or `.claude/settings.local.json`
- The hook `command` references a script inside the project directory
- The sandbox is enabled (this is the irony — sandbox-enabled projects are vulnerable)

## Mitigations (Recommendations)

1. **Sandbox should protect hook scripts**: Any file path referenced in a hook `command`
   should be read-only from inside the sandbox
2. **Integrity checking**: Hash hook scripts when settings are loaded; refuse to run
   if the hash changes during a session
3. **Warn on in-project hooks**: Flag hook commands that reference project-local paths
   as a security consideration in documentation
4. **Separate hook storage**: Encourage hooks to live outside the project directory
   (e.g., `~/.claude/hooks/`) where the sandbox can't reach them
