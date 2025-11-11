#!/bin/bash
# Git workflow helper functions
# Source this file to use: source .claude/skills/managing-git-workflow/scripts/git-helpers.sh

# Check if in git repository
# Returns: 0 if in repo, 1 if not
_check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "ERROR: Not in a git repository" >&2
        return 1
    fi
    return 0
}

# Check if there are uncommitted changes (staged or unstaged)
# Returns: 0 if changes exist, 1 if clean, 2 if not in git repo
has_uncommitted_changes() {
    _check_git_repo || return 2

    # Check both staged and unstaged changes
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
        return 0
    else
        return 1
    fi
}

# Check if there are unpushed commits on current branch
# Returns: 0 if unpushed commits exist, 1 if up to date
has_unpushed_commits() {
    local current_branch=$(git branch --show-current)
    local upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)

    if [[ -z "$upstream" ]]; then
        # No upstream tracking - check if any commits exist
        if [[ $(git rev-list --count HEAD) -gt 0 ]]; then
            return 0
        else
            return 1
        fi
    else
        # Compare with upstream
        local unpushed=$(git rev-list --count @{u}..HEAD 2>/dev/null)
        if [[ $unpushed -gt 0 ]]; then
            return 0
        else
            return 1
        fi
    fi
}

# Get current branch name
# Returns: branch name as string, empty if error
get_current_branch() {
    _check_git_repo || return 1

    local branch=$(git branch --show-current 2>/dev/null)
    if [[ -z "$branch" ]]; then
        echo "ERROR: Could not determine current branch (detached HEAD?)" >&2
        return 1
    fi
    echo "$branch"
}

# Check if upstream tracking exists for current branch
# Returns: 0 if exists, 1 if not
has_upstream() {
    git rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null
    return $?
}

# Check if PR exists for current branch
# Returns: 0 if PR exists, 1 if not, 2 if gh not available
check_pr_exists() {
    # Check if gh CLI is installed
    if ! command -v gh &> /dev/null; then
        echo "ERROR: gh CLI not found. Install with: brew install gh" >&2
        echo "Then authenticate with: gh auth login" >&2
        return 2
    fi

    local current_branch=$(get_current_branch) || return 1

    local pr_count=$(gh pr list --head "$current_branch" --json number --jq 'length' 2>/dev/null)
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        echo "ERROR: Failed to check PR status. Are you authenticated?" >&2
        echo "Run: gh auth login" >&2
        return 2
    fi

    [[ $pr_count -gt 0 ]]
}

# Get PR URL for current branch
# Returns: PR URL as string, empty if not found or error
get_pr_url() {
    if ! command -v gh &> /dev/null; then
        echo "ERROR: gh CLI not found" >&2
        return 1
    fi

    local current_branch=$(get_current_branch) || return 1
    gh pr list --head "$current_branch" --json url --jq '.[0].url' 2>/dev/null
}

# Extract ticket number from branch name
# Returns: ticket number (e.g., FMT-1234, FLEASVR-287) or empty string
extract_ticket_from_branch() {
    local branch=$(get_current_branch)
    # Match patterns like FMT-1234, FLEASVR-287, ABC-123
    if [[ $branch =~ ([A-Z]+(-[A-Z]+)?-[0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo ""
    fi
}

# Check if on main/master branch
# Returns: 0 if on main branch, 1 if not
is_main_branch() {
    local branch=$(get_current_branch)
    if [[ "$branch" == "master" || "$branch" == "main" ]]; then
        return 0
    else
        return 1
    fi
}

# Get repository owner and name from git remote
# Returns: "owner/repo" format, empty if not a GitHub repo
get_repo_info() {
    _check_git_repo || return 1

    local remote_url=$(git remote get-url origin 2>/dev/null)
    if [[ -z "$remote_url" ]]; then
        echo "ERROR: No remote 'origin' found" >&2
        return 1
    fi

    if [[ $remote_url =~ github\.com[:/](.+)/(.+)(\.git)?$ ]]; then
        local owner="${BASH_REMATCH[1]}"
        local repo="${BASH_REMATCH[2]%.git}"
        echo "$owner/$repo"
    else
        echo "ERROR: Remote 'origin' is not a GitHub repository" >&2
        return 1
    fi
}
