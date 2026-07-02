---
name: dont-mind-me
description: Manages the creation and update of gitignore and other ignore files in repositories. It leverages templates from github/gitignore or other online sources, combines multiple technologies/IDEs, supports subdirectory-specific ignore files, and understands a wide range of famous ignore formats like .dockerignore, .npmignore, and more.
license: Apache-2.0
metadata:
  author: Ivan De Marino (http://github.com/detro)
  version: 1.0.0
---

# Don't Mind Me

> Authored and maintained by **Ivan De Marino**.

This skill manages the creation, combination, and update of ignore files (such as `.gitignore`, `.dockerignore`, `.npmignore`, and more) within any repository. It uses the community-vetted templates from the official [github/gitignore](https://github.com/github/gitignore) repository as well as other reliable online sources, supporting multi-technology projects and sub-directory specific rules.

## When to Use

- Bootstrapping a new repository with standard ignore rules for a language (e.g., Rust, Python, Go) or IDE (e.g., VS Code, IntelliJ, Xcode).
- Updating an existing `.gitignore` or other ignore files when adding a new framework, language, or developer tool to a project.
- Setting up specialized ignore files such as `.dockerignore` (to reduce container build context size) or `.npmignore` (to exclude test/development files from npm packages).
- Adding sub-directory specific ignores to restrict or customize rules within complex or monorepo layouts.

## When Not to Use

- Standard code refactoring tasks that do not involve configuring file ignore patterns.
- Managing git repository configurations (e.g., `.gitattributes`, `.gitconfig`) or performing standard version control operations (e.g., branch switching, merging), unless specifically committing the newly created ignore files.

## Inputs

| Input                | Required | Description                                                                                                             |
|----------------------|----------|-------------------------------------------------------------------------------------------------------------------------|
| **tech_or_language** | Yes      | The programming languages, frameworks, or tools to ignore (e.g., `Rust`, `Node`, `Python`). Can be multiple.            |
| **ides_or_tools**    | No       | The development environments, editors, or operating systems to ignore (e.g., `VisualStudioCode`, `JetBrains`, `macOS`). |
| **ignore_type**      | No       | The type of ignore file to manage. Defaults to `.gitignore`.                                                            |
| **target_directory** | No       | The directory path where the ignore file should be placed (defaults to the root directory `.`).                         |

---

## I Know, For Example, About Those Types of Ignores

Below is a non-exhaustive list of the diverse types of ignore files used across version control, build systems, deployment platforms, formatters, and search tools that this skill knows how to configure:

| Ignore File            | Primary Technology / Tool               | Typical Use / Ignored Items                             | Pattern Syntax & Nuances                                                                                                                                         |
|:-----------------------|:----------------------------------------|:--------------------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **`.gitignore`**       | Git VCS                                 | Development artifacts, logs, dependencies, IDE settings | Standard git ignore patterns: supports unanchored (`*.log`) vs anchored (`/debug.log`), negation (`!`), and doublestar recursive directory globbing (`**/logs`). |
| **`.cvsignore`**       | CVS VCS                                 | Legacy CVS build targets                                | Early 1990s predecessor to `.gitignore`. Standard simple glob matching.                                                                                          |
| **`.hgignore`**        | Mercurial VCS                           | Mercurial repository ignores                            | Supports multiple syntax styles in a single file via `syntax: glob` or `syntax: regexp`.                                                                         |
| **`.bzrignore`**       | Bazaar VCS                              | Bazaar repository ignores                               | Controls files ignored for registration in Bazaar.                                                                                                               |
| **`P4IGNORE`**         | Perforce VCS                            | Perforce workspace ignores                              | Ignored patterns specified in local workspace files or the environment.                                                                                          |
| **`.ignore`**          | Search/FS Tools (e.g., `ripgrep`, `fd`) | General tool-agnostic file filtering                    | Shared search-ignore file format supported natively by `ripgrep` and `fd`.                                                                                       |
| **`.dockerignore`**    | Docker Container Tool                   | Docker build context exclusions                         | Shrinks the Docker build context. Uses Go's `filepath.Match` syntax, differing slightly from Git's unanchored directory matching behavior.                       |
| **`.containerignore`** | Podman / Buildah                        | OCI container build context                             | OCI-compliant alternative to `.dockerignore`.                                                                                                                    |
| **`.npmignore`**       | npm / Node.js package manager           | npm package publishing exclusions                       | Prevents publishing source files/assets. Falls back to `.gitignore` rules if `.npmignore` is not present.                                                        |
| **`.helmignore`**      | Helm                                    | Helm Chart files                                        | Filters out files when packaging/uploading Kubernetes charts.                                                                                                    |
| **`.vscodeignore`**    | VS Code Extension Packaging             | VS Code extension assets                                | Excludes development files when publishing or packaging extensions.                                                                                              |
| **`.gcloudignore`**    | Google Cloud CLI                        | Cloud upload files                                      | Controls what files are uploaded during `gcloud` app deployments and build triggers.                                                                             |
| **`.vercelignore`**    | Vercel Deployment                       | Deployment artifact exclusions                          | Legacy name was `.nowignore`. Ignores files from being sent to Vercel builds.                                                                                    |
| **`.slugignore`**      | Heroku Cloud Platform                   | Heroku slug compilation                                 | Excludes source/config files from the final Heroku container runtime slug.                                                                                       |
| **`.ebignore`**        | AWS Elastic Beanstalk                   | Beanstalk environment uploads                           | Controls files ignored by the EB CLI during deployment.                                                                                                          |
| **`.cfignore`**        | Cloud Foundry                           | Cloud Foundry deployment                                | Excludes development files from push bundles to Cloud Foundry space.                                                                                             |
| **`.artifactignore`**  | Azure DevOps                            | Azure Artifacts packaging                               | Reference and configuration for publishing Azure Artifacts.                                                                                                      |
| **`.funcignore`**      | Azure Functions CLI                     | Function app package                                    | Controls what gets packaged and uploaded for serverless functions.                                                                                               |
| **`.prettierignore`**  | Prettier Formatter                      | Formatting target exclusions                            | Avoids auto-formatting vendor, minified, or build files.                                                                                                         |
| **`.eslintignore`**    | ESLint Linter                           | Linting target exclusions                               | Prevents linting third-party libraries, compiled scripts, or build directories.                                                                                  |
| **`.stylelintignore`** | Stylelint CSS Linter                    | Style linting exclusions                                | Prevents CSS/SCSS linting for third-party styles or build outputs.                                                                                               |
| **`.rgignore`**        | `ripgrep` Search Tool                   | Search-specific exclusions                              | Ignores files/dirs during search (often legacy now in favor of `.ignore`).                                                                                       |
| **`.agignore`**        | The Silver Searcher (`ag`)              | Search-specific exclusions                              | Excludes directories/files from Silver Searcher index.                                                                                                           |
| **`.chefignore`**      | Chef Configuration                      | Chef repository cookbooks                               | Ignores files during upload/management of Chef cookbooks.                                                                                                        |
| **`CODEOWNERS`**       | GitHub / GitLab / Gitea                 | Code ownership definition                               | Uses Gitignore-style globs but generally drops negation (`!`), character ranges (`[]`), and backslash escaping (`\#`).                                           |

---

## Workflow

### Step 1: Detect Targets & Directory Scope

Before writing any ignore file, clarify the scope and targets:
1. **Identify Target Directory:** Check if the file goes to the repository root (e.g., `./.gitignore`) or to a specific subdirectory (e.g., `./services/api/.gitignore`).
   - *Why:* Path-based rules act differently when defined inside a subdirectory. If a pattern like `/target` is declared in a root-level ignore file, it matches only `target` at the root. If it is declared in `services/api/.gitignore`, it matches `services/api/target`.
2. **Determine Ignore Type:** Check if you are writing `.gitignore` or another ignore file (e.g., `.dockerignore`, `.npmignore`).
3. **Scan Project Tech:** Look at the project files to suggest the best languages, IDEs, and environments if the user didn't specify them.
   - For example: if a `Cargo.toml` exists, suggest `Rust`. If `package.json` exists, suggest `Node`.

### Step 2: Fetch Base Templates from github/gitignore

Retrieve official, community-tested templates from the `github/gitignore` repository using your high-level platform fetch tool (like `fetch` or `agentic_fetch`):
1. **Determine Template Filename:** 
   - Language templates reside at:
     ```
     https://raw.githubusercontent.com/github/gitignore/main/<Language>.gitignore
     ```
     *(e.g., `Rust.gitignore`, `Python.gitignore`, `Go.gitignore`)*
   - Global templates (IDEs, OSs, Global tools) reside at:
     ```
     https://raw.githubusercontent.com/github/gitignore/main/Global/<IDE-or-OS>.gitignore
     ```
     *(e.g., `VisualStudioCode.gitignore`, `macOS.gitignore`, `JetBrains.gitignore`)*
2. **Handle Capitalization & Spacing:** The GitHub repository is case-sensitive. Ensure proper capitalization (e.g. `Rust` rather than `rust`, `Go` rather than `go`).
3. **Handle Missing Templates / Alternatives:**
   - If a specific tool or framework isn't listed in the official `github/gitignore` repo, perform a search or fetch from alternative reliable sources (like `https://www.toptal.com/developers/gitignore/api/<tech>`).

### Step 3: Combine and Deduplicate

When combining templates for multiple technologies (e.g., Python + VS Code + macOS):
1. **Separate with Clear Headers:** Add a clear header for each template to make the file easy to read and update later.
   ```text
   # ==========================================
   # Created by dont-mind-me: Rust
   # ==========================================
   ... (Rust rules here) ...

   # ==========================================
   # Created by dont-mind-me: VisualStudioCode
   # ==========================================
   ... (VS Code rules here) ...
   ```
2. **Deduplicate Rules:** Keep track of identical rules across different templates (e.g., `.DS_Store` appearing in both macOS and other templates) and only include the rule in the first section it appears, or group common global files into their own section.
   - *Why:* Clean files prevent confusion and reduce processing overhead for git or build systems.

### Step 4: Adapt Syntax for Other Ignore Formats

If configuring an ignore file other than `.gitignore`, translate Git-style patterns into the correct target format:
- **`.dockerignore`:** 
  - *Why:* Docker build contexts are loaded from the root context path. Rules are resolved using Go's `filepath.Match`, which doesn't support unanchored directory matching like Git does (e.g., `build` ignores both `build` file and `build/` directory recursively in git, but in Docker, you should use `**/build` or specify nested paths).
  - *How:* Convert unanchored directory patterns by ensuring they are covered recursively. Keep rules specific to the files needed for the container build.
- **`.npmignore`:**
  - *Why:* `.npmignore` prevents shipping internal development artifacts to registry bundles, making packages lightweight and secure.
  - *How:* Maintain a subset of `.gitignore` targets, ensuring files like compiled binaries, tests, mock files, and configuration dotfiles are excluded.
- **`.hgignore`:**
  - *Why:* Mercurial supports regexes as well as globs.
  - *How:* Write a `syntax: glob` header at the top to safely reuse standard globbing patterns.

### Step 5: Write and Verify the Ignore File

1. **Verify Existing Content:** If the target ignore file already exists, do not overwrite it blindly. Read it first to identify if there are any custom rules defined by the user. Preserve those custom rules in their own section (e.g., `# Custom Rules`).
2. **Write the Content:** Write the newly constructed ignore content to the target path.
3. **Run Verification:**
   - Run `git status` or checking tools to verify that previously untracked build artifacts are now ignored correctly.

---

## Validation

- [ ] The ignore file is created at the correct relative path (`target_directory`).
- [ ] Each included technology or environment template has a clear, separated header.
- [ ] Duplicated lines across combined templates are eliminated.
- [ ] Existing custom rules are fully preserved and not overwritten.
- [ ] The syntax matches the requirements of the requested `ignore_type` (e.g., `.dockerignore` or `.hgignore`).

## Common Pitfalls

| Pitfall                                            | Solution                                                                                                                                                                                    |
|----------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Casing mismatch on GitHub URLs**                 | Always verify the correct template filename casing on the `github/gitignore` repository before fetching. Fall back to search or Toptal gitignore API if casing is unclear.                  |
| **Overwriting custom developer rules**             | Always read the existing ignore file first, extract custom non-templated rules, and merge them safely rather than completely replacing the file.                                            |
| **Ignoring files that are already tracked by git** | Git does not retroactively ignore files that are already tracked. If a user asks to ignore a file that is already tracked, advise them to run `git rm --cached <file>` to stop tracking it. |
| **Path resolution in subdirectories**              | Ensure subdirectory `.gitignore` rules use relative paths relative to that subdirectory, not relative to the repository root.                                                               |
