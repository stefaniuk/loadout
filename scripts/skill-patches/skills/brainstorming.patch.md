## Workflow Mode Guard

Use this skill only when the active local workflow mode is `superpowers`.

Before proceeding:

- Run `./scripts/hooks/workflow-mode.sh status`.
- If the active mode is `speckit`, stop and tell the user to switch with `make workflow-use mode=superpowers` or continue with the Spec Kit lifecycle instead.
- Do not mix Superpowers workflow skills with `speckit-*` commands in the same session or worktree.
