# Quirks

<small>_You might have skills, but I got quirks!_</small>

A personal collection of Agent Skills, based on the [agentskills.io](https://agentskills.io/) specs, and what I find useful.
If you are looking for a big collection, go [somewhere else](https://www.skills.sh/): this is instead _my set of agentic quirks_.

I try to keep them _agent-agnostic_ and _operating-system-agnostic_, but if they target a specific agent it will be evident.

## Install

```shell
# Via `npx`  (works with Claude Code, Cursor, Copilot, Codex, 40+ agents)
npx skills add https://github.com/detro/quirks

# Manually
git clone https://github.com/detro/quirks.git
ln -s $(pwd)/quirks/skills/* ~/.agents/skills/
```

## Development

A repository like this one doesn't really have a "development loop". But when making changes or adding a new
skill, an obvious next step is to _install_ them.

To do such thing I provide a `task install` command that will install all the "quirks"
in the `~/.agents/skills/` directory.

I recommend using [asdf](https://asdf-vm.com/) to install the [tools used in this repository](.tool-versions).

## License

[Apache 2.0](./LICENSE)
