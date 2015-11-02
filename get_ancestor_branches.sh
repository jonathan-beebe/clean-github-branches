#!/bin/bash

# Find all local and remote ancestor branches that have been merged into the root branch

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

echo ${ANCESTORS[@]}
