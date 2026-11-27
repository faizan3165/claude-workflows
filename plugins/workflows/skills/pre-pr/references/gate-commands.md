# Fallback gate commands by stack

Use these only when the repo's docs, CI, task runner and git hooks don't define the gate. Run a tool only if the repo configures it (config file or dev dependency present). Prefix with the repo's runner (`pnpm`, `uv run`, `poetry run`, `bundle exec`, `./gradlew`...).

| Stack (detected by) | Format | Lint / static | Typecheck | Test | Build |
|---|---|---|---|---|---|
| JS / TS (`package.json`) | `prettier --check .` or `biome ci .` | `eslint .` or `biome lint` | `tsc --noEmit` | `vitest run`, `jest --ci`, or the `test` script with `CI=true` | `build` script |
| Deno (`deno.json`) | `deno fmt --check` | `deno lint` | `deno check .` | `deno test` | |
| Python (`pyproject.toml`, `setup.cfg`, `requirements*.txt`) | `ruff format --check .` or `black --check .` | `ruff check .` or `flake8` | `mypy` or `pyright` if configured | `pytest -q` | `python -m build` only if CI builds |
| Django (`manage.py`) | as Python | `python manage.py check` | as Python | `pytest` or `python manage.py test` | `makemigrations --check --dry-run` |
| Go (`go.mod`) | `test -z "$(gofmt -l .)"` | `go vet ./...`, `golangci-lint run` if configured | (compiler) | `go test ./...` (`-race` if CI uses it) | `go build ./...` |
| Rust (`Cargo.toml`) | `cargo fmt --all -- --check` | `cargo clippy --all-targets -- -D warnings` | (compiler) | `cargo test` | `cargo build` |
| Java / Kotlin, Gradle (`build.gradle*`) | `./gradlew spotlessCheck` or `ktlintCheck` if configured | `./gradlew check` (detekt, checkstyle if configured) | (compiler) | `./gradlew test` | `./gradlew build` |
| Java, Maven (`pom.xml`) | `./mvnw spotless:check` if configured | `./mvnw -B verify` covers configured plugins | (compiler) | `./mvnw -B test` | `./mvnw -B verify` |
| .NET (`*.sln`, `*.csproj`) | `dotnet format --verify-no-changes` | analyzers run in build | (compiler) | `dotnet test --no-build` | `dotnet restore` then `dotnet build --no-restore` |
| Dart / Flutter (`pubspec.yaml`) | `dart format --output=none --set-exit-if-changed .` | `flutter analyze` or `dart analyze` | (analyzer) | `flutter test` or `dart test` | only if CI builds (slow, platform-bound) |
| Swift, SwiftPM (`Package.swift`) | `swift-format lint -r .` if configured | `swiftlint` if `.swiftlint.yml` | (compiler) | `swift test` | `swift build` |
| Swift, Xcode (`*.xcodeproj`) | as above | as above | (compiler) | `xcodebuild test -scheme <S> -destination '<D>'`, scheme and destination from CI or ask | `xcodebuild build` |
| Ruby (`Gemfile`) | `rubocop` covers format | `bundle exec rubocop` | `srb tc` or `steep check` if configured | `bundle exec rspec` or `bin/rails test` | |
| PHP (`composer.json`) | `vendor/bin/pint --test` or `php-cs-fixer fix --dry-run --diff` | `vendor/bin/phpstan analyse` or `psalm`, `phpcs` | (static analysis) | `vendor/bin/phpunit` or `vendor/bin/pest` | `composer validate --strict` |
| Elixir (`mix.exs`) | `mix format --check-formatted` | `mix credo` if a dependency | `mix dialyzer` if configured | `mix test` | `mix compile --warnings-as-errors` |
| C / C++ (`CMakeLists.txt`) | `clang-format --dry-run --Werror <changed files>` if `.clang-format` | `clang-tidy` if `.clang-tidy` | (compiler) | `ctest --test-dir build` | `cmake -S . -B build && cmake --build build` |
| Terraform (`*.tf`) | `terraform fmt -check -recursive` | `tflint` if configured | `terraform init -backend=false && terraform validate` | | |
| Shell (`*.sh`) | `shfmt -d` if configured | `shellcheck <changed scripts>` | | `bats` if present | |
| Docker (`Dockerfile`) | | `hadolint Dockerfile` if available | | | `docker build` only if CI does |
| Helm / Kubernetes | | `helm lint`, `kubeconform` if configured | | | |
| Expo / React Native | as JS / TS | as JS / TS, plus `npx expo-doctor` for Expo | `tsc --noEmit` | as JS / TS | native builds only if CI does |
| Markdown / docs | `prettier --check` or `markdownlint` if configured | link check if CI runs one | | | site build if CI runs one |

## Database migrations

If the diff touches schema or migrations, run the repo's check when it exists: `drizzle-kit check`, `prisma validate` plus `prisma migrate diff`, `alembic check`, `rails db:migrate:status`, `makemigrations --check`.

## Monorepos (affected packages only)

- Turborepo: `turbo run lint test build --filter=...[origin/<base>]`
- Nx: `nx affected -t lint test build --base=origin/<base>`
- pnpm workspaces: `pnpm -r --filter "...[origin/<base>]" run <script>`
- Otherwise run the gate in each package the diff touches.
