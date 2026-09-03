# Clean IIS and Exchange server logs

[![Script Verification](https://github.com/heyvaldemar/clean-server-logs-iis-exchange/actions/workflows/verification.yml/badge.svg?branch=main)](https://github.com/heyvaldemar/clean-server-logs-iis-exchange/actions/workflows/verification.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

IIS and Exchange write logs that nothing rotates. On a busy server they fill the system volume, and Exchange stops accepting mail long before anyone reads a disk alert. This PowerShell script deletes log files older than a given age from the IIS and Exchange logging paths.

## Getting started

```powershell
# 1. Clone
git clone https://github.com/heyvaldemar/clean-server-logs-iis-exchange
cd clean-server-logs-iis-exchange

# 2. See what would be deleted, without deleting anything
.\clean-server-logs-iis-exchange.ps1 -WhatIf

# 3. Delete for real once the list looks right
.\clean-server-logs-iis-exchange.ps1 -Days 30 -Confirm:$false
```

Run it as an account that can delete inside the log folders. It needs no domain rights.

### What success looks like

```text
What if: Performing the operation "Delete log file older than 30 days" on target "C:\inetpub\logs\LogFiles\W3SVC1\u_ex260801.log".
...
Deleted 4812 file(s), freed 37.4 GB, 3 file(s) could not be deleted.
```

The three that could not be deleted are normally logs the service still holds open. They are named in the output rather than hidden.

## Parameters

| Parameter  | Default | What it does |
|------------|---------|--------------|
| `-Path`    | IIS and Exchange V15 logging paths | Folders to clean. Pass your own if Exchange is not on the system drive. |
| `-Days`    | `30` | Delete files last written more than this many days ago. |
| `-Include` | `*.log, *.blg, *.etl` | File name patterns to consider. |

A path that does not exist on the server is reported and skipped, so the same command works on a mailbox server and on a plain IIS host.

## Scheduling it

```powershell
$action  = New-ScheduledTaskAction -Execute 'powershell.exe' `
  -Argument '-ExecutionPolicy Bypass -NoProfile -File "C:\Scripts\clean-server-logs-iis-exchange.ps1" -Days 30 -Confirm:$false'
$trigger = New-ScheduledTaskTrigger -Daily -At 3am
Register-ScheduledTask -TaskName 'Clean IIS and Exchange logs' -Action $action -Trigger $trigger -User 'SYSTEM' -RunLevel Highest
```

`-ExecutionPolicy Bypass` on the launcher is deliberate. The script does not change the machine's execution policy itself: a cleanup job has no business rewriting a security setting as a side effect.

## Production checklist

- [ ] **Run with `-WhatIf` first** and read the list. It is the cheapest possible review of a deletion job.
- [ ] **Check what Exchange keeps for you.** Message tracking and audit logs may be part of a retention obligation. Exclude those paths or raise `-Days` for them.
- [ ] **Set `-Days` from your disk headroom**, not from habit. Thirty days of IIS logs on a busy front end can be tens of gigabytes.
- [ ] **Watch the failure count** in the output. A number that keeps growing means a service is holding files open and the real fix is elsewhere.

## Testing

The [Script Verification](https://github.com/heyvaldemar/clean-server-logs-iis-exchange/actions/workflows/verification.yml?query=branch%3Amain) workflow runs on every push, pull request, and weekly: it parses the script, runs PSScriptAnalyzer at Error and Warning severity, checks that the comment-based help is present, and lints the workflow itself.

---

## About the maintainer

<div align="center">

**Maintained by [Vladimir Mikhalev](https://github.com/heyvaldemar)** · Docker Captain · IBM Champion · AWS Community Builder

[YouTube](https://www.youtube.com/channel/UCf85kQ0u1sYTTTyKVpxrlyQ?sub_confirmation=1) · [Blog](https://heyvaldemar.com) · [LinkedIn](https://www.linkedin.com/in/heyvaldemar/)

</div>
