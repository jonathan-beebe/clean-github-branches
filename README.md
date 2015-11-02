
To find all ancestor branches

```
./get_ancestor_branches.sh
```

To create the delete commands for all ancestor branches and echo them as text (not invoking them)

```
./get_ancestor_branches.sh | ./delete_branches.sh
```

To invoke the delete commands to actually perform the work

```
./get_ancestor_branches.sh | ./delete_branches.sh | bash -
```
