---
name: keep-a-changelog
description: Manages the project's CHANGELOG.md following the detected or requested format (e.g., Keep a Changelog or HashiCorp/Terraform format). Bootstraps a new changelog, creates entries for new releases, or updates in-progress entries in-place based on git history.
license: Apache-2.0
metadata:
  author: Ivan De Marino (http://github.com/detro)
  version: 2.2.0
---

# Keep a Changelog (Multi-Format Support)

> Authored and maintained by **Ivan De Marino**.

This skill manages the project's `CHANGELOG.md` (or `CHANGELOG`) — bootstrapping it from scratch, creating new version entries, or updating unreleased/in-progress entries in-place. It supports multiple changelog formats, dynamically detects existing formats, and prompts the user to select or confirm the desired standard.

## Supported Formats

### 1. Keep a Changelog v1.1.0
This format adheres to [Keep a Changelog v1.1.0](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

- **Header Structure**: Standard markdown headings detailing compliance with the format.
- **Release Entry Heading**: `## [<version>] - <YYYY-MM-DD>` (e.g., `## [1.6.0] - 2026-03-27`).
- **Standard Categories**:
  - `### Added` — For new features.
  - `### Changed` — For changes in existing functionality.
  - `### Fixed` — For bug fixes.
  - `### Removed` — For now-removed features.
- **Conventions**: Empty categories are omitted. Each bullet point is a concise, user-facing summary.

### 2. HashiCorp / Terraform Provider Format
This format adheres to HashiCorp's changelog standard (commonly used for Terraform providers and other plugins).

- **Header Structure**: Mentions compliance with HashiCorp's versioning and changelog best practices.
- **Release Entry Heading**:
  - Unreleased / Upcoming: `## X.Y.Z (Unreleased)`
  - Released: `## A.B.C (Month Day, Year)` (e.g., `## 1.0.0 (March 27, 2026)`).
- **Standard Categories**:
  - `BREAKING CHANGES:` or `BACKWARDS INCOMPATIBILITIES:` — Brief documentation of incompatible changes and upgrade paths.
  - `NOTES:` — Deprecations, critical crash fixes, or unexpected upgrade behavior.
  - `FEATURES:` — Major improvements, such as new resources or data sources.
  - `IMPROVEMENTS:` or `ENHANCEMENTS:` — Smaller additions (e.g., attributes).
  - `BUG FIXES:` — Any fixed bugs.
- **Conventions**:
  - Every entry must match the syntax: `* subsystem: Descriptive message [GH-####]`
  - *Subsystem* is typically the resource name (e.g., `resource/instance`) or `provider` if global.
  - *PR Reference* `[GH-####]` must correspond to the GitHub pull request number.
  - Entries under each category are ordered **lexicographically** based on the subsystem (e.g., `resource/load_balancer` comes before `resource/subnet`). Cross-cutting changes (`provider`) are listed first.

### 3. Other / Custom Format
If the repository follows a custom standard, the agent prompts the user to specify or describe it, then proceeds to follow that custom layout and syntax.

---

## Workflow: Detect, Ask, and Decide Mode

Before writing or editing anything, execute this workflow to establish the format and update mode:

### Step 1: Detect or Prompt for Changelog Format

1. **Check for Existing Files**: Look for `CHANGELOG.md` or `CHANGELOG` in the root of the repository.
2. **Auto-Detect Format**:
   - If the file exists, inspect the top-level headings and entries:
     - Contains `## [<version>] - <YYYY-MM-DD>` or mentions `keepachangelog.com` → **Keep a Changelog** format.
     - Contains `(Unreleased)` or categories like `BREAKING CHANGES:`, `FEATURES:`, `IMPROVEMENTS:` or bullet points with `[GH-####]` → **HashiCorp** format.
3. **Ask/Confirm with the User**:
   - Always verify the detected format, or ask the user to choose when bootstrapping or if detection is ambiguous.
   - **Action**: Use the agent's interactive questioning tool (e.g., `question` in Crush, or the appropriate interactive tool in your platform) to present a clear option:
     - `"Keep a Changelog" format`
     - `"HashiCorp" format (Terraform providers, etc.)`
     - `"Other / Custom" format (please specify)`
   - Under the hood, document which format the changelog adheres to (both in the bootstrap header and in your internal execution context), and comply with it from that point forward.

### Step 2: Determine Update Mode

1. **Check if any git tags exist**:
   ```bash
   git tag --sort=-v:refname | head -1
   ```
   If no tags exist, proceed to **Mode C: Bootstrap** (even if a file exists, treat it as a fresh project).

2. **Extract the latest version from the changelog**:
   - Parse the first version heading using the pattern of the detected format (e.g., `## [1.6.0]` or `## 1.6.0 (Unreleased)`).

3. **Check if a git tag exists for that version**:
   - Check if the tag matches (e.g., `v1.6.0` or `1.6.0`).
   ```bash
   git tag --list "v<version>"
   git tag --list "<version>"
   ```

4. **Decide the mode**:
   - **No file, no tags, or empty file** → **Mode C: Bootstrap**.
   - **Tag exists for latest entry** (it represents a finalized release) → **Mode A: Create a New Entry** at the top.
   - **Tag does NOT exist for latest entry** (it represents a work-in-progress release or an "Unreleased" section) → **Mode B: Update Existing Entry** in-place.

---

## Workflow Modes

### Mode A: Create a New Entry (tag exists for latest entry)
1. **Determine Version**: Ask the user what the next version should be. Do not guess or infer the version number — always confirm with the user.
2. **Gather Changes**: Follow [Determining What Changed](#determining-what-changed) using the latest tag as the baseline.
3. **Insert Heading**:
   - For *Keep a Changelog*: Insert `## [<version>] - <YYYY-MM-DD>` at the top (under the file header).
   - For *HashiCorp*: If this is an upcoming unreleased version, insert `## <version> (Unreleased)`. If finalizing a release, insert `## <version> (Month Day, Year)`.

### Mode B: Update an Existing Unreleased Entry (no tag for latest entry)
1. **Find Baseline Tag**: Find the most recent tag that actually exists (which served as the baseline for this in-progress version):
   ```bash
   git tag --sort=-v:refname | head -1
   ```
2. **Gather Changes**: Retrieve all commits since that baseline tag.
3. **Rewrite Entry**:
   - Replace the entire top entry from the unreleased header down to the next version header.
   - Ensure you perform a full rewrite to avoid duplicates and accurately reflect any changes or squashed commits.
   - Preserve the unreleased designation or version number unless a bump is requested.

### Mode C: Bootstrap a New CHANGELOG
1. **Create the file**: Write `CHANGELOG.md` or `CHANGELOG`.
2. **Include Header**:
   - For *Keep a Changelog*:
     ```markdown
     # Changelog

     All notable changes to this project will be documented in this file.

     The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
     and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
     ```
   - For *HashiCorp*:
     ```markdown
     # Changelog

     All notable changes to this project will be documented in this file.

     The format is based on [HashiCorp's Changelog Best Practices](https://developer.hashicorp.com/terraform/plugin/best-practices/versioning).
     ```
3. **Generate First Entry**: Use the repository's root commit (or latest tag if tags exist but file is missing) as the baseline. Write the first entry at version `0.1.0` (or `1.0.0` or user's requested version) adhering to the chosen format structure.

---

## Determining What Changed

1. **Find the last tag**:
   ```bash
   git tag --sort=-v:refname | head -1
   ```
2. **List commits since tag with message/body**:
   ```bash
   git log <last-tag>..HEAD --no-merges --format="%h %s%n%b---"
   ```
3. **Extract PR numbers**:
   - Parse merge commits or commit subjects for pull request IDs (e.g., `(#123)` or `Merge pull request #123`). These are used to generate references like `[GH-123]` in HashiCorp format.

### Category and Subsystem Mapping

Map the conventional commit prefixes and file changes to the appropriate categories for each format:

| Commit Prefix                 | Keep a Changelog Section    | HashiCorp Section |
|-------------------------------|-----------------------------|-------------------|
| `feat` (new resource/feature) | Added                       | FEATURES:         |
| `feat` (enhancements)         | Added / Changed             | IMPROVEMENTS:     |
| `fix`                         | Fixed                       | BUG FIXES:        |
| `refactor` / `chore`          | Changed                     | IMPROVEMENTS:     |
| `breaking` / `!`              | Added/Changed (highlighted) | BREAKING CHANGES: |

#### Subsystem Determination (HashiCorp Format Only)
For HashiCorp format, parse the modified files in the commit diff to find the affected subsystem (e.g., `internal/provider/resource_aws_instance.go` -> `resource/aws_instance` or `provider`).
- Sort entries lexicographically by subsystem within each category.
- List global `provider` entries first.

---

## Examples

### Example: HashiCorp Format Entry
Given the following commits since `v1.1.0`:
- `feat: add resource_network_interface (#42)`
- `fix(resource/subnet): resolve IP allocation issue (#45)`
- `refactor(provider): configure custom user agent (#46)`

The resulting entry for version `1.2.0 (Unreleased)` or `1.2.0 (July 2, 2026)` will look like:

```markdown
## 1.2.0 (Unreleased)

FEATURES:

* **New Resource:** `network_interface` [GH-42]

IMPROVEMENTS:

* provider: Configure custom user agent [GH-46]

BUG FIXES:

* resource/subnet: Resolve IP allocation issue [GH-45]
```

---

## Checklist Before Finishing

- [ ] Used an interactive questioning tool (`question`) to confirm or select the format if bootstrapping or if detection was ambiguous.
- [ ] Complied with the exact conventions of the selected format (Keep a Changelog or HashiCorp).
- [ ] Grouped and classified commits accurately into standard category headers.
- [ ] If HashiCorp format: applied subsystem prefixes, sorted entries lexicographically by subsystem within categories, and appended `[GH-####]` PR references.
- [ ] Verified that any generated file clearly documents which format it follows.
- [ ] Preserved all existing untouched history below the edited section.
- [ ] Set correct dates and version tags in accordance with the format rules.
