#!/bin/bash

# Find all local and remote ancestor branches that have been merged
# into the root branch and create the delete commands to remove the branches.
#
# Great post on deleting branches in git:
# http://stackoverflow.com/a/23961231/123781

# ---------
# Config

# Set the root branch name.
# e.g. if you want to find all ancestors of master, 
# then set this to use `origin/master`
ROOT_BRANCH=origin/master
# Get the hash of the parent repo
ROOT_HASH="$(git rev-parse $ROOT_BRANCH 2>&-)"

# A list of protected repos that should never be operated on automatically
# meaning this script will _not_ create delete commands for these branches.
PROTECTED_BRANCHES=(master origin/master PROD origin/PROD BETA origin/BETA DEV origin/DEV)

# END Config
# ---------

# 1. Find all merged branches
FIND_BRANCH_COMMAND="git for-each-ref --sort=-committerdate --format='%(objectname):%(refname:short)' refs/heads/ refs/remotes/ --merged"
for branchName in ${PROTECTED_BRANCHES[@]}; do
	FIND_BRANCH_COMMAND+=" | grep -v $branchName"
done
FOUND_BRANCHES=`eval $FIND_BRANCH_COMMAND`

# 2. Filter branches down to only those ancestors fully merged into root branch.
ANCESTORS=()
for branch in $FOUND_BRANCHES; do
    HASH="$(echo $branch | awk -F":" '{print $1}')"
    REF="$(echo $branch | awk -F":" '{print $2}')"
	if $(git merge-base --is-ancestor "$HASH" "$ROOT_HASH"); then 
		ANCESTORS+=($REF)
	fi
done

echo "Found ${#ANCESTORS[@]} branches to clean."
echo "Building Delete Commands..."

# 3. Create the commands to clean up the git repo.
COMMANDS=()
PREFIX=""
# Loop over each ancestor branch, creating command to delete from local and remote git repo
for branch in ${ANCESTORS[@]}; do
	case "$branch" in
		origin/* ) 
			# handle remotes/origin case
			branchName="$(echo $branch | sed 's/origin\///')"
			command="git push origin --delete $branchName"
		;;
		*)
			# handle the local branch case
			command="git branch -d $branch"
		;;
	esac

	COMMANDS+=("$PREFIX$command;")
	PREFIX="\n"
done

# Write all commands to a file.
echo -e "${COMMANDS[@]}" > commands.txt
# Add command to clean up remote tracking branches.
echo -e "git remote prune origin;" >> commands.txt

echo "Commands written to \"commands.txt\""
