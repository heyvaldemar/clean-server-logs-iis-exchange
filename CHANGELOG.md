# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

_(no unreleased changes yet)_

## [1.1.0] - 2026-09-26

### Added

- **Tests of what the script does, and proof that they can fail.** A Pester suite runs the script for real and asserts its behaviour; `tests/plant-violations.py` breaks it 6 ways on a copy and requires the suite to notice each. Both run in CI on every push.

## [1.0.0] - 2026-09-03

### Fixed

- **The script only ever cleaned one folder.** `CleanLogfiles` took a
  `$TargetFolder` parameter and then ignored it, scanning the hardcoded
  Exchange logging path instead. IIS logs were never deleted, no matter what
  the script printed, and the Exchange path was walked four times per run.
  Each path passed in is now the path that gets cleaned.
- **A failed deletion is reported instead of hidden.** `-ErrorAction
  SilentlyContinue` on the delete meant a log the service still held open
  looked exactly like a successful cleanup. Failures are now counted and named
  in the summary.

### Added

- **`-WhatIf` support.** The first run can show every file it would delete
  without deleting one, which is the only safe way to point a deletion script
  at a production mail server.
- **Parameters instead of edit-the-file variables**: `-Path`, `-Days` and
  `-Include`, with the previous values as defaults, so the script can be
  scheduled without a local fork.
- **Comment-based help** (`Get-Help .\clean-server-logs-iis-exchange.ps1 -Full`)
  and a summary line reporting how many files were deleted and how much space
  came back.
- CI that parses the script and runs PSScriptAnalyzer at Error and Warning
  severity on every push and weekly.

### Removed

- **`Set-Executionpolicy RemoteSigned` from the top of the script.** A cleanup
  script has no business changing a machine-wide security setting as a side
  effect of running.

[Unreleased]: https://github.com/heyvaldemar/clean-server-logs-iis-exchange/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/heyvaldemar/clean-server-logs-iis-exchange/releases/tag/v1.0.0
