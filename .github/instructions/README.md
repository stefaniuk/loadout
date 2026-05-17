# Instructions 📋

Auto-generated index of instruction packs. Each `*.instructions.md` carries an `applyTo` glob so Copilot scopes the rules to matching files automatically. See [VS Code custom instructions docs](https://code.visualstudio.com/docs/copilot/customization/custom-instructions).

> **Do not edit by hand.** Regenerate with `make catalogue`.

For the language-pack convention that pairs each tech instruction with an enforce prompt, see [docs/conventions.md](../../docs/conventions.md#language-packs).

## Catalogue

| File | `applyTo` | Description |
| ---- | --------- | ----------- |
| [docker.instructions.md](docker.instructions.md) | `{**/Dockerfile,**/Dockerfile.*,**/compose.yaml,**/compose.*.yaml,**/docker-compose.yaml,**/docker-compose.*.yaml}` | Dockerfile Engineering Instructions (container image development) |
| [go.instructions.md](go.instructions.md) | `**/*.go` | Go Engineering Instructions (CLI + API, framework-agnostic) |
| [likec4.instructions.md](likec4.instructions.md) | `**/*.{likec4,c4}` | LikeC4 DSL Instructions (architecture-as-code diagrams) |
| [makefile.instructions.md](makefile.instructions.md) | `{Makefile,**/Makefile,**/*.mk}` | Makefile Engineering Instructions (developer experience, CI-aligned) |
| [playwright-python.instructions.md](playwright-python.instructions.md) | `**/*.py` | Playwright Python Test Generation Instructions |
| [playwright-typescript.instructions.md](playwright-typescript.instructions.md) | `**/*.{ts,tsx}` | Playwright TypeScript Test Generation Instructions |
| [python.instructions.md](python.instructions.md) | `**/*.py` | Python Engineering Instructions (CLI + API, framework-agnostic) |
| [reactjs.instructions.md](reactjs.instructions.md) | `**/*.{jsx,tsx,js,ts}` | ReactJS Engineering Instructions |
| [readme.instructions.md](readme.instructions.md) | `**/README.md` | README Engineering Instructions |
| [rust.instructions.md](rust.instructions.md) | `**/*.rs` | Rust Engineering Instructions |
| [shell.instructions.md](shell.instructions.md) | `**/*.{sh,bash,zsh}` | Shell Script Engineering Instructions (Bash, CLI wrappers, automation) |
| [tauri.instructions.md](tauri.instructions.md) | `**/*.{rs,ts,tsx,js,jsx}` | Tauri Engineering Instructions |
| [terraform.instructions.md](terraform.instructions.md) | `**/*.tf` | Terraform Engineering Instructions (AWS) |
| [typescript.instructions.md](typescript.instructions.md) | `**/*.{js,ts,tsx}` | TypeScript Engineering Instructions (CLI + API + UI, framework-agnostic) |

## Subdirectories

- [`includes/`](includes/) — shared instruction fragments referenced via markdown file links.
- [`templates/`](templates/) — instruction-pack templates used when scaffolding new languages.
