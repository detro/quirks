---
name: ground-rules
description: Helps setup, view, and edit a global context or "ground rules" file for your AI agents (such as Crush, Claude Code, or Cursor), including configuring custom global context file paths and auto-detecting the executing agent.
license: Apache-2.0
metadata:
  author: Ivan De Marino (http://github.com/detro)
  version: 1.2.0
---

# Ground Rules

The `ground-rules` skill helps you setup, view, and update global context instructions (often called "ground rules" or global system prompts) for AI agents across different development environments. It automates locating the correct configuration directories, creating context files, and configuring agent-specific option files to track custom context paths.

## When to Use

- Initializing global, cross-project instructions for your development agents.
- Customizing the location of global instructions (e.g., pointing Crush to a custom path like `~/.agents/global-context.md` instead of the defaults).
- Reviewing or updating existing global ground rules.

## When Not to Use

- Managing project-specific context (e.g., local `.cursorrules`, `.clauderules`, or project-root `CRUSH.md` files). This skill is explicitly for global/user-wide guidelines.

## Inputs

| Input         | Required | Description                                                                                                                                      |
|---------------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| `action`      | Yes      | The action to perform: `setup` (initial setup), `view` (read current rules), or `edit` (update rules).                                           |
| `agent_name`  | No       | Target agent. If omitted, the skill will auto-detect the currently executing agent (e.g. `crush`, `claude-code`, etc.) or fallback to `generic`. |
| `custom_path` | No       | Custom path to store rules (e.g., `~/.agents/global-context.md`). If omitted, agent-specific defaults are used.                                  |
| `content`     | No       | The markdown content/system prompt to save as the ground rules.                                                                                  |

## Workflow

### Step 1: Auto-Detect Executing Agent and Determine Target Paths

The executing agent must auto-detect itself before determining the context file and configuration requirements.

#### 1. Auto-Detection Logic
- **Crush**:
  - Detection: Check if any environment variables start with `CRUSH_` (e.g., `CRUSH_CWD`, `CRUSH_EVENT`), or if Crush-specific tools (such as `crush_info` or `crush_logs`) are present in the available tools list, or if the runtime agent is known to be Crush.
- **Claude Code**:
  - Detection: Check if the environment variable `CLAUDE_CODE` is set to `1` or `true`, or if Claude-specific tools (such as `AskUserQuestion`) are available.
- **Generic / Other**:
  - Detection: Fallback when no platform-specific features are detected.

#### 2. Agent Configuration and Path Lookups
Based on the detected agent, lookup and configure standard paths and options:
- **Crush**:
  - Default global context files: `~/.config/crush/CRUSH.md` and `~/.config/AGENTS.md`.
  - Configuration File: `~/.config/crush/crush.json` (or `$XDG_CONFIG_HOME/crush/crush.json`).
  - Custom context paths requirement: Supports custom file paths by adding them to the `options.global_context_paths` array inside the global `crush.json`.
- **Claude Code**:
  - Default global context files: `~/.config/AGENTS.md` (or custom rulepaths/ignores if configured).
  - Configuration File: `~/.config/clauderules` or standard global agent instruction files.
- **Generic**:
  - Default global context file: `~/.config/AGENTS.md`.

If a `custom_path` is specified, resolve tilde (`~`) characters to the user's home directory path before proceeding. If the detected agent does not support registering a custom global context path array (like Crush does), inform the user that they must use the default path or manually configure their agent.

### Step 2: Perform Requested Action

#### Action: `setup` or `edit`
1. Prompt the user (or request if missing) for the rules content to be stored. Suggest/offer "Zio Ivan's global context" (included as an asset at `assets/zio-ivan-global-context.md` in the skill folder) as a starting point.
   - When suggesting this context, read `assets/zio-ivan-global-context.md` from the skill's assets directory and show/display its full contents to the user so they can inspect it before deciding.
   - If they opt to use Zio Ivan's global context, use its content.
   - If they prefer a different prompt or the file cannot be read, fall back to asking them for a custom prompt.
2. Ensure the parent directory of the target file path exists. Create it recursively if missing.
3. Write the markdown content to the target file path.
4. If the agent is `crush` and a `custom_path` is used, wire it up in the global config:
   - Check if the global config file exists at `~/.config/crush/crush.json` (or resolve standard path).
   - If it doesn't exist, initialize a clean, minimal JSON configuration:
     ```json
     {
       "$schema": "https://charm.land/crush.json",
       "options": {
         "global_context_paths": []
       }
     }
     ```
   - If it exists, read and parse the JSON. Use strict JSON manipulation to append/set the custom path within the `options.global_context_paths` array.
   - Save the updated config back to the global `crush.json`.

#### Action: `view`
1. Locate the active context file path (either the custom path specified/found in config, or the default paths).
2. Read and print the content of the file(s) so the user can inspect their active global rules.

### Step 3: Verify the Configuration

- Check that the context file has been written correctly.
- If using Crush with a custom path, verify that the path is listed in `~/.config/crush/crush.json` under `options.global_context_paths`.

## Validation

- [ ] Global context file exists and contains the expected content.
- [ ] No tilde (`~`) characters remain unresolved in configuration files; paths are stored as absolute or relative to known home roots.
- [ ] For Crush custom paths, the path is correctly added to `options.global_context_paths` in `~/.config/crush/crush.json`.
- [ ] Global configuration file remains valid JSON after modifications.

## Common Pitfalls

| Pitfall                                            | Solution                                                                                                                                                                         |
|----------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Shell expansion/Tilde (`~`) not resolving          | Always expand `~` using standard environment logic (`$HOME` or home path resolution) before reading or writing files via bash.                                                   |
| Corrupting `crush.json` format                     | Parse the JSON fully, modify the object programmatically (e.g., using `jq` or native language parsers), and serialize it back rather than trying to perform raw string replaces. |
| Target file exists and is overwritten accidentally | When running `setup`, check if the file already contains rules and prompt the user before overwriting, or append/edit selectively.                                               |
