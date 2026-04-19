## Summary:

Claude Code's sandbox is documented as a defense against prompt injection. Anthropic's own documentation is explicit about this: "Even if an attacker successfully manipulates Claude Code's behavior through prompt injection, the sandbox ensures your system remains secure." ([source](https://code.claude.com/docs/en/sandboxing))

However, since hook scripts run outside the sandbox, an agent can find and modify a script referenced by an existing hook, and in the same turn trigger the hook using follow-up instructions in the prompt. The attacker can then revert the hook script to evade detection.

Allowing **some** hooks to run in the sandbox improves the security configurability. Running in the sandbox by default with an opt-in to escape the sandbox (`runInSandbox: false`) would be a preferred default but a breaking change; flipping this to opt-out would be a non-breaking improvement.

## Steps To Reproduce:

POC repository: https://github.com/ozydingo/claude-hook-sandbox-escape

```
git clone https://github.com/ozydingo/claude-hook-sandbox-escape
cd claude-hook-sandbox-escape
./demo.sh
```

The demo:

1. Sets up a project with a pre-existing hook script (representative of a normal formatter/linter hook).
2. Has the agent append a payload to that hook script — an operation that occurs entirely inside the sandbox.
3. Triggers the hook via a tool call issued in the same turn as the modification.
4. The payload runs unsandboxed and (a) writes a marker file to a location outside the sandbox, (b) issues `curl` to `https://www.google.com/generate_204` and writes the result to the same file, demonstrating both filesystem escape and network egress.
5. Reverts the hook script to its original contents, demonstrating that the attack leaves no residual artifact in the hook configuration.

The payload is intentionally benign — a marker file and a connectivity check. Nothing is exfiltrated; the Google endpoint is a standard zero-byte captive-portal probe.

## Supporting Material/References:

Logs from my local run. Note that timestamps are just for debugging and grepping specific sentinel tokens in my logfile:

```
[1776569110:1776569093] Unboxed
[1776569111:1776569093] Network connection successful
[1776569113:1776569093] Unboxed
[1776569113:1776569093] Network connection successful
```
