---
name: crush-agent-refresh-models
description: Use when the user wants to update, refresh, or sync the model definitions in their Crush config (crush.json) for one or more providers from the upstream charmbracelet/catwalk definitions — including composite/reseller providers like Vertex AI or Bedrock that combine models from other providers (e.g. "update the models used by anthropic", "add to my vertexai all the gemini and anthropic models", or "update all the models I already use with the latest version").
license: Apache-2.0
metadata:
  author: Ivan De Marino (http://github.com/detro)
  version: 1.0.0
---

# Refresh Crush Models

> Authored and maintained by **Ivan De Marino**.
>
> **Scope:** This skill is specific to the **Crush** coding agent
> ([`charmbracelet/crush`](https://github.com/charmbracelet/crush)) and its
> `crush.json` configuration file. It is not applicable to other agents or
> config formats.

This skill updates the per-provider `models` arrays inside the user's Crush
configuration (`crush.json`) using the authoritative model definitions published
on the **`main`** branch of
[`charmbracelet/catwalk`](https://github.com/charmbracelet/catwalk/tree/main/internal/providers/configs)
(the model catalog used by [`charmbracelet/crush`](https://github.com/charmbracelet/crush)).

Each catwalk provider is a JSON file at
`internal/providers/configs/<provider>.json` whose `models` array uses the **same
object schema** Crush expects (`id`, `name`, `cost_per_1m_in`,
`cost_per_1m_out`, `cost_per_1m_in_cached`, `cost_per_1m_out_cached`,
`context_window`, `default_max_tokens`, `can_reason`, `reasoning_levels`,
`default_reasoning_effort`, `supports_attachments`, ...). No field translation is
needed — catwalk model objects drop straight into Crush.

### How the work is split

- **Fetching is done by YOU (the agent) with Crush's built-in `fetch` /
  `download` tool** — not by the script and not with `gh`/`curl`. Each provider
  file is fetched from its raw URL:
  ```
  https://raw.githubusercontent.com/charmbracelet/catwalk/main/internal/providers/configs/<provider>.json
  ```
  Save each fetched file locally (e.g. `download` it to `/tmp/catwalk/<provider>.json`,
  or `fetch` it and write the body to a file).
- **All JSON math (compose / dedup / merge / apply) is done by the helper
  script**, which reads those local files and never touches the network:
  ```
  scripts/catwalk.sh {models|meta|compose|merge|apply} <file> ...
  ```
- **Editing `crush.json` is done by YOU** with Crush's `view`/`edit`/`write`
  tools, after showing the diff.

The **only external dependency is `jq`** (used by the script; the builtin `jq`
skill documents it). No `gh`, no `curl`, no network access in the script.

### Listing available providers

There is no `list` subcommand (it would need network). If you need to discover
the full provider set, `fetch` the directory listing page
<https://github.com/charmbracelet/catwalk/tree/main/internal/providers/configs>
(or its API form) and read the file names. For a named provider you already
know, just fetch its raw `<provider>.json` directly — no listing needed.

## Core rules (do not deviate)

1. **Source of truth is catwalk `main`.** Always fetch fresh; never rely on
   memorized model lists.
2. **Upstream wins.** When refreshing, the catwalk definition fully replaces the
   user's existing entry for a given model id. Local customizations (custom
   cost, renamed `name`, tweaked `context_window`, etc.) are **discarded** — they
   are assumed to be staler than catwalk.
3. **Retired models are removed.** If a model id the user currently has is no
   longer present in the (composed) upstream set, drop it.
4. **Composite / reseller providers compose from source files.** Providers like
   `vertexai` (Google Vertex AI), `bedrock-*` (AWS Bedrock), `azure`, etc. resell
   models that originate from other providers (Gemini, Anthropic, OpenAI, ...).
   For these, build the model list by composing:
   - start from the reseller's own catwalk file (e.g. `vertexai.json`), then
   - add the requested source providers' models (e.g. `gemini` + `anthropic`),
   - **deduplicate by `id`, and the SOURCE providers WIN** over the reseller's
     base entry on conflict. Rationale: when the user asks to pull from
     gemini/anthropic directly, they know those files are more up to date than
     the reseller's curated copy.
   The helper `compose <base.json> <src.json>...` implements exactly this (base
   first, sources override, first-seen order preserved).
5. **Show the diff, then edit.** Present the added / removed / updated model ids
   (the `merge` subcommand prints this summary), then edit `crush.json` with
   Crush's own edit tools. **No backup file.** This is ordinary file editing.
6. **Only touch the targeted provider(s).** Never reorder, reformat, or modify
   other parts of `crush.json` (lsp, permissions, other providers, etc.).
   Preserve the file's existing indentation/style.

## Locating crush.json

Resolve the active Crush config path the same way Crush documents it
(<https://github.com/charmbracelet/crush#configuration>). Check, in order, and
use the first that exists:

1. `$CRUSH_CONFIG` / an explicit path the user gives.
2. **Project-local**: `./crush.json` or `./.crush.json` in the working dir.
3. **Global**, by OS:
   - macOS / Linux: `$XDG_CONFIG_HOME/crush/crush.json`, else
     `~/.config/crush/crush.json`.
   - Windows: `%USERPROFILE%\AppData\Local\crush\crush.json` (i.e.
     `$LOCALAPPDATA/crush/crush.json`).

If both a project-local and a global config exist, **ask** which to update unless
the user already made it clear. Read the file before editing it.

## Determining the request mode

### Mode 1 — Explicit single provider

> "update the models used by anthropic" / "refresh gemini models"

The provider maps directly to one catwalk file.

1. Fetch `…/configs/<provider>.json` (Crush `fetch`/`download`) to a local file.
2. `scripts/catwalk.sh models <provider>.json` → the desired model array.
3. Continue at **Apply the update**.

### Mode 2 — Explicit composition (reseller + named sources)

> "add to my vertexai all the gemini and anthropic models"

1. Fetch the reseller and each source file locally (e.g. `vertexai.json`,
   `gemini.json`, `anthropic.json`).
2. `scripts/catwalk.sh compose <reseller>.json <src1>.json <src2>.json ...`
   → desired model array.
   - Base = the reseller; sources = the named providers; sources win on dedup.
3. Continue at **Apply the update**.

### Mode 3 — Auto / minimal input

> "update all the models I already use, with the latest version"

Figure out, **per provider already present in `crush.json`**, what to fetch:

1. Read the user's `crush.json` and list every provider under `providers` that
   has a `models` array (or that you can refresh).
2. For each such provider, decide its catwalk sources, then fetch the needed
   `<provider>.json` file(s) locally:
   - If the provider name matches a catwalk file directly (e.g. `anthropic`,
     `gemini`, `openai`) and is **not** a known reseller → Mode-1 style: fetch
     that provider's file and take its models.
   - If it's a **reseller** (`vertexai`, `bedrock-*`, `azure`, ...) → infer the
     source providers from the **ids already configured**:
     - ids starting with `gemini` ⇒ source `gemini`
     - ids starting with `claude` ⇒ source `anthropic`
     - ids starting with `gpt`/`o1`/`o3`/`o4` ⇒ source `openai`
     - (extend by inspecting catwalk: a model id present in provider X's
       `models` identifies X as a source.)
     Fetch the reseller file plus each inferred source file, then
     `compose <reseller>.json <inferred-sources>.json ...` (superset, sources
     win) — do **not** silently fall back to only the reseller's curated file;
     the user-confirmed behavior is the composed superset.
   - Use `scripts/catwalk.sh meta <provider>.json` and `models <provider>.json`
     to confirm a provider's `type` and ids when inferring sources.
3. Apply the update for each provider (below). Summarize all providers touched.

If inference is genuinely ambiguous for a reseller (e.g. ids you can't map to a
known source), state what you found and ask which source providers to use rather
than guessing.

## Filtering / narrowing the model set (optional)

The user may want only a SUBSET of the composed/desired models, e.g.:

> "only include opus and sonnet versions 4.6 and higher"
> "only include the latest version of each model variant"
> "drop the preview models" / "gemini flash only"

Apply the filter **with jq on the composed/desired array** (the `/tmp/new.json`
produced by `models`/`compose`) **before** running `merge`. The script does no
filtering; you express the user's intent as a jq pipeline. Keep the result a
plain models array so `merge`/`apply` keep working unchanged.

The catwalk model objects carry useful fields for filtering: `id`, `name`,
`context_window`, `can_reason`, `supports_attachments`, cost fields, etc. Model
ids encode the variant and version (e.g. `claude-opus-4-8`,
`claude-sonnet-4-5-20250929`, `gemini-3.5-flash`, `gemini-3-flash-preview`).

### A. Explicit variant + version-floor filters

> "only opus and sonnet, 4.6 and higher"

Parse a comparable numeric version out of each id, then keep matching variants
at or above the floor. Example (Anthropic-style `claude-<variant>-<maj>-<min>…`):

```bash
jq '
  [ .[]
    | . as $m
    | ($m.id | capture("claude-(?<variant>opus|sonnet|haiku)-(?<maj>[0-9]+)-(?<min>[0-9]+)") ) as $v
    | select($v != null)
    | select($v.variant | IN("opus","sonnet"))
    | select((($v.maj|tonumber) > 4) or
             (($v.maj|tonumber) == 4 and ($v.min|tonumber) >= 6))
    | $m
  ]
' /tmp/new.json > /tmp/filtered.json
```

Adjust the regex/floor to the provider's id scheme and the user's request (e.g.
`gemini-(?<maj>[0-9]+)\\.?(?<min>[0-9]*)`). State the floor and variants you
applied so the user can confirm.

> **Pitfall:** ids that append a release date (e.g.
> `claude-opus-4-20250514`) put the date where a minor version is expected, so a
> naive `min >= 6` test will wrongly admit `…-4-20250514` (min "parsed" as a
> huge date number). Inspect ids first (`jq -r '.[].id' /tmp/new.json`) and make
> the regex distinguish a real minor (`-4-6`) from a date (`-4-YYYYMMDD`) — e.g.
> require the version segment to be 1–2 digits, and treat dated ids separately.

### B. "Latest version of each variant only"

> "only the latest opus, latest sonnet, latest gemini-flash, etc."

Group ids by their **variant key** (the id with the version/date segments
stripped), then keep the single highest-versioned id per group. Derive a
sortable version key from the id (numeric version tuples and any trailing date
`YYYYMMDD` both compare correctly as zero-padded/lexible tuples). Example:

```bash
jq '
  def variant_key: (sub("-[0-9].*$";""));        # e.g. claude-opus, gemini-flash
  def version_key:
        [ (scan("[0-9]+") | tonumber) ];          # numeric segments as a sortable list
  [ .[] ]
  | group_by(.id | variant_key)
  | map( max_by(.id | version_key) )
' /tmp/new.json > /tmp/filtered.json
```

Tune `variant_key` so it separates the variants the user means (for Gemini you
may want `pro` vs `flash` to stay distinct, and preview vs GA — inspect the ids
first with `jq -r ".[].id" /tmp/new.json`). If "latest" is ambiguous between a
dated GA release and a `-preview`, prefer GA unless the user says otherwise, and
say which you picked.

> **Pitfall:** the simple `variant_key`/`version_key` above are only a starting
> point. `sub("-[0-9].*$";"")` groups `gemini-3-pro-preview` and
> `gemini-3-flash-preview` separately (good) but won't split `pro` from
> `flash` if the family number comes last, and a `version_key` built from all
> numeric runs ranks a trailing date (`…-20250514`) above a plain `-4-8`. Verify
> the chosen winner per group against the printed id list, and refine the keys
> (e.g. include the variant word, or weight version vs date) until each group's
> "latest" is the one the user expects.

### After filtering

Use `/tmp/filtered.json` in place of `/tmp/new.json` from step 2 of **Apply the
update** onward (`merge /tmp/cur.json /tmp/filtered.json …`). The merge summary
and final recap then reflect exactly the narrowed set, and any of the user's
existing ids that fall outside the filter are correctly reported as removed.

If a filter would yield an empty set, or you can't confidently parse the ids for
the requested rule, show the candidate ids and ask rather than guessing.

## Apply the update

For each provider being updated:

1. Write the provider's **current** models array to a temp file (use Crush's
   tools, or jq): `jq '.providers.<provider>.models // []' <crush.json> > /tmp/cur.json`
2. Write the **desired** array (from the `models` or `compose` subcommand, run
   on the locally fetched catwalk files) to a temp file: `... > /tmp/new.json`
3. `scripts/catwalk.sh merge /tmp/cur.json /tmp/new.json > /tmp/merged.json`
   - The merge summary (added `+` / removed `-` / kept-updated `~`) is printed to
     **stderr** — relay it to the user as the diff.
   - `/tmp/merged.json` is the authoritative merged array (upstream wins,
     retired removed).
4. **Present the diff** to the user (the summary). Then set
   `providers.<provider>.models` to the merged array. Use the `apply`
   subcommand, which preserves the rest of the document and works on any jq
   version:
   ```bash
   scripts/catwalk.sh apply <crush.json> <provider> /tmp/merged.json > /tmp/out.json
   ```
   Verify the change is scoped to that provider's models before saving:
   ```bash
   diff <(jq 'del(.providers.<provider>.models)' <crush.json) \
        <(jq 'del(.providers.<provider>.models)' /tmp/out.json)   # must be empty
   ```
   then write `/tmp/out.json` back over `crush.json` using Crush's `write`/`edit`
   tool. If you instead hand-edit `crush.json` directly, match the file's
   existing indentation exactly and change only that provider's `models` block.
5. If the provider didn't previously exist in `providers`, create the minimal
   block (`"<provider>": { "models": [...] }`) — but only if the user asked to
   add it; otherwise stick to providers already configured.

## Final recap (always)

After all targeted providers have been written back, **end with a recap of the
final model list** so the user can see the end state at a glance. For each
provider you touched, read the saved `crush.json` and list the model ids now
present (e.g. `jq -r '.providers.<provider>.models[].id' crush.json`). Present,
per provider:

- the **complete final list** of model ids now configured (the recap), and
- the counts / change summary (added, removed, kept-updated) for context.

This recap is mandatory and comes in addition to the pre-write diff from step 4.

## Notes & gotchas

- **API keys / endpoints / defaults are not touched.** This skill only manages
  `models`. Leave `api_key`, `api_endpoint`, `default_large_model_id`, etc. as
  the user has them. (catwalk's `meta` carries upstream defaults if the user asks
  to also refresh those, but do it only on explicit request.)
- **Reseller list isn't hard-coded in catwalk by name** — identify resellers by
  their `type` (`google-vertex`, `bedrock`, `azure`, `openrouter`, `vercel`,
  `openai-compat`) and by the fact that their models originate elsewhere. Use
  `scripts/catwalk.sh meta <provider>.json` to read `type`.
- **Duplicate ids in the user's existing config** are harmless to the merge (it
  dedups), and collapsing them to a single canonical entry is desirable.
- **Validate JSON** after editing (`jq . crush.json`), and if the repo/dir is a
  git checkout, show `git diff` of `crush.json` so the change is reviewable.
- **Only `jq` is required.** Fetching uses Crush's `fetch`/`download` tool;
  editing uses Crush's `edit`/`write` tools. No `gh` or `curl` is needed.

## Quick reference

Fetch first (Crush `fetch`/`download`), saving to local files, then:

```bash
S=~/.config/agents/skills/crush-agent-refresh-models/scripts/catwalk.sh

# (agent fetched these to /tmp/catwalk/<provider>.json beforehand)
"$S" meta    /tmp/catwalk/vertexai.json            # provider metadata incl. type
"$S" models  /tmp/catwalk/anthropic.json           # one provider's models array
"$S" compose /tmp/catwalk/vertexai.json \
             /tmp/catwalk/gemini.json \
             /tmp/catwalk/anthropic.json           # reseller + sources, sources win
"$S" merge   /tmp/cur.json /tmp/new.json           # merged array + diff summary(stderr)
"$S" apply   crush.json vertexai /tmp/merged.json  # full doc w/ models replaced
```
