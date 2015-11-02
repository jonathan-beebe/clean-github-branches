#!/bin/bash

# Input: takes a list of git branches as input.
# Output: outputs a list of git commands to delete the input branches.
#
# Great post on deleting branches in git:
# http://stackoverflow.com/a/23961231/123781

# Set `input` to grab the first argument, or the stdin.
[ $# -ge 1 -a -f "$1" ] && input="$1" || input=$(cat)

# Loop over each branch, creating command to delete from local and remote git repo
for branch in ${input[@]}; do
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

	echo $command
done
