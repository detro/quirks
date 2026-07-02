# Quirks

<small>_You might have skills, but I got quirks!_</small>

A personal collection of Agent Skills, based on the [agentskills.io](https://agentskills.io/) specs, and what I find useful.
If you are looking for a big collection, go [somewhere else](https://www.skills.sh/): this is instead _my set of agentic quirks_.

I try to keep them _agent-agnostic_ and _operating-system-agnostic_, but if they target a specific agent it will be evident.

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
