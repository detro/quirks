# Quirks

<small>_You might have skills, but I got quirks!_</small>

A personal collection of Agent Skills, based on the [agentskills.io](https://agentskills.io/) specs, and what I find useful.
If you are looking for a big collection, go [somewhere else](https://www.skills.sh/): this is instead _my set of agentic quirks_.

I try to keep them _agent-agnostic_ and _operating-system-agnostic_, but if they target a specific agent it will be evident.

## Available Skills

<!-- SKILLS_TABLE_START -->

| Skill | Version | Description |
| --- | --- | --- |
| [asdf-manager](skills/asdf-manager) | `1.2.0` | Manage project runtime dependencies, tool versions, and plugins using asdf-vm. Proposes asdf to resolve missing script runtimes (e.g. Python, Perl) and handle tool updates with strict security checks for custom plugins. |
| [crush-config-manage-models](skills/crush-config-manage-models) | `1.0.0` | Use when the user wants to update, refresh, or sync the model definitions in their Crush config (crush.json) for one or more providers from the upstream charmbracelet/catwalk definitions — including composite/reseller providers like Vertex AI or Bedrock that combine models from other providers (e.g. "update the models used by anthropic", "add to my vertexai all the gemini and anthropic models", or "update all the models I already use with the latest version"). |
| [dont-mind-me](skills/dont-mind-me) | `1.0.0` | Manages the creation and update of gitignore and other ignore files in repositories. It leverages templates from github/gitignore or other online sources, combines multiple technologies/IDEs, supports subdirectory-specific ignore files, and understands a wide range of famous ignore formats like .dockerignore, .npmignore, and more. |
| [ground-rules](skills/ground-rules) | `1.1.0` | Helps setup, view, and edit a global context or "ground rules" file for your AI agents (such as Crush, Claude Code, or Cursor), including configuring custom global context file paths and auto-detecting the executing agent. |
| [keep-a-changelog](skills/keep-a-changelog) | `2.2.0` | Manages the project's CHANGELOG.md following the detected or requested format (e.g., Keep a Changelog or HashiCorp/Terraform format). Bootstraps a new changelog, creates entries for new releases, or updates in-progress entries in-place based on git history. |
| [quirks-curator](skills/quirks-curator) | `1.1.0` | Scaffolds, edits, and curates agent skills (quirks) for the Quirks repository conforming to the agentskills.io specification. Use when creating a new skill, updating an existing skill, generating or modifying SKILL.md files, managing semantic versions, or setting up skill directory structures. Handles frontmatter generation, version bumping, section templates, and validation. |
| [rfc-adr-curator](skills/rfc-adr-curator) | `1.0.0` | Manages the lifecycle of architectural designs and feature proposals from inception (RFC), through implementation tracking, to permanent archival as Architecture Decision Records (ADRs). Helps agents review proposals against historical context, decompose approved designs into actionable tickets, and distill chaotic comment threads into clean, immutable ADRs. |

<!-- SKILLS_TABLE_END -->

## Install

I recommend installing skills under `~/.agents/skills/`: most Agents look into this location.

```shell
# Via `npx`  (works with Claude Code, Cursor, Copilot, Codex, 40+ agents)
npx skills add https://github.com/detro/quirks

# Manually (via Task, recommended)
git clone https://github.com/detro/quirks.git
cd quirks && task install

# Manually (copy)
git clone https://github.com/detro/quirks.git
mkdir -p ~/.agents/skills
for skill in quirks/skills/*; do
  [ -d "$skill" ] && cp -r "$skill" ~/.agents/skills/
done

# Manually (symlink)
git clone https://github.com/detro/quirks.git
mkdir -p ~/.agents/skills
ln -sfn $(pwd)/quirks/skills/* ~/.agents/skills/
```

## Development

A repository like this one doesn't really have a "development loop". But when making changes or adding a new
skill, an obvious next step is to _install_ them.

To do such thing I provide the following commands:
- `task install`: Deletes and copies (replaces) this repository's skill directories into the `~/.agents/skills/` folder, preserving any other external skill directories.
- `task list`: Generates a Markdown table rendered with `glow` listing all skills in the repository, their repo version, installed version, and whether they are up-to-date or out-of-sync.

I recommend using [asdf](https://asdf-vm.com/) to install the [tools used in this repository](.tool-versions).

## License

[Apache 2.0](./LICENSE)
