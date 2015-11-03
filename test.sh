#!/bin/bash

# ---------
# Config

# Set the parent repo name.
# e.g. if you want to find all ancestors of master, 
# then set this to use `origin/master`
PARENT_REF=origin/master

# A list of protected repos that should never be operated on automatically
PROTECTED_REPOS=(master origin/master PROD origin/PROD BETA origin/BETA DEV origin/DEV)

# END Config
# ---------

# Check if a list contains the given value
#
# See this article on passing arrays as parameters
# http://www.faqs.org/docs/abs/HTML/assortedtips.html#ARRFUNC
#
# @example:
# ```
# value=PROD
# if listContains "$PROTECTED_REPOS_ARG" $value; then
# 	echo "contains $value"
# else
# 	echo "does not contain $value"
# fi
# ```
function listContains()
{
	if [[ $1 =~ $2 ]]; then
		return 0
	else
		return 1
	fi
}

# The argument suitable for passing into a function
PROTECTED_REPOS_ARG=`echo ${PROTECTED_REPOS[@]}`

# Get the sha hash of the parent repo
PARENT_SHA="$(git rev-parse $PARENT_REF)"

# Find each branch that is merged into the parent repo
CHILDREN=()
for branch in $(git for-each-ref --sort=-committerdate --format='%(objectname):%(refname:short)' refs/heads/ refs/remotes/); do
    SHA="$(echo $branch | awk -F":" '{print $1}')"
    REF="$(echo $branch | awk -F":" '{print $2}')"

	if listContains "$PROTECTED_REPOS_ARG" $REF; then
		echo "skipping $REF"
	else
		if git merge-base --is-ancestor "$SHA" "$PARENT_SHA"; then 
			CHILDREN+=($REF)
		else 
			echo "skipping $REF"
		fi
	fi

done

echo
echo

echo "found ${#CHILDREN[@]} ancestor branches"

echo
echo

# Loop over each ancestor branch, deleting from local and remote git repo
for branch in ${CHILDREN[@]}; do
	echo
	echo "working on $branch"
	case "$branch" in
		origin/* ) 
			# handle remotes/origin case

			# Get the sha hash for this branch
			branchSHA="$(git rev-parse $branch)"
			echo "branchSHA = $branchSHA"
			# Get the short branch name, e.g. without the `origin/` prefix
			shortBranchName="$(git name-rev --name-only $branchSHA)"
			echo "shortBranchName = $shortBranchName"
			command="git push origin --delete $shortBranchName"

			# branchName="$(echo $branch | sed 's/origin\///')"
			# command="git push origin --delete $branchName"
		;;
		*)
			command="git branch -d $branch"
		;;
	esac

	echo
	echo "$command"
	# echo $($command)
done
