#!/usr/bin/env bash
set -uo pipefail
cd -- "$(dirname -- "$0")/.." || exit 1
if [ "$#" -eq 0 ]; then
    while IFS= read -r -d '' file; do
        set -- "$@" "$file"
    done < <(find . -type d -name '.*' ! -name . -prune -o -type f -name '*.md' -print0)
fi
if [ "$#" -eq 0 ]; then
    printf 'No Markdown files found\n' >&2
    exit 1
fi
status=0
for f in "$@"; do
    prose=$(awk '/^[[:space:]]*```/{c=!c; next} !c' "$f" | sed -E 's/`[^`]*`//g') || { status=1; continue; }
    hits=$(printf '%s\n' "$prose" | grep -n -E '—|–| -- ')
    [ -n "$hits" ] && { printf '%s: dash\n%s\n' "$f" "$hits"; status=1; }
    hits=$(printf '%s\n' "$prose" | grep -n '’')
    [ -n "$hits" ] && { printf '%s: curly apostrophe\n%s\n' "$f" "$hits"; status=1; }
    hits=$(printf '%s\n' "$prose" | grep -n -E '(^|[.!?]\s+|^\s*([-*]|[0-9]+\.)\s+|\|\s*)(\*\*)?[A-Z][A-Za-z ]{0,25}(\*\*)?:(\s|$)')
    [ -n "$hits" ] && { printf '%s: label colon\n%s\n' "$f" "$hits"; status=1; }
    hits=$(printf '%s\n' "$prose" | grep -n -i -w -E 'delve|robust|comprehensive|leverage|seamless(ly)?|crucial|pivotal|utilize|furthermore|moreover|additionally|notably|landscape|ecosystem|meticulous(ly)?|underscores?|showcas(e|ing)|tapestry|realm|paradigm|holistic|actionable|impactful|learnings|facilitate[sd]?|streamline|empower|foster|navigate|nuanced|myriad|plethora|paramount|overarching|in order to|serves as|it.s worth noting|that said|at its core')
    [ -n "$hits" ] && { printf '%s: ai words\n%s\n' "$f" "$hits"; status=1; }
done
exit "$status"
