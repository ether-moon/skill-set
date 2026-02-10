#!/usr/bin/env bash

# Detect installed skill-set plugins and inject them into the SKILL.md

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"
SKILL_FILE="${PLUGIN_ROOT}/SKILL.md"
PLUGINS_DIR="${HOME}/.claude/plugins"

# Define skill-set plugins to check
declare -a SKILL_SET_PLUGINS=(
  "consulting-peer-llms"
  "managing-git-workflow"
  "understanding-code-context"
  "coderabbit-feedback"
)

# Find installed plugins
INSTALLED=()
for plugin in "${SKILL_SET_PLUGINS[@]}"; do
  if [ -d "${PLUGINS_DIR}/${plugin}" ]; then
    INSTALLED+=("- **${plugin}**")
  fi
done

# Build the installed plugins list
if [ ${#INSTALLED[@]} -eq 0 ]; then
  PLUGINS_LIST="No skill-set plugins currently installed."
else
  PLUGINS_LIST=$(printf '%s\n' "${INSTALLED[@]}")
fi

# Create a temporary SKILL.md with installed plugins injected
TEMP_SKILL=$(mktemp)
sed "s|{{INSTALLED_PLUGINS}}|${PLUGINS_LIST}|g" "${SKILL_FILE}" > "${TEMP_SKILL}"

# Output the modified SKILL.md content
cat "${TEMP_SKILL}"
rm "${TEMP_SKILL}"
