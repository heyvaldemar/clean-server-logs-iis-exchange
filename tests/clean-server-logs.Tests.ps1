# What the script promises, run against a real folder on any machine with
# PowerShell 7: old logs of the named kinds go, everything else stays, and
# -WhatIf touches nothing. tests/plant-violations.py breaks each promise in a
# copy of the script and requires this file to notice.
#
#   Invoke-Pester -Path tests -Output Detailed

BeforeAll {
    $script:Script = Join-Path $PSScriptRoot '..' 'clean-server-logs-iis-exchange.ps1'

    function New-Log([string] $Root, [string] $Name, [int] $AgeDays) {
        $path = Join-Path $Root $Name
        New-Item -ItemType Directory -Force -Path (Split-Path $path) | Out-Null
        Set-Content -LiteralPath $path -Value ('x' * 1024)
        (Get-Item -LiteralPath $path).LastWriteTime = (Get-Date).AddDays(-$AgeDays)
        $path
    }
}

Describe 'clean-server-logs-iis-exchange.ps1' {
    BeforeEach {
        $script:Root = Join-Path ([System.IO.Path]::GetTempPath()) ("logs-" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $Root | Out-Null
        $script:OldLog  = New-Log $Root 'W3SVC1/u_ex200101.log' 90
        $script:OldEtl  = New-Log $Root 'Diagnostics/trace.etl' 45
        $script:OldBlg  = New-Log $Root 'perf/counters.blg' 31
        $script:NewLog  = New-Log $Root 'W3SVC1/u_ex260925.log' 2
        $script:OldConf = New-Log $Root 'W3SVC1/web.config' 400
        $script:OldTxt  = New-Log $Root 'readme.txt' 400
    }
    AfterEach { Remove-Item -LiteralPath $Root -Recurse -Force -ErrorAction SilentlyContinue }

    It 'deletes logs older than -Days, in subfolders too' {
        & $Script -Path $Root -Days 30 -Confirm:$false | Out-Null
        $OldLog, $OldEtl, $OldBlg | ForEach-Object { Test-Path -LiteralPath $_ | Should -BeFalse }
    }

    It 'keeps logs newer than -Days' {
        & $Script -Path $Root -Days 30 -Confirm:$false | Out-Null
        Test-Path -LiteralPath $NewLog | Should -BeTrue
    }

    It 'never touches a file that is not a log, however old' {
        & $Script -Path $Root -Days 30 -Confirm:$false | Out-Null
        Test-Path -LiteralPath $OldConf | Should -BeTrue
        Test-Path -LiteralPath $OldTxt | Should -BeTrue
    }

    It 'leaves the folders in place' {
        & $Script -Path $Root -Days 30 -Confirm:$false | Out-Null
        Test-Path -LiteralPath (Join-Path $Root 'W3SVC1') | Should -BeTrue
        Test-Path -LiteralPath $Root | Should -BeTrue
    }

    It 'deletes nothing under -WhatIf, and does not claim to have' {
        $out = & $Script -Path $Root -Days 30 -WhatIf
        $OldLog, $OldEtl, $OldBlg, $NewLog | ForEach-Object { Test-Path -LiteralPath $_ | Should -BeTrue }
        # Remove-Item honours -WhatIf on its own, so the files survive even if
        # the script's own ShouldProcess were bypassed; the count would not.
        $out | Should -Match '^Deleted 0 file\(s\)'
    }

    It 'says how many files it deleted' {
        $out = & $Script -Path $Root -Days 30 -Confirm:$false
        $out | Should -Match '^Deleted 3 file\(s\)'
    }

    It 'skips a folder that does not exist and still cleans the ones that do' {
        $missing = Join-Path $Root 'no-such-folder'
        $out = & $Script -Path $missing, $Root -Days 30 -Confirm:$false -WarningVariable w -WarningAction SilentlyContinue
        ($w -join ' ') | Should -Match 'does not exist'
        Test-Path -LiteralPath $OldLog | Should -BeFalse
        $out | Should -Match '^Deleted 3 file\(s\)'
    }

    It 'honours -Include' {
        & $Script -Path $Root -Days 30 -Include '*.etl' -Confirm:$false | Out-Null
        Test-Path -LiteralPath $OldEtl | Should -BeFalse
        Test-Path -LiteralPath $OldLog | Should -BeTrue
    }

    It 'refuses -Days 0, which would delete every log' {
        { & $Script -Path $Root -Days 0 -Confirm:$false } | Should -Throw
        Test-Path -LiteralPath $NewLog | Should -BeTrue
    }
}
