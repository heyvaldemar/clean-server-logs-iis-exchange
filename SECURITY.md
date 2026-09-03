# Security Policy

## Supported versions

| Version                                        | Status             |
|------------------------------------------------|--------------------|
| Current `main` and the latest tagged release   | :white_check_mark: |
| Older tags                                     | :x:                |

Fixes land on `main` and ship as a new tag; older tags are not patched in place.

## Reporting a vulnerability

Send reports to v@valdemar.ai. Encrypted email is preferred; the PGP public key is published at [heyvaldemar.com/security](https://heyvaldemar.com/security).

You can expect an acknowledgment within 7 days. This project does not operate a bounty program; researchers who submit valid, responsibly disclosed reports receive public credit in the release notes and the changelog.

Please do not open public GitHub issues for security reports.

## Running this script safely

The script deletes files. Two properties keep that from becoming an incident: it supports `-WhatIf`, so a first run prints every deletion without performing one, and it never changes the machine's execution policy for you. If a host blocks scripts, launch it with `powershell.exe -ExecutionPolicy Bypass -File` so the policy your security team set stays in place.

Run it as an account that can delete inside the log folders and nothing more. It needs no domain rights.

GitHub Actions used by this repository are pinned by commit SHA, and CI runs on every push and weekly.
