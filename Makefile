include scripts/init.mk

# ==============================================================================
# Project targets

env: # Set up project environment @Configuration
	# TODO: Implement environment setup steps

deps: # Install dependencies needed to build and test the project @Build
	# TODO: Implement installation of your project dependencies

format: check ?= all
format: # Auto-format code (set check=all|staged-changes|working-tree-changes|branch) @Quality
	$(MAKE) format-markdown

lint: check ?= all
lint: # Run linter to check code style and errors (set check=all|staged-changes|working-tree-changes|branch for the file checks) @Quality
	if [[ "$(check)" == branch ]]; then
		source scripts/quality/git-base.lib.sh
		quality-export-pr-base
	fi
	$(MAKE) lint-file-format
	$(MAKE) lint-markdown-format
	$(MAKE) lint-markdown-links
	$(MAKE) lint-shell
	$(MAKE) lint-workflow-security

typecheck: # Run type checker @Quality
	# TODO: Implement type checking required for this repository

test: # Run all tests @Quality
	./scripts/tests/run-test-suites.sh

check: # Run all format, lint, type and test checks @Quality
	$(MAKE) format
	$(MAKE) lint
	$(MAKE) typecheck
	$(MAKE) test

build: # Build the project artefact @Build
	# TODO: Implement the artefact build step

publish: # Publish the project artefact @Release
	# TODO: Implement the artefact publishing step

deploy: # Deploy the project artefact to the target environment @Release
	# TODO: Implement the artefact deployment step

validate-customisations: # Validate customisation artefact frontmatter and naming @Quality
	./scripts/quality/validate-customisations.sh

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

apply: # Copy prompt files assets to a destination repository; mandatory: dest=[path]; optional: clean=[true|false], subset=[csv], all|python|typescript|go|reactjs|rust|terraform|tauri|playwright=[true] @Operations
	$(if $(dest),,$(error dest is required. Usage: make apply dest=/path/to/destination))
	./scripts/apply.sh "$(dest)"

import: # Import changed prompt files from a destination repository; mandatory: dest=[path]; optional: force|new=[true] @Operations
	$(if $(dest),,$(error dest is required. Usage: make import dest=/path/to/destination))
	./scripts/import.sh "$(dest)"

revert: # Remove all loadout-managed artifacts from a destination repository (opposite of apply); mandatory: dest=[path]; optional: dry-run=[true|false] @Operations
	$(if $(dest),,$(error dest is required. Usage: make revert dest=/path/to/destination))
	./scripts/revert.sh --dest "$(dest)" $(if $(filter true,$(dry-run)),--dry-run)

config:: # Configure development environment (main) @Configuration
	# TODO: Implement project-specific configuration steps

clean:: # Clean-up project resources (main) @Operations
	# TODO: Implement project resources clean-up step

# ==============================================================================

${VERBOSE}.SILENT: \
	apply \
	build \
	check \
	clean \
	config \
	deploy \
	deps \
	env \
	format \
	import \
	lint \
	publish \
	revert \
	skill-add \
	skill-patch \
	skill-remove \
	skill-sync \
	speckit-sync \
	test \
	typecheck \
	validate-customisations \
