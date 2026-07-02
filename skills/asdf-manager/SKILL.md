---
name: asdf-manager
description: Manage project runtime dependencies, tool versions, and plugins using asdf-vm. Proposes asdf to resolve missing script runtimes (e.g. Python, Perl) and handle tool updates with strict security checks for custom plugins.
license: Apache-2.0
metadata:
  author: Ivan De Marino (http://github.com/detro)
  version: 1.2.0
---

# ASDF Manager

This skill allows agents to manage project tool versions and dependencies using `asdf`. It handles the creation and updating of `.tool-versions` files, installs and updates plugins, and enforces essential security guardrails when installing third-party plugins.

## When to Use

- When a project uses `asdf` for managing runtime environments (e.g. Node.js, Python, Ruby, Go, Elixir, Rust).
- When a `.tool-versions` file exists in the repository, or the user wants to set up multi-runtime versioning.
- When the user asks to "update all tools" or set a tool to its "latest" version.
- When the user wants to add a new development tool, language runtime, or utility that is manageable via `asdf`.
- When an agent is trying to run a script in Python, Perl, or another scripting language, but is struggling to find the required runtime on the host system, especially if the project is already leveraging `asdf` (e.g., contains a `.tool-versions` file).

## When Not to Use

- When the project is explicitly configured to use another package/runtime manager (such as `mise`, `fnm`, `nvm`, `pyenv`, `rbenv`, `gvm`, or `asdf-vm` is not installed/desired).
- When installing packages that should be managed via system-level package managers (like `brew`, `apt`, `pacman`, or `dnf`) and do not require per-project version locking.

## Inputs

| Input     | Required | Description                                                                                                        |
|-----------|----------|--------------------------------------------------------------------------------------------------------------------|
| Tool Name | Yes      | The name of the runtime or tool (e.g., `nodejs`, `python`, `golang`).                                              |
| Version   | No       | The specific version to set or install (e.g., `18.16.0`, `latest`, `system`).                                      |
| Action    | Yes      | The operation to perform: `update-all`, `install-tool`, `set-version`, `add-plugin`, or `propose-missing-runtime`. |
| Global    | No       | Set to `true` to apply the configuration globally (`$HOME/.tool-versions`) instead of the local project directory. |

## Workflow

### Step 1: Detect and Validate ASDF Environment

Before executing any `asdf` commands, verify that `asdf` is installed and accessible in the agent's current shell environment:
1. Run `which asdf` or `asdf --version`.
2. If `asdf` is not found, check common installation paths (such as `$HOME/.asdf/bin/asdf` or `/opt/homebrew/bin/asdf`). If it is installed but not sourced, guide the user on how to source it.
3. If `asdf` is completely missing from the system, **the skill must quit early** and inform the user:
   "Please install it from https://asdf-vm.com/guide/getting-started.html"
   - **Why**: The skill cannot proceed without the `asdf` core executable installed. Fast-failing with a helpful installation URL ensures a smooth user setup experience.

### Step 2: Handle "Update All Tools" requests

When the user asks to update all tools to their latest versions:
1. Locate the `.tool-versions` file (typically in the project root, or check parent directories).
2. Read the list of tools defined in the `.tool-versions` file.
3. For each tool found, execute the following command to automatically resolve and write the latest version:
   ```bash
   asdf set <tool-name> latest
   ```
   - **Why**: Using `asdf set <tool-name> latest` is more precise and robust than editing `.tool-versions` manually, because it triggers `asdf` to fetch the real, resolved, latest available version, download/compile it if necessary, and write the exact static version string back to the `.tool-versions` file.

### Step 3: Search and Add Plugins (Community Index Check)

When the user requests to install a tool/plugin:
1. First, check if the plugin is already installed by running:
   ```bash
   asdf plugin list
   ```
   If it is already installed, skip to **Step 5**.
2. If the plugin is not installed, verify if it exists in the official `asdf` community index:
   ```bash
   asdf plugin list all
   ```
   Filter or search the output for the desired tool name.
   - **Why**: Checking the community index ensures we only install curated and reviewed plugins. Third-party plugins outside the official index have the power to run custom hook scripts and compile/install untrusted binaries on the host system.

### Step 4: Strict Security Check for Custom/Non-Community Plugins

If the requested tool is **NOT** present in the official community index (`asdf plugin list all` output):
1. **Guide the Agent to search online** (e.g., via search engines, GitHub, or documentation) to find the correct, legitimate source repository URL for the `asdf` plugin.
2. **DO NOT proceed to install the custom plugin without explicit user permission.** This is a critical security boundary.
3. **Formulate a structured permission request** to the user containing:
   - A clear warning that the plugin is **not** in the official `asdf` community repository list.
   - The exact repository URL found for the plugin (e.g., `https://github.com/someone/asdf-mytool`).
   - A warning about the security implications of third-party plugins (which can execute arbitrary shell code during installation/use).
   - An explicit prompt asking for permission to proceed with installation.
4. If and only if the user consents, proceed to add the custom plugin using the verified URL:
   ```bash
   asdf plugin add <tool-name> <plugin-url>
   ```

### Step 5: Install and Set the Tool Version

Once the plugin is installed/added:
1. If the user requested a specific version, install it:
   ```bash
   asdf install <tool-name> <version>
   ```
   Otherwise, install the latest version:
   ```bash
   asdf install <tool-name> latest
   ```
2. Write the version to the project configuration:
   - For **local project versioning** (default):
     ```bash
     asdf set <tool-name> <version-or-latest>
     ```
   - For **global user-level versioning**:
     ```bash
     asdf set -u <tool-name> <version-or-latest>
     ```
3. Run `asdf reshim` after installation to ensure all shims are updated and the newly installed executable is immediately usable.

### Step 6: Propose and Install Missing Runtimes for Scripts

When an agent needs to execute a script (e.g., Python, Perl, Ruby, Bash, etc.) but cannot locate the necessary language runtime or interpreter on the host system:
1. **Analyze Project Context**: Check if the project is already leveraging `asdf` by looking for a `.tool-versions` file or `asdf` configurations in the current directory or parent directories.
   - **Why**: If the project already uses `asdf`, utilizing it to install the missing runtime keeps the environment consistent with existing project configurations and avoids polluting the global system or introducing version conflicts.
2. **Propose ASDF as an Option**: Instead of failing or trying to install the runtime globally via system package managers (which might require root/sudo privileges or cause environment contamination), propose using `asdf` to install the required runtime.
3. **Ask for Explicit User Permission**: Present a clear proposal to the user explaining:
   - Which runtime is missing (e.g., `python`, `perl`).
   - The script that needs to be executed.
   - Why `asdf` is the recommended path (e.g., local version isolation, existing `.tool-versions` file).
   - An explicit request for permission to add the plugin, install the runtime, and set the version locally.
   - **Why**: Installing a runtime compiles or downloads binaries and modifies the local workspace environment. Explicit user permission is a critical safety and transparency boundary before performing these changes.
4. **Install and Configure**: If and only if the user grants permission:
   - Identify the official plugin name (e.g., `python`, `perl`) using `asdf plugin list all`.
   - Add the plugin, install the specified/latest version, and set it locally (following **Steps 3, 4, and 5**).
   - Ensure the runtime is added to the project's local `.tool-versions` file so that future executions of the script are fully reproducible.

## Validation

- [ ] Run `asdf current` to verify that the newly set tool versions are active and resolve correctly in the directory.
- [ ] Ensure `.tool-versions` file matches the configured tools and versions.
- [ ] Check that custom plugins added outside the official index were only installed after explicit user confirmation.
- [ ] Verify that missing script runtimes (like Python or Perl) are proposed and installed via `asdf` only after explicit user consent, and are properly written to the local `.tool-versions` file.

## Common Pitfalls

| Pitfall                                             | Solution                                                                                                                                                                                                                                     |
|-----------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `asdf: command not found` in agent shell            | `asdf` is likely installed but not sourced in the active shell. Locate `asdf.sh` (e.g., under `/opt/homebrew/opt/asdf/libexec/asdf.sh` or `$HOME/.asdf/asdf.sh`) and source it, or add `/shims` to `$PATH` dynamically in the agent context. |
| Tool executable does not run after install          | Run `asdf reshim` to regenerate the shims directory wrappers so the shell can locate the new binary.                                                                                                                                         |
| Installation fails due to missing compilation tools | Languages like Ruby, Python, and Erlang compiled from source using `asdf` require local build dependencies (like `gcc`, `openssl`, `make`, `libyaml`, etc.). Tell the user which dependencies are missing based on the build logs.           |
| Non-interactive shell blocks on interactive prompts | Ensure `asdf` commands are run non-interactively or dependencies are pre-satisfied.                                                                                                                                                          |
| Script still fails after installing runtime         | Check if the script contains a hardcoded absolute shebang (e.g., `#!/usr/bin/python3` or `#!/usr/bin/perl`). Suggest updating the shebang to use `#!/usr/bin/env <runtime>` (e.g., `#!/usr/bin/env python3`) so that `asdf` shims can intercept and resolve the execution path correctly. |

## References

- [ASDF Official Getting Started Guide](https://asdf-vm.com/guide/getting-started.html)
- [ASDF Configuration Options](https://asdf-vm.com/manage/configuration.html)
- [ASDF Official Community Plugins List](https://github.com/asdf-vm/asdf-plugins)
