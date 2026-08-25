include scripts/init.mk
include scripts/loadout.mk

# ==============================================================================
# Project targets

format: # Auto-format code @Quality
	./scripts/quality/format-markdown-tables.sh

lint-file-format: # Check file formats @Quality
	check=all ./scripts/quality/check-file-format.sh && echo "file format: ok"

lint-markdown-format: # Check markdown formatting @Quality
	check=all ./scripts/quality/check-markdown-format.sh && echo "markdown format: ok"

lint-markdown-links: # Check markdown links @Quality
	output=$$(check=all ./scripts/quality/check-markdown-links.sh 2>&1) && echo "markdown links: ok" || { echo "$$output"; exit 1; }

lint-shell: # Check shell scripts @Quality
	$(MAKE) check-shell-lint

lint-customisations: # Validate customisation artefact frontmatter and naming @Quality
	./scripts/quality/validate-customisations.sh

lint: # Run linter to check code style and errors @Quality
	$(MAKE) lint-file-format
	$(MAKE) lint-markdown-format
	$(MAKE) lint-markdown-links
	$(MAKE) lint-shell
	$(MAKE) lint-customisations

test: # Run comprehensive test suite @Testing
	@bash -c '\
		d=$$(mktemp -d); trap "rm -rf $$d" EXIT; \
		tests="apply speckit-sync import skill-sync session-start-hook subagent-hooks workflow-mode revert skill-remove"; \
		pids=""; \
		for t in $$tests; do \
			bash ./scripts/tests/$$t.test.sh > "$$d/$$t.log" 2>&1 & \
			pids="$$pids $$t:$$!"; \
		done; \
		status=0; \
		for entry in $$pids; do \
			t=$${entry%%:*}; p=$${entry##*:}; \
			if wait "$$p"; then echo "$$t: ok"; \
			else echo "$$t: FAIL"; cat "$$d/$$t.log"; status=1; fi; \
		done; \
		exit $$status \
	'

speckit-sync: # Fetch upstream spec-kit and apply local patches; optional: patch=[true|false] @Operations
	patch="$(or $(patch),true)" ./scripts/speckit-sync.sh

skill-sync: # Fetch/update external skills declared in scripts/config/skills.yaml and apply local patches; optional: name=[skill], patch=[true|false] @Operations
	name="$(name)" patch="$(or $(patch),true)" ./scripts/skill-sync.sh

skill-patch: # Reapply local patches to already-synced skills without fetching upstream; optional: name=[skill] @Operations
	name="$(name)" patch_only=true ./scripts/skill-sync.sh

skill-add: # Add a new external skill to config and sync it; mandatory: name=[name] repo=[url] path=[path]; optional: ref=[branch] @Operations
	$(if $(and $(name),$(repo),$(path)),,$(error Usage: make skill-add name=my-skill repo=https://github.com/owner/repo.git path=skills/my-skill))
	name="$(name)" repo="$(repo)" path="$(path)" ref="$(or $(ref),main)" ./scripts/skill-add.sh
	name="$(name)" ./scripts/skill-sync.sh

skill-remove: # Remove an external skill from config and delete its synced directory; mandatory: name=[name] @Operations
	$(if $(name),,$(error Usage: make skill-remove name=my-skill))
	name="$(name)" ./scripts/skill-remove.sh

rt-clone: # Clone the repository template into .github/skills/repository-template @Operations
	.github/skills/repository-template/scripts/git-clone-repository-template.sh

rt-remove: # Remove the cloned repository template assets from .github/skills/repository-template @Operations
	rm -rf .github/skills/repository-template/assets

apply: # Copy prompt files assets to a destination repository; mandatory: dest=[path]; optional: clean=[true|false], subset=[csv], all|python|typescript|go|reactjs|rust|terraform|tauri|playwright=[true] @Operations
	$(if $(dest),,$(error dest is required. Usage: make apply dest=/path/to/destination))
	./scripts/apply.sh "$(dest)"

import: # Import changed prompt files from a destination repository; mandatory: dest=[path]; optional: force|new=[true] @Operations
	$(if $(dest),,$(error dest is required. Usage: make import dest=/path/to/destination))
	./scripts/import.sh "$(dest)"

revert: # Remove all loadout-managed artifacts from a destination repository (opposite of apply); mandatory: dest=[path]; optional: dry-run=[true|false] @Operations
	$(if $(dest),,$(error dest is required. Usage: make revert dest=/path/to/destination))
	./scripts/revert.sh --dest "$(dest)" $(if $(filter true,$(dry-run)),--dry-run)

clean:: # Remove project-specific generated files (main) @Operations
	find .copilot/analysis -mindepth 1 ! -name ".gitignore" -exec rm -rf {} +
	rm -rf docs/superpowers
	rm -rf .github/skills/repository-template/assets
	find . \( \
		-name ".coverage" -o \
		-name ".env" -o \
		-name "*.log" -o \
		-name "coverage.xml" \
	\) -prune -exec rm -rf {} +

config:: # Configure development environment (main) @Configuration
	$(MAKE) _install-dependencies
	$(MAKE) rt-clone

# ==============================================================================

${VERBOSE}.SILENT: \
	apply \
	clean \
	config \
	format \
	import \
	lint \
	lint-customisations \
	lint-file-format \
	lint-markdown-format \
	lint-markdown-links \
	lint-shell \
	revert \
	rt-clone \
	rt-remove \
	skill-add \
	skill-patch \
	skill-remove \
	skill-sync \
	speckit-sync \
	test \
