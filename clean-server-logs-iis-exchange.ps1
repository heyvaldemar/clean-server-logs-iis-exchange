<#
.SYNOPSIS
    Deletes IIS and Exchange Server log files older than a given number of days.

.DESCRIPTION
    IIS and Exchange write logs that nothing rotates: on a busy server they fill
    the system volume and Exchange stops accepting mail long before anyone reads
    a monitoring alert. This script removes log files older than -Days from the
    paths you pass in.

    It supports -WhatIf, so the first run can show exactly what would be deleted
    without deleting anything. Run it that way before you put it on a schedule.

.PARAMETER Path
    One or more folders to clean. Defaults to the standard IIS and Exchange
    Server 2019 (V15) logging paths.

.PARAMETER Days
    Delete files last written more than this many days ago. Default 30.

.PARAMETER Include
    File name patterns to consider. Default: *.log, *.blg, *.etl.

.EXAMPLE
    .\clean-server-logs-iis-exchange.ps1 -WhatIf

    Shows every file that would be deleted from the default paths.

.EXAMPLE
    .\clean-server-logs-iis-exchange.ps1 -Days 14 -Confirm:$false

    Deletes logs older than 14 days without prompting. This is the form to use
    from Task Scheduler.

.NOTES
    Run as a user that can delete inside the log folders (usually a local
    administrator). The script never changes the execution policy for you: if
    the host blocks scripts, launch it explicitly with
    powershell.exe -ExecutionPolicy Bypass -File .\clean-server-logs-iis-exchange.ps1
    so the machine-wide policy stays as your security team set it.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string[]] $Path = @(
        'C:\inetpub\logs\LogFiles',
        'C:\Program Files\Microsoft\Exchange Server\V15\Logging',
        'C:\Program Files\Microsoft\Exchange Server\V15\Bin\Search\Ceres\Diagnostics\ETLTraces',
        'C:\Program Files\Microsoft\Exchange Server\V15\Bin\Search\Ceres\Diagnostics\Logs'
    ),
    [ValidateRange(1, 3650)]
    [int] $Days = 30,
    [string[]] $Include = @('*.log', '*.blg', '*.etl')
)

$ErrorActionPreference = 'Stop'
$cutoff = (Get-Date).AddDays(-$Days)
$deleted = 0
$failed = 0
$bytes = [long]0

foreach ($folder in $Path) {
    if (-not (Test-Path -LiteralPath $folder)) {
        Write-Warning "Skipping $folder : the folder does not exist on this server."
        continue
    }

    Write-Verbose "Scanning $folder for files older than $cutoff"

    # -Force so hidden and system log files are seen; the folder itself is
    # never removed, only files inside it.
    $files = Get-ChildItem -LiteralPath $folder -Include $Include -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cutoff }

    foreach ($file in $files) {
        if ($PSCmdlet.ShouldProcess($file.FullName, "Delete log file older than $Days days")) {
            try {
                $size = $file.Length
                Remove-Item -LiteralPath $file.FullName -Force
                $deleted++
                $bytes += $size
            }
            catch {
                # A log the service still holds open cannot be deleted. That is
                # expected and must not stop the run, but it is reported rather
                # than swallowed.
                $failed++
                Write-Warning "Could not delete $($file.FullName): $($_.Exception.Message)"
            }
        }
    }
}

$freed = [math]::Round($bytes / 1GB, 2)
Write-Output "Deleted $deleted file(s), freed $freed GB, $failed file(s) could not be deleted."
