# loadout-managed: scripts/loadout.mk

# ==============================================================================
# Loadout workflow targets
# ==============================================================================

workflow-status: # Print the active local workflow mode; optional: LOADOUT_WORKFLOW_MODE_FILE=[path] @Operations
	./scripts/hooks/workflow-mode.sh status

workflow-switch: # Flip the active local workflow mode between superpowers and speckit; optional: LOADOUT_WORKFLOW_MODE_FILE=[path] @Operations
	./scripts/hooks/workflow-mode.sh switch

workflow-use: # Set the active local workflow mode; mandatory: mode=[speckit|superpowers]; optional: LOADOUT_WORKFLOW_MODE_FILE=[path] @Operations
	$(if $(mode),,$(error mode is required. Usage: make workflow-use mode=speckit))
	./scripts/hooks/workflow-mode.sh use "$(mode)"

# ==============================================================================

${VERBOSE}.SILENT: \
	workflow-switch \
	workflow-status \
	workflow-use \
