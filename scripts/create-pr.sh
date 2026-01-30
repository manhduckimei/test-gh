#!/bin/bash

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null
then
    echo "Error: GitHub CLI (gh) is not installed. Please install it first (brew install gh)."
    exit 1
fi

# Get current branch name
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)

# Extract Task ID from branch (e.g., feat/VIET-123 -> VIET-123)
TASK_ID=$(echo "$BRANCH_NAME" | awk -F'/' '{print $NF}')
PLANE_LINK="https://plane.kways.vn/vietwow/browse/$TASK_ID"

# Get commit messages (from current branch relative to origin/main or origin/master)
BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@' 2>/dev/null || echo "main")

# Ensure we have the latest from origin
git fetch origin "$BASE_BRANCH" --quiet 2>/dev/null

# Check for uncommitted changes FIRST
# We use -u to see untracked files too
UNCOMMITTED=$(git status --porcelain -u)
if [ -n "$UNCOMMITTED" ]; then
    echo "Warning: You have uncommitted changes:"
    echo "$UNCOMMITTED"
    read -p "Do you want to commit them with message '$TASK_ID: update'? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git add .
        git commit -m "$TASK_ID: update"
    else
        echo "Proceeding with existing commits only. Note: uncommitted changes WILL NOT be in the PR."
    fi
fi

# Determine the range of commits. 
# If origin branch exists, use origin/base..HEAD. 
# Otherwise, we might be in an initial state or local-only repo.
if git rev-parse --verify "origin/$BASE_BRANCH" >/dev/null 2>&1; then
    RANGE="origin/$BASE_BRANCH..HEAD"
else
    RANGE="$BASE_BRANCH..HEAD"
fi

COMMITS=$(git log "$RANGE" --pretty=format:"* %s" 2>/dev/null)

# If no commits found
if [ -z "$COMMITS" ]; then
    echo "Error: No commits found between $BASE_BRANCH and current branch."
    echo "GitHub requires at least one commit difference to create a PR."
    exit 1
fi

# Author info
AUTHOR=$(git config user.name)

# Create PR Body
PR_BODY=$(cat <<EOF
## Summary

$COMMITS

## Task ID

[$TASK_ID]($PLANE_LINK)

---
**Author**: @$AUTHOR
EOF
)

echo "----------------------------------------"
echo "Creating PR for branch: $BRANCH_NAME"
echo "Targeting base: $BASE_BRANCH"
echo "Task ID: $TASK_ID"
echo "----------------------------------------"
echo "PR Body Preview:"
echo "$PR_BODY"
echo "----------------------------------------"

# Ask for confirmation
read -p "Do you want to create this PR? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

# Create the PR using gh cli
# Construct title (avoid duplicate Task ID)
TITLE=$(git log -1 --pretty=%s)
if [[ "$TITLE" != "$TASK_ID"* ]]; then
    TITLE="$TASK_ID: $TITLE"
fi
gh pr create --title "$TITLE" --body "$PR_BODY" --assignee "@me" --base "$BASE_BRANCH"
