# Codex CLI Overview

Guide to configuring and operating the Codex CLI for model-assisted development and automation.

## Table of Contents

- [Codex CLI Overview](#codex-cli-overview)
  - [Table of Contents](#table-of-contents)
  - [Repository \& Documentation](#repository--documentation)
  - [Configuration Overview](#configuration-overview)
    - [Sample config.toml](#sample-configtoml)
    - [Profiles](#profiles)
  - [CLI Reference](#cli-reference)
  - [Common Usage Examples](#common-usage-examples)
  - [Safety \& Best Practices](#safety--best-practices)
  - [Quick One-Liner](#quick-one-liner)

## Repository & Documentation

- Repository: https://github.com/openai/codex
- Config reference: https://github.com/openai/codex/blob/main/codex-rs/config.md

## Configuration Overview

Codex uses a layered configuration:

1. Global config (typically ~/.codex/config.toml)
2. Per-profile overrides (selected via --profile)
3. Inline overrides (-c key=val)
4. Command-line flags (highest precedence)

### Sample config.toml

Example with inline commentary to illustrate intent.

```toml
projects = { "/home/catalin/.codex" = { trust_level = "trusted" } , "/home/catalin/workspace/llm" = { trust_level = "trusted" } , "/home/catalin/workspace/llm/models/gpt-oss" = { trust_level = "trusted" } , "/home/catalin/workspace/playground/.tls" = { trust_level = "trusted" } }
# Codex CLI configuration
# Usage examples:
#   codex --profile dev                        # matches this project env
#   codex --profile read....                   # safest defaults
#   codex --profile full-auto                  # no approvals, full access (trusted only)
#   codex --model gpt4_1                       # override model for current profile
#   codex --model gpt-oss....                  # use local llama.cpp at :9000
# Tip: Set provider credentials via env vars (e.g., OPENAI_API_KEY).

default_profile           = "dev"
disable_response_storage  = false
hide_agent_reasoning      = true   # defaults to false

[history]
persistence = "none"  # "save-all" is the default value

[profiles.dev]
sandbox_mode    = "workspace-write"     # write within workspace only
approval_policy = "on-request"          # ask before privileged actions
model           = "gpt-5"

[profiles.read]
# Restrictive, review-friendly profile for read-only usage.
sandbox_mode    = "read-only"
approval_policy = "on-request"
model           = "gpt-5"


[profiles.full-auto]
# Unrestricted automation; only use in trusted environments.
sandbox_mode            = "danger-full-access"
approval_policy         = "never"
model                   = "gpt-5"
model_reasoning_effort  = "high"

[model_providers.ollama]
name      = "Ollama"
base_url  = "http://localhost:11434/v1"

[model_providers.llama]
name      = "Local Llama.cpp"
base_url  = "http://localhost:9000/v1"
api_key   = "none"
```

### Profiles

Purpose-aligned presets:
- dev: Balanced defaults for iterative coding in a controlled workspace.
- read: Safest inspection mode (no writes).
- full-auto: High-trust automation (avoid in untrusted environments).

Sandbox / filesystem modes:
- read-only: No mutation.
- workspace-write: Constrained edits.
- danger-full-access: Full host access (only when externally sandboxed).

Approval policies:
- untrusted: Only pre-approved “trusted” commands auto-run.
- on-request: Model chooses when escalation is needed.
- on-failure: Retry path—only escalate after failure.
- never: No human gate (auditable only via logs).

## CLI Reference

Canonical --help output for quick lookup.

```shell
Codex CLI

If no subcommand is specified, options will be forwarded to the interactive CLI.

Usage: codex [OPTIONS] [PROMPT]
       codex [OPTIONS] [PROMPT] <COMMAND>

Commands:
  exec        Run Codex non-interactively [aliases: e]
  login       Manage login
  logout      Remove stored authentication credentials
  mcp         Experimental: run Codex as an MCP server
  proto       Run the Protocol stream via stdin/stdout [aliases: p]
  completion  Generate shell completion scripts
  debug       Internal debugging commands
  apply       Apply the latest diff produced by Codex agent as a `git apply` to your local
              working tree [aliases: a]
  help        Print this message or the help of the given subcommand(s)

Arguments:
  [PROMPT]
          Optional user prompt to start the session

Options:
  -c, --config <key=value>
          Override a configuration value that would otherwise be loaded from
          `~/.codex/config.toml`. Use a dotted path (`foo.bar.baz`) to override nested values.
          The `value` portion is parsed as JSON. If it fails to parse as JSON, the raw string is
          used as a literal.

          Examples: - `-c model="o3"` - `-c 'sandbox_permissions=["disk-full-read-access"]'` -
          `-c shell_environment_policy.inherit=all`

  -i, --image <FILE>...
          Optional image(s) to attach to the initial prompt

  -m, --model <MODEL>
          Model the agent should use

      --oss
          Convenience flag to select the local open source model provider. Equivalent to -c
          model_provider=oss; verifies a local Ollama server is running

  -p, --profile <CONFIG_PROFILE>
          Configuration profile from config.toml to specify default options

  -s, --sandbox <SANDBOX_MODE>
          Select the sandbox policy to use when executing model-generated shell commands

          [possible values: read-only, workspace-write, danger-full-access]

  -a, --ask-for-approval <APPROVAL_POLICY>
          Configure when the model requires human approval before executing a command

          Possible values:
          - untrusted:  Only run "trusted" commands (e.g. ls, cat, sed) without asking for user
            approval. Will escalate to the user if the model proposes a command that is not in
            the "trusted" set
          - on-failure: Run all commands without asking for user approval. Only asks for approval
            if a command fails to execute, in which case it will escalate to the user to ask for
            un-sandboxed execution
          - on-request: The model decides when to ask the user for approval
          - never:      Never ask for user approval Execution failures are immediately returned
            to the model

      --full-auto
          Convenience alias for low-friction sandboxed automatic execution (-a on-failure,
          --sandbox workspace-write)

      --dangerously-bypass-approvals-and-sandbox
          Skip all confirmation prompts and execute commands without sandboxing. EXTREMELY
          DANGEROUS. Intended solely for running in environments that are externally sandboxed

  -C, --cd <DIR>
          Tell the agent to use the specified directory as its working root

  -h, --help
          Print help (see a summary with '-h')

  -V, --version
          Print version
```

## Common Usage Examples

Minimal prompt with default profile:

```shell
codex "Generate a concise summary of CONTRIBUTING guidelines."
```

Read-only inspection with local llama.cpp model:

```shell
codex exec -p read -c model_provider=llama -m gpt-oss "List key build steps."
```

Override model temperature inline:

```shell
codex -c models.gpt4_1.temperature=0.0 "Refactor this function for determinism."
```

Full-auto (sandboxed workspace writes) with explicit profile:

```shell
codex --full-auto -p dev "Add a CI badge to README."
```


## Safety & Best Practices

- Always start with read or dev profiles before escalating.
- Review model-suggested shell commands—avoid --dangerously-bypass-* outside isolated containers.
- Log and audit automation runs in full-auto mode.
- Keep API keys in environment variables; do not hardcode secrets.
- Use explicit -c overrides for reproducibility in CI.

## Quick One-Liner

```shell
codex exec -p read -c model_provider=llama -m gpt-oss "Say hi in one word."
```