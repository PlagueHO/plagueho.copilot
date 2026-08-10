#!/usr/bin/env bash
# Scan-Dotfiles — Scans a directory tree for common dotfile candidates.
#
# Usage:
#   ./scan-dotfiles.sh [path] [--json] [--include-vscode]
#
# Arguments:
#   path            Root directory to scan (default: $HOME)
#   --json          Output in JSON format instead of human-readable table
#   --include-vscode  Also scan for VS Code settings
#
# Searches for known dotfiles and configuration files grouped by category.
# SSH private keys are explicitly excluded for security.

set -euo pipefail

SCAN_PATH="${HOME}"
OUTPUT_JSON=false
INCLUDE_VSCODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) OUTPUT_JSON=true; shift ;;
    --include-vscode) INCLUDE_VSCODE=true; shift ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) SCAN_PATH="$1"; shift ;;
  esac
done

if [[ ! -d "$SCAN_PATH" ]]; then
  echo "Error: Path '$SCAN_PATH' does not exist." >&2
  exit 1
fi

# Results stored as lines: "category|file|fullpath|size_kb|warning|recommended"
RESULTS=()

check_file() {
  local category="$1" file="$2"
  local fullpath="${SCAN_PATH}/${file}"

  if [[ -e "$fullpath" ]]; then
    local size_kb="0"
    local warning=""
    local recommended="true"

    if [[ -d "$fullpath" ]]; then
      size_kb="dir"
    else
      size_kb=$(du -k "$fullpath" 2>/dev/null | cut -f1)

      # Skip files over 100 KB
      if [[ "$size_kb" -gt 100 ]]; then
        warning="File is ${size_kb}KB — exceeds 100KB limit, will be skipped"
        recommended="false"
      fi

      # Check for potential secrets (only for files < 100KB)
      if [[ "$size_kb" -le 100 ]] && [[ -f "$fullpath" ]]; then
        local content
        content=$(cat "$fullpath" 2>/dev/null || true)
        if echo "$content" | grep -qiE '(ghp_|sk-|AKIA|xox-|bearer |password\s*=|token\s*=)'; then
          warning="Potential secret or token detected — review before including"
          recommended="false"
        elif echo "$content" | grep -qE '(/home/[a-zA-Z0-9_]+|/Users/[a-zA-Z0-9_]+|C:\\Users\\)'; then
          if [[ -z "$warning" ]]; then
            warning="Contains hardcoded user paths — recommend sanitization"
          fi
        fi
      fi
    fi

    RESULTS+=("${category}|${file}|${fullpath}|${size_kb}|${warning}|${recommended}")
  fi
}

# Shell
for f in .bashrc .bash_profile .bash_logout .zshrc .zprofile .zshenv .zlogout \
         .profile .aliases .functions .inputrc .hushlogin .exports; do
  check_file "Shell" "$f"
done

# Git
for f in .gitconfig .gitignore_global .gitattributes .gitmessage .gittemplate; do
  check_file "Git" "$f"
done

# Editor
for f in .vimrc .editorconfig .nanorc .emacs; do
  check_file "Editor" "$f"
done

# SSH (config only — never keys)
check_file "SSH" ".ssh/config"
if [[ -d "${SCAN_PATH}/.ssh" ]]; then
  key_count=$(find "${SCAN_PATH}/.ssh" -maxdepth 1 \
    \( -name 'id_rsa' -o -name 'id_ed25519' -o -name 'id_ecdsa' -o -name 'id_dsa' \) \
    2>/dev/null | wc -l)
  if [[ "$key_count" -gt 0 ]]; then
    echo "Warning: SSH keys found in .ssh/ — only config will be included" >&2
  fi
fi

# Terminal
for f in .tmux.conf .screenrc .wezterm.lua .hyper.js .alacritty.yml .alacritty.toml; do
  check_file "Terminal" "$f"
done

# Package Managers
for f in Brewfile .npmrc .yarnrc .yarnrc.yml .gemrc pip.conf .pip/pip.conf .config/pip/pip.conf; do
  check_file "Package Managers" "$f"
done

# OS Preferences
for f in .macos .Xresources .xprofile .xinitrc; do
  check_file "OS Preferences" "$f"
done

# Prompt
for f in .p10k.zsh .starship.toml .config/starship.toml; do
  check_file "Prompt" "$f"
done

# Language Runtimes
for f in .irbrc .pryrc .pylintrc .flake8 .prettierrc .prettierrc.json \
         .prettierrc.yml .eslintrc .eslintrc.json .eslintrc.yml .eslintrc.js \
         .rubocop.yml .python-version .node-version .nvmrc .ruby-version \
         .tool-versions; do
  check_file "Language Runtimes" "$f"
done

# VS Code (optional)
if $INCLUDE_VSCODE; then
  for f in .config/Code/User/settings.json .config/Code/User/keybindings.json \
           ".config/Code - Insiders/User/settings.json"; do
    check_file "VS Code" "$f"
  done
fi

# Output
if [[ ${#RESULTS[@]} -eq 0 ]]; then
  echo "No dotfile candidates found in '$SCAN_PATH'."
  exit 0
fi

if $OUTPUT_JSON; then
  echo "["
  for i in "${!RESULTS[@]}"; do
    IFS='|' read -r cat file fullpath size_kb warning recommended <<< "${RESULTS[$i]}"
    comma=","
    if [[ $i -eq $(( ${#RESULTS[@]} - 1 )) ]]; then
      comma=""
    fi
    cat <<EOF
  {"category":"${cat}","file":"${file}","fullPath":"${fullpath}","sizeKB":"${size_kb}","warning":"${warning}","recommended":${recommended}}${comma}
EOF
  done
  echo "]"
else
  echo ""
  echo "Dotfile candidates found in: ${SCAN_PATH}"
  echo ""

  current_category=""
  category_count=0

  for entry in "${RESULTS[@]}"; do
    IFS='|' read -r cat file fullpath size_kb warning recommended <<< "$entry"

    if [[ "$cat" != "$current_category" ]]; then
      if [[ -n "$current_category" ]]; then
        echo ""
      fi
      # Count files in this category
      category_count=0
      for e in "${RESULTS[@]}"; do
        IFS='|' read -r c _ _ _ _ _ <<< "$e"
        if [[ "$c" == "$cat" ]]; then
          category_count=$((category_count + 1))
        fi
      done
      echo "  ${cat} (${category_count} files)"
      current_category="$cat"
    fi

    if [[ "$recommended" == "true" ]]; then
      icon="✅"
    else
      icon="⚠️"
    fi

    line="    ${icon} ${file}"
    if [[ "$size_kb" != "dir" ]]; then
      line="${line} (${size_kb} KB)"
    fi
    echo "$line"

    if [[ -n "$warning" ]]; then
      echo "       ⤷ ${warning}"
    fi
  done

  echo ""
  echo "Total: ${#RESULTS[@]} candidates found."
fi
