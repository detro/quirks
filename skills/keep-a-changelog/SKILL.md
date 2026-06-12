---
name: keep-a-changelog
description: Manages the project's CHANGELOG.md following Keep a Changelog format. Bootstraps a new changelog from scratch, creates entries for new releases, or updates an in-progress (unreleased) entry in-place — all based on git history and tags.
license: Apache-2.0
metadata:
  author: Ivan De Marino (http://github.com/detro)
  version: 2.1.0
---

# Keep a Changelog

> Authored and maintained by **Ivan De Marino**.

This skill manages the project's `CHANGELOG.md` — bootstrapping it from scratch, creating new version entries, or updating unreleased entries in-place.

## Format

The changelog follows [Keep a Changelog v1.1.0](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Each release entry uses this structure:

```markdown
## [<version>] - <YYYY-MM-DD>

### Added
- New features or capabilities.

### Changed
- Changes to existing functionality.

### Fixed
- Bug fixes.

### Removed
- Removed features (use only when applicable).
```

**Rules:**

- Use only the sections that have content (`Added`, `Changed`, `Fixed`, `Removed`). Omit empty sections.
- Each bullet should be a concise, user-facing description of the change — not a commit message copy-paste.
- Group related commits into a single bullet when they represent a single logical change.
- Pure documentation or CI-only changes (e.g., "Updated `AGENTS.md`") may be grouped under `Changed` if meaningful, or omitted if trivial.
- The date should be today's date in `YYYY-MM-DD` format.

## Workflow: Detect Whether to Create, Update, or Bootstrap

Before writing anything, determine the current state:

1. **Check if `CHANGELOG.md` exists and has entries:**

   If the file does not exist, or exists but contains no `## [<version>]` headings, proceed to **Mode C: Bootstrap**.

2. **Check if any git tags exist:**

   ```bash
   git tag --sort=-v:refname | head -1
   ```

   If no tags exist at all, proceed to **Mode C: Bootstrap** (even if a `CHANGELOG.md` with entries exists — treat it as a fresh project).

3. **Extract the latest version from `CHANGELOG.md`:**

   Parse the first `## [<version>]` heading in the file to get the version string (e.g., `1.6.0`).

4. **Check if a git tag exists for that version:**

   ```bash
   git tag --list "v<version>"
   ```

   For example, if the latest entry is `## [1.6.0]`, check for tag `v1.6.0`.

5. **Decide the mode:**

   - **No file, no entries, or no tags at all** → **Mode C: Bootstrap** a new `CHANGELOG.md`.
   - **Tag exists for latest entry** → **Mode A:** the latest entry is a released version. Create a new entry at the top.
   - **Tag does NOT exist for latest entry** → **Mode B:** the latest entry is still a work-in-progress. Update the existing entry in-place.

### Mode A: Create a New Entry (tag exists for latest entry)

This is the standard flow. The new entry is inserted at the top, immediately after the file header (before the previous release entry).

1. **Determine the version number:** If the user provided a version number upfront (e.g., "create a 2.0.0 entry"), use it. If no version was specified, **ask the user** what version the new entry should be before proceeding. Do not guess or infer the version number — always confirm with the user.

2. **Gather changes:** Follow the steps in [Determining What Changed](#determining-what-changed) using the latest tag as the baseline.

### Mode B: Update an Existing Unreleased Entry (no tag for latest entry)

When the latest changelog entry has no corresponding git tag, it represents an in-progress release. Instead of creating a new entry:

1. **Find the baseline tag:** Since the latest entry's version has no tag, find the tag that was the baseline for that entry. This is the most recent tag that actually exists:

   ```bash
   git tag --sort=-v:refname | head -1
   ```

2. **Gather all commits since that baseline tag** using the steps in [Determining What Changed](#determining-what-changed) with this baseline tag.

3. **Rewrite the existing top entry** by replacing its entire content (from the `## [<version>]` heading down to but not including the next `## [` heading) with freshly generated content based on ALL commits since the baseline tag.

4. **Preserve the version number** from the existing entry unless the user explicitly requests a version bump. Update the date to today's date.

5. **Important:** This is a full rewrite of the entry, not an append. Re-analyze all commits since the baseline tag to produce a complete, coherent entry. This ensures removed or squashed commits are reflected and duplicates are avoided.

### Mode C: Bootstrap a New CHANGELOG.md (no file, no entries, or no tags)

When starting a brand-new project — no `CHANGELOG.md` exists, or the file has no version entries, or no git tags exist yet:

1. **Create (or overwrite) `CHANGELOG.md`** with the standard [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) file header:

   ```markdown
   # Changelog

   All notable changes to this project will be documented in this file.

   The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
   and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
   ```

2. **Determine the baseline for commits:**

   - If tags exist but the file is missing/empty: use the latest tag as the baseline (same as Mode A).
   - If no tags exist at all: use the **root commit** of the repository as the baseline, so that all commits in the repo's history are considered:

     ```bash
     git rev-list --max-parents=0 HEAD
     ```

3. **Gather all commits since the baseline** using the steps in [Determining What Changed](#determining-what-changed).

4. **Generate the first version entry** and place it immediately after the file header. The version number should be determined by the user's request or inferred as `0.1.0` if not specified (following SemVer conventions for initial development).

5. **Date** should be today's date in `YYYY-MM-DD` format.

## Determining What Changed

1. **Find the last tagged release:**

   ```bash
   git tag --sort=-v:refname | head -1
   ```

2. **List commits since that tag:**

   ```bash
   git log <last-tag>..HEAD --oneline --no-merges
   ```

3. **Get detailed commit info (messages and bodies):**

   ```bash
   git log <last-tag>..HEAD --no-merges --format="%h %s%n%b---"
   ```

4. **Get a file-level summary of what changed:**

   ```bash
   git diff <last-tag>..HEAD --stat
   ```

5. **Read specific diffs** for commits or files that need more context to write an accurate changelog bullet.

Use the commit messages as a starting point, but always read the actual diffs to understand the real impact. Conventional Commit prefixes (`feat`, `fix`, `chore`, `refactor`, `test`, `docs`) help classify changes:

| Commit Prefix | Changelog Section |
|---------------|-------------------|
| `feat`        | Added             |
| `fix`         | Fixed             |
| `refactor`    | Changed           |
| `chore`       | Changed (or omit if trivial) |
| `test`        | Added (if new test coverage) or Changed (if refactoring tests) |
| `docs`        | Changed (or omit if trivial) |

## Identifying Contributors

When a commit originates from a merged pull request by someone other than the repository owner:

1. **Detect PR merges** in the full log (including merge commits):

   ```bash
   git log <last-tag>..HEAD --merges --format="%h %s"
   ```

   Merge commits from GitHub typically have the format: `Merge pull request #<number> from <org>/<branch>`.

2. **Identify the PR author** by inspecting the commits within each merged PR, or by checking
   `git log --format="%an <%ae>"` for non-merge commits associated with that PR branch.

3. **Credit the contributor** at the end of the relevant changelog bullet using this format:

   ```markdown
   - Description of the change. Thank you to [@username](https://github.com/username) for the contribution!
   ```

   If the GitHub username cannot be determined from the git author name, use the git author name directly.

4. **Omit contributor attribution** for commits authored by the repository owner(s) — only credit external contributors.

## Examples

### Example 1: Creating a New Entry (Mode A)

Given that the latest changelog entry is `## [1.5.1-rc1]` and tag `v1.5.1-rc1` exists, and these commits since `v1.5.1-rc1`:

```
29ab8fc chore(docs): update docs to mention the new 'completion' command
eb4edae feat(cli): adding 'completion' command to generate bash/zsh/fish auto-complete
e81cc71 fix: hash command args when spawning k8s job    (from merged PR by @snyk-thannan)
```

The resulting **new** changelog entry inserted at the top:

```markdown
## [1.6.0] - 2026-03-27

### Added

- Command `debops completion <shell>` to generate shell auto-completion scripts for `bash`, `zsh`, and `fish`.

### Changed

- Updated `AGENTS.md` and `README.md` with the latest changes and features.

### Fixed

- Spawned Kubernetes Job names now include a hash of the command arguments, allowing parallel invocations
  of the same base command with different arguments to spawn distinct jobs without name collisions.
  Thank you to [@snyk-thannan](https://github.com/snyk-thannan) for the fix!
```

### Example 2: Updating an Existing Unreleased Entry (Mode B)

The latest changelog entry is `## [1.6.0] - 2026-03-27`, but tag `v1.6.0` does **not** exist. The most recent actual tag is `v1.5.1-rc2`. Since the initial entry was written, new commits have landed.

All commits since `v1.5.1-rc2`:

```
a1b2c3d feat(cli): add --output flag for JSON output in gather command
29ab8fc chore(docs): update docs to mention the new 'completion' command
eb4edae feat(cli): adding 'completion' command to generate bash/zsh/fish auto-complete
e81cc71 fix: hash command args when spawning k8s job    (from merged PR by @snyk-thannan)
```

The existing `## [1.6.0]` entry is **rewritten in-place** with all commits since `v1.5.1-rc2`, and the date updated to today:

```markdown
## [1.6.0] - 2026-03-28

### Added

- Command `debops completion <shell>` to generate shell auto-completion scripts for `bash`, `zsh`, and `fish`.
- New `--output` flag for the `gather` command to support JSON output format.

### Changed

- Updated `AGENTS.md` and `README.md` with the latest changes and features.

### Fixed

- Spawned Kubernetes Job names now include a hash of the command arguments, allowing parallel invocations
  of the same base command with different arguments to spawn distinct jobs without name collisions.
  Thank you to [@snyk-thannan](https://github.com/snyk-thannan) for the fix!
```

### Example 3: Bootstrapping a New CHANGELOG.md (Mode C)

A brand-new project has no `CHANGELOG.md` and no git tags. The full commit history is:

```
f1a2b3c feat: add CLI entry point with 'gather' and 'reset-offset' commands
d4e5f6a feat: kafka consumer for offset storage topic
c7b8a9d chore: initial project setup with Go module, Taskfile, and CI config
```

The skill creates a new `CHANGELOG.md` from scratch:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-03-28

### Added

- CLI entry point with `gather` and `reset-offset` commands.
- Kafka consumer for reading the Debezium offset storage topic.
- Initial project setup with Go module, Taskfile, and CI configuration.
```

## Checklist Before Finishing

- [ ] Determined the correct mode (A: new entry, B: update unreleased, C: bootstrap).
- [ ] If Mode C: file has the standard Keep a Changelog header and first entry covers all commits.
- [ ] If Mode B: updated the existing entry in-place (full rewrite from baseline tag).
- [ ] If Mode A: created a new entry at the top of the changelog.
- [ ] Version number is correct (preserved from existing entry in Mode B, unless user requested a bump).
- [ ] Date is set to today.
- [ ] Only non-empty sections are included.
- [ ] Bullets describe user-visible impact, not implementation details.
- [ ] External contributors are credited with a link to their GitHub profile.
- [ ] No duplicate information across bullets.
- [ ] Existing entries below the target entry are untouched.
