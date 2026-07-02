# Agent Guide (AGENTS.md)

Welcome, fellow Agent! This repository, **Quirks**, is a curated collection of agentic skills compliant with the [agentskills.io](https://agentskills.io/) specification.

This guide provides the necessary architectural context, development patterns, coding conventions, and common gotchas you need to know when maintaining or extending this repository.

---

## 🏗️ Repository Architecture & Organization

The repository is lightweight and contains no compiled code or heavy dependencies. It is organized as follows:

```text
.
├── LICENSE
├── README.md
├── AGENTS.md               # This guide
└── skills/                 # The core directory containing all skills
    ├── <skill-name>/
    │   ├── SKILL.md        # The skill specification (frontmatter + instructions)
    │   └── scripts/        # (Optional) Supporting execution scripts
    │       └── <script>.sh
```

### The Role of `SKILL.md`
Each subdirectory under `skills/` defines a single "Quirk" (Skill). The `SKILL.md` file is the entry point. It has two parts:
1. **YAML Frontmatter**: Defines metadata that is parsed by agent platforms to register and trigger the skill:
   - `name`: Unique identifier for the skill.
   - `description`: A highly precise description of **when** and **why** the skill should be triggered.
   - `license`: Software license (typically `Apache-2.0`).
   - `metadata`: Sub-object containing `author` and `version`.
2. **Markdown Body**: Acts as the "runbook" for the agent. It explains the scope, step-by-step procedures, commands to run, and logic for fulfilling the skill.

---

## 🛠️ Development Conventions & Best Practices

When adding new skills or editing existing ones, adhere to the following principles:

### 1. The Quirks Curator Skill
- **Always use the local `quirks-curator` skill** (`skills/quirks-curator/SKILL.md`) to manage the creation or editing of skills in this repository. It enforces consistent frontmatter formatting, directory layout, Cognitive-First explanations, and Semantic Versioning management.

### 2. The Agent-Agnostic Goal
- Skills should be as agent-agnostic and operating-system-agnostic as possible.
- If a skill *must* target a specific environment (e.g., `crush-config-manage-models` targets the `charmbracelet/crush` agent), explicitly state its scope at the very beginning of the markdown body.

### 3. Cognitive-First Rule ("Explain the Why")
- When designing instructions, **never accept assumptions as facts**. Ask the user/creator questions to understand the underlying rationale behind every step or constraint.
- Explain the reasoning behind instructions inside the markdown text so that executing agents can adapt gracefully to unexpected edge cases.
- Leverage interactive/dialogue tools provided by the execution platform to clarify ambiguities (e.g., `question` in Crush, `AskUserQuestion` in Claude Code, `Ask User Tool` in Gemini CLI, or `Question` in Open Code).

### 4. No Network Access in Helper Scripts
- **Pattern**: Helper scripts (e.g., `catwalk.sh`) must **not** perform HTTP requests (e.g., via `curl` or `gh`).
- **Reasoning**: External network calls inside scripts are fragile and depend on the execution environment's networking tools.
- **Solution**: The agent should use its native high-level platform tools (like Crush's `fetch`/`download` or equivalent) to fetch any external data, save it to local temporary files, and pass those files to the helper script for processing.

### 5. Shell Scripting Guidelines
For helper scripts inside `scripts/`:
- Always start with `#!/usr/bin/env bash`.
- Use `set -euo pipefail` for robust error handling.
- Clearly document subcommands, arguments, and exit codes at the top of the file.
- Perform parameter validation and check for tool dependencies early (e.g., checking if `jq` is installed).

---

## ⚠️ Important Gotchas & Non-Obvious Patterns

### 1. `jq` Portability Gotcha (Critical)
- **Problem**: Some common builds of `jq` (notably certain Homebrew v1.8.x binaries on macOS) fail with a `function not defined: slurpfile/0` error when using `--slurpfile`.
- **Convention**: **Never use `--slurpfile`** in any script or ad-hoc command.
- **Workaround**: Load JSON files into memory as shell variables using `--argjson` and command substitution:
  ```bash
  # WRONG (fails on some jq builds)
  jq --slurpfile cur cur.json 'MAP USING $cur[0]' new.json

  # RIGHT (portable across all jq builds)
  jq --argjson cur "$(cat cur.json)" 'MAP USING $cur' new.json
  ```

### 2. Development Loop & Manual Installation
- A simple development loop is configured in this repository. Once a new skill is created or an existing one is updated, use the `task install` command (or simply `task` since it is the default task) to refresh/install the skills in the generic `~/.agents/skills/` directory that executing agents read:
  ```bash
  task install
  ```
- Under the hood, this deletes and replaces each skill directory present in this repository, while preserving other external skill directories.
- You can list the skills present in this repository, check their defined version versus their installed version, and detect any mismatches by running:
  ```bash
  task list
  ```
  This command parses the YAML frontmatter from `SKILL.md` files using `yq` and outputs a clean, styled Markdown table rendered by `glow`.
- You can regenerate and update the available skills table in the `README.md` by running:
  ```bash
  task update-readme
  ```
  This command dynamically parses all the `SKILL.md` files in the `skills/` directory to construct the markdown table between the comment markers in `README.md`.
- Ensure file paths, scripts, and relative assets referenced inside `SKILL.md` resolve correctly when executing in the context of the installed directory.

---

## 🧪 Testing and Verification

- There is no automated test suite or CI testing configured in this repository.
- **How to test**:
  1. Make your changes to the `SKILL.md` or helper scripts.
  2. Perform a manual dry run of the helper script using sample inputs (e.g., testing `catwalk.sh` subcommands like `compose` or `merge` with local mock JSON files).
  3. Ensure that the helper script returns appropriate exit codes (non-zero on failures/invalid JSON, `0` on success).
