# loadout-managed: scripts/loadout.ext.mk

# ==============================================================================
# Loadout workflow mode targets
# ==============================================================================

workflow-clear: # Clear the workflow mode chosen for this worktree, so the default applies @Operations
	./scripts/hooks/workflow-mode.sh clear

workflow-list: # List the workflow modes and mark the active one @Operations
	./scripts/hooks/workflow-mode.sh list

workflow-status: # Print the active workflow mode of this worktree, or none @Operations
	./scripts/hooks/workflow-mode.sh status

workflow-use: # Make a workflow mode active in this worktree - mandatory: mode=[name from make workflow-list] @Operations
	mode=$(mode) ./scripts/hooks/workflow-mode.sh use

# ==============================================================================

${VERBOSE}.SILENT: \
	workflow-clear \
	workflow-list \
	workflow-status \
	workflow-use \
