# CVE PoC: Claude Code Sandbox Escape via Hook Script Modification

## Summary

As documented, Claude Code hooks run **outside** the sandbox with full host privileges. But Claude can edit scripts inside the sandbox, often without any user interaction. Therefore, directing claude to modify a script referenced in a hook is a prime target for executing arbitrary code and connecting to networks regardless of sandbox settings. It is trivial to immediately revert the hook script to avoid detection.

## Potential mitigations

- Default hooks to run inside the sandbox; opt-in to running outside the sandbox
- For backwards compatibility, flip the default, but this is the "insecure by default" approach

## Demo

```bash
./demo.sh              # run the exploit
```

This demo:

- Writes a payload to a file outside the sandbox
- Connects to the internet (google.com/generate_204) and writes the results to the same file
- Reverts the hook script to the original state

With these fundamental capabilities, the attacker can run arbitrary code, download arbitrayr payloads, and install arbitrary software on the host machine despite Claude Code running in full sandbox mode.
