#!/usr/bin/env bash
# Claude Code status line: repo, forge, branch, git status, context gradient,
# cost, code velocity, model. Palette: catppuccin mocha (lavender accent).
# Wired up in llm.nix as programs.claude-code.settings.statusLine.

export LC_ALL=C  # locale uses comma decimals; printf %.2f/%.0f need dots

input=$(cat)

# ── Truecolor helper ──
rgb() { printf '\033[38;2;%d;%d;%dm' "$1" "$2" "$3"; }

# ── Colors: catppuccin mocha ──
LAVENDER=$(rgb 180 190 254)
MAUVE=$(rgb 203 166 247)
BLUE=$(rgb 137 180 250)
GREEN=$(rgb 166 227 161)
RED=$(rgb 243 139 168)
SURFACE2=$(rgb 88 91 112)
DIM=$(rgb 108 112 134)
BOLD='\033[1m'
RESET='\033[0m'

# ── Parse JSON fields ──
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
lines_add=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_del=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')

# ── Git info ──
branch=""
repo=""
forge=""
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  repo=$(basename "$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null)

  # Forge icon from the origin remote (nerd font glyphs).
  remote=$(git -C "$cwd" --no-optional-locks remote get-url origin 2>/dev/null)
  case "$remote" in
    *github.com*)                 forge=$'' ;;  # github
    *gitlab*)                     forge=$'' ;;  # gitlab
    *bitbucket*)                  forge=$'' ;;  # bitbucket
    *forgejo*|*gitea*|*codeberg*) forge=$'' ;;  # forgejo/gitea
    ?*)                           forge=$'' ;;  # generic git remote
  esac

  # Git status classifier, tide-style: conflicted / staged / dirty / untracked.
  if [ -n "$repo" ]; then
    eval "$(git -C "$cwd" --no-optional-locks status --porcelain=v1 2>/dev/null | awk '
      /^\?\?/                   { u++; next }
      /^(DD|AU|UD|UA|DU|AA|UU)/ { c++; next }
      {
        if (substr($0,1,1) != " ") s++
        if (substr($0,2,1) != " ") d++
      }
      END { printf "st_staged=%d st_dirty=%d st_untracked=%d st_conflict=%d", s, d, u, c }
    ')"
    st_stash=$(git -C "$cwd" --no-optional-locks stash list 2>/dev/null | wc -l)
    # Commits behind/ahead of upstream; empty when there is no tracking branch.
    read -r st_behind st_ahead <<<"$(git -C "$cwd" --no-optional-locks rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null)"
  fi
fi

# ── Git status classifier (colors mirror the tide_git_color_* fish vars) ──
gitstat=""
[ "${st_conflict:-0}"  -gt 0 ] && gitstat="${gitstat}$(rgb 243 139 168)~${st_conflict}${RESET}"
[ "${st_staged:-0}"    -gt 0 ] && gitstat="${gitstat}$(rgb 249 226 175)+${st_staged}${RESET}"
[ "${st_dirty:-0}"     -gt 0 ] && gitstat="${gitstat}$(rgb 249 226 175)!${st_dirty}${RESET}"
[ "${st_untracked:-0}" -gt 0 ] && gitstat="${gitstat}$(rgb 137 220 235)?${st_untracked}${RESET}"
[ "${st_stash:-0}"     -gt 0 ] && gitstat="${gitstat}$(rgb 166 227 161)*${st_stash}${RESET}"
[ "${st_ahead:-0}"     -gt 0 ] && gitstat="${gitstat}$(rgb 137 180 250)⇡${st_ahead}${RESET}"
[ "${st_behind:-0}"    -gt 0 ] && gitstat="${gitstat}$(rgb 137 180 250)⇣${st_behind}${RESET}"

# ── Context bar: lavender → mauve → red gradient, full blocks only ──
BAR_WIDTH=20

if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")

  # Round to nearest block
  filled=$(( (used_int * BAR_WIDTH + 50) / 100 ))

  bar=""
  for (( i=0; i<BAR_WIDTH; i++ )); do
    pos=$(( i * 100 / (BAR_WIDTH - 1) ))

    if [ "$pos" -le 50 ]; then
      # lavender (180,190,254) → mauve (203,166,247)
      r=$(( 180 + 23 * pos / 50 ))
      g=$(( 190 - 24 * pos / 50 ))
      b=$(( 254 - 7 * pos / 50 ))
    else
      # mauve (203,166,247) → red (243,139,168)
      adj=$(( pos - 50 ))
      r=$(( 203 + 40 * adj / 50 ))
      g=$(( 166 - 27 * adj / 50 ))
      b=$(( 247 - 79 * adj / 50 ))
    fi

    if [ "$i" -lt "$filled" ]; then
      bar="${bar}$(rgb $r $g $b)█"
    else
      bar="${bar}${SURFACE2}░"
    fi
  done
  bar="${bar}${RESET}"

  if [ "$used_int" -ge 90 ]; then pct_color="$RED"
  elif [ "$used_int" -ge 70 ]; then pct_color="$MAUVE"
  else pct_color="$LAVENDER"; fi

  ctx_part="${bar} ${pct_color}${used_int}%${RESET}"
else
  ctx_part="${SURFACE2}░░░░░░░░░░░░░░░░░░░░${RESET} --%"
fi

# ── Cost ──
cost_part="${MAUVE}$(printf '$%.2f' "$cost")${RESET}"

# ── Code velocity ──
velocity="${GREEN}+${lines_add}${RESET} ${RED}-${lines_del}${RESET}"

# ── Single line ──
out=""
[ -n "$repo" ] && out="${BOLD}${LAVENDER}${repo}${RESET}"
[ -n "$forge" ] && out="${out:+$out }${MAUVE}${forge}${RESET}"
[ -n "$branch" ] && out="${out:+$out }${BOLD}${BLUE}(${branch})${RESET}"
[ -n "$gitstat" ] && out="${out:+$out }${gitstat}"
out="${out:+$out ${DIM}|${RESET} }${ctx_part}"
out="${out} ${DIM}|${RESET} ${cost_part}"
out="${out} ${DIM}|${RESET} ${velocity}"
out="${out} ${DIM}|${RESET} ${LAVENDER}${model}${RESET}"

printf '%b' "$out"
