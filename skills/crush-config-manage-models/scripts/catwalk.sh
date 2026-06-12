#!/usr/bin/env bash
#
# catwalk.sh — pure-jq transformer for the crush-agent-refresh-models skill.
#
# This script does NOT touch the network. The agent fetches the catwalk
# provider JSON files itself using Crush's built-in `fetch`/`download` tool
# from:
#   https://raw.githubusercontent.com/charmbracelet/catwalk/main/internal/providers/configs/<provider>.json
# and saves each one to a local file. This script then composes, deduplicates,
# merges and applies those files. Its only dependency is `jq`.
#
# Why a script at all: the compose/dedup/merge math is fiddly to do by hand and
# easy to get subtly wrong (ordering, last-write-wins, retired-model removal).
# Keeping it in one tested place makes the result deterministic. All file I/O is
# done with Crush's own tools by the agent; this is just the JSON engine.
#
# Requirements: bash + jq. No gh, no curl, no network.
#
# Subcommands (all read local files, all print to stdout):
#
#   models <provider.json>
#       Print just the `.models` array of a single fetched provider file.
#
#   meta <provider.json>
#       Print the provider object without its `.models` array (metadata:
#       id, name, type, default_large_model_id, ...). Use to read the
#       provider `type` (e.g. google-vertex, bedrock) and defaults.
#
#   compose <base.json> <src.json> [<src.json> ...]
#       Print a single JSON array of models composed as:
#         start from <base>'s models, then add each <src>'s models in order,
#         deduplicating by `.id`. SOURCES WIN on conflicts (a later file wins),
#         so <src> overrides <base> and a later <src> overrides an earlier one.
#         First-seen ORDER is preserved (base ids first, then new src ids).
#       This matches the skill rule: "to the vertexai list, add gemini+anthropic,
#       dedup, sources win". For a single provider verbatim, use `models`.
#
#   merge <current-models.json> <new-models.json>
#       <current-models.json> = the provider's CURRENT models array from
#       crush.json. <new-models.json> = the freshly composed/desired array.
#       Prints the merged array per the skill's rules:
#         - upstream definition wins (local customizations discarded);
#         - models present upstream are kept/updated;
#         - models NOT present upstream are removed (retired);
#         - order follows the new/desired array.
#       The merged result is the new array; a human-readable summary of
#       added/removed/kept ids is printed to STDERR for the agent to relay.
#
#   apply <crush.json> <provider> <models.json>
#       Set .providers.<provider>.models to the contents of <models.json> in
#       <crush.json> and print the resulting FULL document on stdout. Does NOT
#       write in place — the agent reviews the diff and writes the file with
#       Crush's own edit/write tools. Preserves every other part of the
#       document. Uses only portable jq (no --slurpfile).
#
# Exit codes: non-zero on any missing-file or parse error.

set -euo pipefail

die() { echo "catwalk.sh: $*" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || die "jq is required but not found on PATH"

# require_json <file> — fail unless <file> exists and is valid JSON
require_json() {
  local f="$1"
  [ -f "$f" ] || die "file not found: $f"
  jq -e . "$f" >/dev/null 2>&1 || die "not valid JSON: $f"
}

# models_of <provider-or-models-file> — print a models ARRAY from a file that is
# either a full provider object ({...,"models":[...]}) or already a bare array.
models_of() {
  local f="$1"
  require_json "$f"
  jq 'if type=="array" then . else (.models // []) end' "$f"
}

cmd_models() {
  [ "$#" -eq 1 ] || die "usage: catwalk.sh models <provider.json>"
  models_of "$1"
}

cmd_meta() {
  [ "$#" -eq 1 ] || die "usage: catwalk.sh meta <provider.json>"
  require_json "$1"
  jq 'del(.models)' "$1"
}

cmd_compose() {
  [ "$#" -ge 2 ] || die "usage: catwalk.sh compose <base.json> <src.json> [<src.json> ...]"
  local base="$1"; shift
  local combined
  combined="$(models_of "$base")"
  local src add
  for src in "$@"; do
    add="$(models_of "$src")"
    # Append src models to the running list, then dedup by .id:
    #   - keep first-seen ORDER (base order first, then new src ids), and
    #   - keep the LAST value for a given id (so src wins over base, and a
    #     later src wins over an earlier one).
    combined="$(jq -n --argjson a "$combined" --argjson b "$add" '
      ($a + $b) as $all
      | ($all | reduce .[] as $m ({}; .[$m.id] = $m)) as $byid
      | ($all | reduce .[] as $m ([]; if (index($m.id) != null) then . else . + [$m.id] end)) as $order
      | [ $order[] as $id | $byid[$id] ]
    ')"
  done
  echo "$combined" | jq '.'
}

cmd_merge() {
  [ "$#" -eq 2 ] || die "usage: catwalk.sh merge <current-models.json> <new-models.json>"
  local cur new
  cur="$(models_of "$1")"
  new="$(models_of "$2")"

  # Summary of the diff (to stderr) so the agent can describe it.
  # De-duplicate id lists so duplicate ids in the current config don't skew comm(1).
  local cur_ids new_ids
  cur_ids="$(jq -rn --argjson c "$cur" '[$c[].id] | unique | .[]')"
  new_ids="$(jq -rn --argjson n "$new" '[$n[].id] | unique | .[]')"

  {
    echo "=== merge summary ==="
    echo "-- added (in upstream, not in current):"
    comm -13 <(printf '%s\n' "$cur_ids") <(printf '%s\n' "$new_ids") | sed 's/^/   + /'
    echo "-- removed (retired upstream, present in current):"
    comm -23 <(printf '%s\n' "$cur_ids") <(printf '%s\n' "$new_ids") | sed 's/^/   - /'
    echo "-- kept/updated (present in both; upstream definition wins):"
    comm -12 <(printf '%s\n' "$cur_ids") <(printf '%s\n' "$new_ids") | sed 's/^/   ~ /'
    echo "====================="
  } >&2

  # Merged result: upstream wins entirely => the new array is authoritative.
  echo "$new" | jq '.'
}

cmd_apply() {
  [ "$#" -eq 3 ] || die "usage: catwalk.sh apply <crush.json> <provider> <models.json>"
  local cfg="$1" provider="$2" models="$3"
  require_json "$cfg"
  local arr
  arr="$(models_of "$models")"
  # Portable across jq versions (no --slurpfile): pass the array via --argjson.
  jq --arg p "$provider" --argjson m "$arr" '.providers[$p].models = $m' "$cfg"
}

main() {
  [ "$#" -ge 1 ] || die "usage: catwalk.sh {models|meta|compose|merge|apply} ..."
  local sub="$1"; shift
  case "$sub" in
    models)  cmd_models "$@" ;;
    meta)    cmd_meta "$@" ;;
    compose) cmd_compose "$@" ;;
    merge)   cmd_merge "$@" ;;
    apply)   cmd_apply "$@" ;;
    *) die "unknown subcommand '$sub' (expected models|meta|compose|merge|apply)" ;;
  esac
}

main "$@"
