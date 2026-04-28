# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository

- GitHub: <https://github.com/azimovich/failure_kit>
- Default branch: `main`. Release branches: `version/X.Y.Z`.

## Commands

```bash
dart pub get          # install dependencies
dart analyze          # lint — must be clean before commit
dart test             # run all tests
dart test -N "name"   # run single test by exact name
dart test -n "pattern"# run tests matching pattern
dart run example/failure_kit_example.dart
dart run example/dio_integration.dart
```

## Architecture

### Single entry point

- `lib/failure_kit.dart` — the only public entry. HTTP-client agnostic, no runtime Dio dependency.

**Rule:** Core (`lib/`) must not depend on any HTTP client. Dio integration lives only in `example/dio_integration.dart` as a copy-paste reference for users. `dio` is a `dev_dependency` (for the example) — never promote it to `dependencies`.

### Three core abstractions

**`Either<L, R>`** (`lib/src/either.dart`) — sealed `Left`/`Right` union. `Left` = failure, `Right` = success. Fully chainable (`map`, `then`, `mapAsync`, `thenAsync`, `fold`, `getOrElse`).

**`Failure`** (`lib/src/failure.dart`) — `abstract` (not `sealed`) base class. Six built-in subtypes: `ServerFailure`, `NoInternetFailure`, `TimeoutFailure`, `CancellationFailure`, `ParsingFailure`, `UnknownFailure`. Users extend `Failure` freely; their subtypes route to `when(custom:)` wildcard. `ServerFailure` carries `data: Object?` — raw response body for domain-specific field extraction.

**`FailureMapperChain`** (`lib/src/failure_mapper.dart`) — interceptor-style chain:

- `FailureMapper` typedef: `Failure? Function(Object error, StackTrace stackTrace)` — return `null` to pass to next.
- `FailureMapperChain.base` — empty chain, falls back to `BaseFailureMapper`.
- `prepend(mapper)` — adds mapper that runs first; `append(mapper)` — runs last before fallback.
- `handle()` — iterates mappers; first non-null wins; always falls back to `BaseFailureMapper.handle()` (guaranteed non-null).

**`FailureGuard`** (`lib/src/failure_guard.dart`) — mixin with `call<T>(action)`. Wraps action in try/catch, routes the error through `failureChain`, returns `Left(failure)` or `Right(value)`. Override `failureChain` to inject custom mappers.

## Extension rules (OCP)

- **Custom Failure:** Subclass `Failure` in user project. It will fall into `when(custom:)`. No package changes needed.
- **Custom mapper:** Return `Failure?` — `null` for errors you don't own. Register via `FailureMapperChain.base.prepend(MyMapper.handle)` or override `failureChain`.
- **Adding a new built-in Failure subtype** is a breaking change — it adds a required parameter to `when()`. Bump major version and add migration guide to `CHANGELOG.md`.

## Testing conventions

- Every `when()` call in tests must include a `custom:` case.
- New `FailureMapperChain` behaviour tests go inside the existing `'FailureMapperChain'` group in `test/failure_kit_test.dart`.

## Publishing

Run `dart pub publish --dry-run` before every release — must show **0 warnings**.

`.pubignore` excludes `CLAUDE.md` and `.claude/` from the published archive (they stay tracked in git for collaborators). Never re-add them to `.gitignore` — pub.dev warns when a checked-in file is also gitignored.

## Release

1. Bump `version` in `pubspec.yaml`.
2. Add entry to `CHANGELOG.md` (breaking changes + migration guide for majors).
3. Work on branch `version/X.Y.Z`. Commits and PRs in English.
4. Commit messages must NOT include a `Co-Authored-By: Claude` trailer.
5. After merge to `main`: tag `vX.Y.Z`, push tags, then `dart pub publish`.
