---
name: quirks-curator
description: Scaffolds, edits, and curates agent skills (quirks) for the Quirks repository conforming to the agentskills.io specification. Use when creating a new skill, updating an existing skill, generating or modifying SKILL.md files, managing semantic versions, or setting up skill directory structures. Handles frontmatter generation, version bumping, section templates, and validation.
license: Apache-2.0
metadata:
  author: Ivan De Marino (http://github.com/detro)
  version: 1.1.0
---

# Quirks Curator

This skill helps you scaffold, edit, and curate agent skills (quirks) that conform to the [agentskills.io](https://agentskills.io/) specification and the **Quirks** repository conventions.

## When to Use

- Creating a new skill from scratch in this repository.
- Updating or editing an existing skill's `SKILL.md`, associated scripts, references, or assets.
- Managing semantic versions (`metadata.version` in frontmatter) during updates—prompting the user with suggestions or automations for version bumping.
- Generating or modifying a `SKILL.md` file with proper YAML frontmatter and section templates.
- Setting up or updating the skill directory structure with optional scripts, assets, or references folders.
- Ensuring compliance with agentskills.io specifications and local quirks (like the `jq` portability rule).

## When Not to Use

- Creating standalone helper tools that aren't wrapped as skills.

## Inputs

| Input          | Required    | Description                                                                       |
|----------------|-------------|-----------------------------------------------------------------------------------|
| Skill name     | Yes         | Lowercase, alphanumeric, hyphens only (e.g., `crush-config`, `keep-a-changelog`). |
| Update type    | Yes         | Whether this is a new skill creation, a major update, a minor update, or a patch. |
| Description    | Optional    | What the skill does and when agents should use it (1-1024 chars).                 |
| Purpose        | Optional    | One paragraph describing the outcome of using the skill.                          |
| Workflow steps | Optional    | Numbered steps the agent should follow.                                           |

## Workflow

### Step 1: Detect Mode (Create vs. Edit)

Check if the folder `skills/<skill-name>/` and the file `skills/<skill-name>/SKILL.md` already exist:
- **If they do not exist**: Proceed with **Mode: Create** (Steps 2, 3, 4, 5, 6, 8).
- **If they exist**: Proceed with **Mode: Edit/Update** (Steps 4, 5, 7, 8).

### Step 2: Validate the skill name (Create Mode Only)

Ensure the proposed skill name:
- Contains only lowercase letters, numbers, and hyphens (`a-z`, `0-9`, `-`).
- Does not start or end with a hyphen.
- Does not contain consecutive hyphens.
- Is between 1-64 characters.

### Step 3: Create the skill directory (Create Mode Only)

Create the directories required under `skills/`:

```
skills/<skill-name>/
```

### Step 4: Extract the "Why" (Cognitive-First Principle)

Before writing or updating the body content, understand the underlying rationale behind every step, constraint, or modification:
- **Do not accept assumptions as facts**: Ask the skill creator/user to explain *why* a particular instruction, sequence, tool, file update, or folder structure is used.
- **Leverage Interactive Tools**: If your platform provides interactive questioning tools, use them to present structured yes/no, single-choice, or free-text questions to the creator to gather precise requirements. Examples of platform-specific tools include:
  - **`question`** (in **Crush**)
  - **`AskUserQuestion`** (in **Claude Code** — see [Claude Code Tools Reference](https://code.claude.com/docs/en/tools-reference))
  - **`Ask User Tool`** (in **Gemini CLI** — see [Gemini CLI Tools](https://geminicli.com/docs/tools/ask-user/))
  - **`Question`** (in **Open Code** — see [Open Code Tools Reference](https://opencode.ai/docs/tools/#question))
- **Explain the "Why" in the text**: When writing or updating the workflow steps in `SKILL.md`, always explain the reasoning behind the constraints (e.g., instead of "You MUST use X," write "Use X because it avoids Y under Z conditions"). This helps future agents understand the theory of mind and adapt better when facing edge cases.

### Step 5: Add or Update body content sections

Include or update the following sections in `SKILL.md`:

1. **Purpose / Title**: High-level overview of the skill.
2. **When to Use**: Bullet list of appropriate scenarios.
3. **When Not to Use**: Boundaries and exclusions.
4. **Inputs**: Table of required and optional inputs.
5. **Workflow**: Numbered steps with clear instructions and code fences where relevant.
6. **Validation**: Checklist of success criteria.
7. **Common Pitfalls**: Table/list of potential issues and solutions.

### Step 6: Generate initial `SKILL.md` with frontmatter (Create Mode Only)

Create `skills/<skill-name>/SKILL.md` with the required YAML frontmatter, utilizing the repository-wide license and author details:

```yaml
---
name: <skill-name>
description: <description of what the skill does and when to use it>
license: Apache-2.0
metadata:
  author: Ivan De Marino (http://github.com/detro)
  version: 1.0.0
---
```

### Step 7: Manage Semantic Versioning (Edit Mode Only)

When updating an existing skill, you must manage its version number (`metadata.version` in the YAML frontmatter) appropriately:
1. Read the current version from the frontmatter of `skills/<skill-name>/SKILL.md` (e.g. `1.1.0`).
2. Analyze the nature of the change:
   - **Major**: Backwards-incompatible workflow changes, removing key parameters/inputs, or structural redesigns.
   - **Minor**: Adding new capabilities, steps, optional inputs, or sub-scripts while keeping the previous features intact.
   - **Patch**: Fixing typos, improving wording, updating descriptions, or minor bug fixes in associated scripts.
3. **Prompt the User**: Present the suggested bump (e.g., `1.1.1` for a patch, `1.2.0` for minor, `2.0.0` for major) to the user.
   - If interactive tools are available (like Crush's `question` tool), present a structured `single_choice` or `free_text` query asking them to confirm the suggested version or provide a custom override.
   - Update the `metadata.version` field in the frontmatter with the approved version.

### Step 8: Add optional directories or scripts (if needed)

If the skill requires companion assets or executable scripts:

```
skills/<skill-name>/
├── SKILL.md
├── scripts/       # Executable code/helper scripts (e.g., catwalk.sh)
├── references/    # Additional documentation loaded on demand
└── assets/        # Templates, mock files, images, or data files
```

*Note: Any scripts added should adhere to the rules outlined in AGENTS.md (e.g., no external network calls inside scripts, and strict `set -euo pipefail` bash configurations).*

### Step 9: Validate the skill

- Confirm frontmatter fields are valid.
- Ensure `SKILL.md` body is under 500 lines (move verbose references to the `references/` subdirectory if needed).
- Verify that file references use relative paths.
- Check that the skill name matches the directory name exactly.

## `SKILL.md` Template

Use this template when creating a new skill:

```markdown
---
name: <skill-name>
description: <1-1024 char description of what the skill does and when to use it>
license: Apache-2.0
metadata:
  author: Ivan De Marino (http://github.com/detro)
  version: 1.0.0
---

# <Skill Title>

<One paragraph describing the skill's purpose and outcome.>

## When to Use

- <Scenario 1>
- <Scenario 2>

## When Not to Use

- <Exclusion 1>
- <Exclusion 2>

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| <input-name> | Yes/No | <description> |

## Workflow

### Step 1: <Action>

<Instructions for this step>

### Step 2: <Action>

<Instructions for this step>

## Validation

- [ ] <Verification step 1>
- [ ] <Verification step 2>

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| <Problem> | <How to avoid or fix> |
```

## Validation Checklist

After creating or updating a skill, verify:

- [ ] Skill name matches directory name exactly.
- [ ] Skill name is lowercase with hyphens only.
- [ ] Description is non-empty and under 1024 characters.
- [ ] `SKILL.md` body is under 500 lines.
- [ ] Frontmatter contains the correct license (`Apache-2.0`) and author name.
- [ ] Instructions are specific and actionable.
- [ ] Workflow has numbered steps with clear checkpoints.
- [ ] Every non-trivial step or constraint explains *why* it is necessary, rather than just stating it.
- [ ] The agent's interactive tools (like `question`) were leveraged during scaffolding or updating to interview the creator.
- [ ] Semantic version was correctly bumped in YAML frontmatter for existing skills based on changes (Major, Minor, or Patch).
- [ ] No hardcoded tokens, secrets, or external URLs (unless generic/public API endpoints).

## Common Pitfalls

| Pitfall                                                                        | Solution                                                                                                                 |
|--------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------|
| Name contains uppercase letters                                                | Use only lowercase: `my-skill` not `My-Skill`.                                                                           |
| Description is vague                                                           | Include what it does AND when to use it.                                                                                 |
| Workflow is composed of purely rigid "MUST/SHOULD" imperatives without context | Explain the reasoning behind instructions. Give future agents the cognitive framework to adapt to edge cases.            |
| Making assumptions about complex or ambiguous requirements                     | Stop and ask the user. Use the `question` tool to gather structured inputs on design/workflow/versioning trade-offs.     |
| Forgetting to bump the version when updating an existing skill                 | Detect if the skill exists, assess change magnitude, suggest the SemVer bump, and update frontmatter accordingly.        |
| Hardcoded network calls in scripts                                             | Move networking to agent's native tools (e.g., `fetch` / `download`). scripts must only do computation/local transforms. |
| Non-portable `jq` commands                                                     | Avoid `--slurpfile` in scripts and instructions. Use `--argjson` with subshell input.                                    |

## References

- [Agent Skills Specification](https://agentskills.io/specification)
- [AGENTS.md](../../AGENTS.md)
