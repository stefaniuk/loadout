include scripts/init.mk

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

lint-mcp: # Validate .vscode/mcp.json.example syntax @Quality
	./scripts/quality/check-mcp-json.sh

lint: # Run linter to check code style and errors @Quality
	$(MAKE) lint-file-format
	$(MAKE) lint-markdown-format
	$(MAKE) lint-markdown-links
	$(MAKE) lint-shell
	$(MAKE) lint-customisations
	$(MAKE) lint-mcp

test: # Run fast local test suite (apply + specify + subagent-hooks + install). Slower tests run in CI via `test-all` @Testing
	bash ./scripts/tests/apply.test.sh && echo "apply: ok"
	bash ./scripts/tests/specify.test.sh && echo "specify: ok"
	bash ./scripts/tests/skill-sync.test.sh && echo "skill-sync: ok"
	bash ./scripts/tests/subagent-hooks.test.sh && echo "subagent-hooks: ok"
	$(MAKE) test-install

test-import: # Run import wrapper tests (slower; included in `test-all` and CI) @Testing
	bash ./scripts/tests/import.test.sh && echo "import: ok"

test-all: # Run the whole test suite (fast + import); used by the CI/CD workflow @Testing
	$(MAKE) test
	$(MAKE) test-import

test-install: # Run install/uninstall wrapper tests @Testing
	bash ./scripts/tests/install.test.sh && echo "install: ok"

test-skill-sync: # Run external skill sync tests @Testing
	bash ./scripts/tests/skill-sync.test.sh && echo "skill-sync: ok"

clone-rt: # Clone the repository template into .github/skills/repository-template @Operations
	.github/skills/repository-template/scripts/git-clone-repository-template.sh

skill-sync: # Fetch/update external skills declared in scripts/config/skills.yaml and apply local patches; optional: name=[skill], patch=[true|false] @Operations
	name="$(name)" patch="$(or $(patch),true)" ./scripts/skill-sync.sh

skill-patch: # Reapply local patches to already-synced skills without fetching upstream; optional: name=[skill] @Operations
	name="$(name)" patch_only=true ./scripts/skill-sync.sh

skill-add: # Add a new external skill to config and sync it; mandatory: name=[name] repo=[url] path=[path]; optional: ref=[branch] @Operations
	$(if $(and $(name),$(repo),$(path)),,$(error Usage: make skill-add name=my-skill repo=https://github.com/owner/repo.git path=skills/my-skill))
	name="$(name)" repo="$(repo)" path="$(path)" ref="$(or $(ref),main)" ./scripts/skill-add.sh
	name="$(name)" ./scripts/skill-sync.sh

specify: # Fetch upstream spec-kit and apply local patches; optional: patch=[true|false] @Operations
	patch="$(or $(patch),true)" ./scripts/specify.sh

apply: # Copy prompt files assets to a destination repository; mandatory: dest=[path]; optional: clean|revert=[true|false], subset=[csv], all|python|typescript|go|reactjs|rust|terraform|tauri|playwright=[true] @Operations
	$(if $(dest),,$(error dest is required. Usage: make apply dest=/path/to/destination))
	./scripts/apply.sh "$(dest)"

import: # Import changed prompt files from a destination repository; mandatory: dest=[path]; optional: force|new=[true] @Operations
	$(if $(dest),,$(error dest is required. Usage: make import dest=/path/to/destination))
	./scripts/import.sh "$(dest)"


clean:: # Remove project-specific generated files (main) @Operations
	rm -f docs/prompt-reports/*.{md,txt}
	rm -rf .github/skills/repository-template/assets
	find . \( \
		-name ".coverage" -o \
		-name ".env" -o \
		-name "*.log" -o \
		-name "coverage.xml" \
	\) -prune -exec rm -rf {} +

config:: # Configure development environment (main) @Configuration
	$(MAKE) _install-dependencies
	$(MAKE) clone-rt

# ==============================================================================

${VERBOSE}.SILENT: \
	apply \
	clean \
	clone-rt \
	config \
	format \
	import \
	lint \
	lint-customisations \
	lint-file-format \
	lint-markdown-format \
	lint-markdown-links \
	lint-mcp \
	lint-shell \
	skill-add \
	skill-patch \
	skill-sync \
	specify \
	test \
	test-skill-sync \
	test-all \
	test-import \
