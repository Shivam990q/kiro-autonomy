<#
.SYNOPSIS
    Replaces the Shivam990q placeholder across the repo with your actual GitHub
    username/org. Run once before pushing to GitHub.

.PARAMETER Owner
    Your GitHub username or organization name.

.EXAMPLE
    pwsh -File scripts/set-repo-owner.ps1 -Owner my-username

.NOTES
    Reads and writes every file as UTF-8 without BOM, preserving original
    line endings. This avoids the encoding round-trip corruption that
    Windows PowerShell 5.1 introduces when using Get-Content / Set-Content
    with default settings.
#>

[CmdletBinding(SupportsShouldProcess)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
    Justification = 'Write-Host is intentional for human-readable script output.')]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9-]{0,38}$')]
    [string]$Owner
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')

$targetExts  = @('*.md', '*.ps1', '*.sh', '*.bat', '*.yml', '*.yaml', '*.json', '*.jsonc')
$utf8NoBom   = New-Object System.Text.UTF8Encoding($false)
$count = 0

Get-ChildItem -Path $repoRoot -Recurse -File -Include $targetExts |
    Where-Object { $_.FullName -notmatch '\\(node_modules|\.git)\\' } |
    ForEach-Object {
        # Read raw bytes so we can:
        #   1. Detect and preserve original line endings
        #   2. Strip BOM if present (we don't want to add one to files that didn't have one)
        #   3. Round-trip cleanly through UTF-8 without ever touching cp1252
        $bytes = [System.IO.File]::ReadAllBytes($_.FullName)

        # Strip leading UTF-8 BOM bytes (EF BB BF) before decoding
        $hadBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
        if ($hadBom) {
            $bytes = $bytes[3..($bytes.Length - 1)]
        }

        $content = $utf8NoBom.GetString($bytes)
        if ($content -match 'Shivam990q') {
            $new = $content -replace 'Shivam990q', $Owner
            if ($PSCmdlet.ShouldProcess($_.FullName, "Replace Shivam990q -> $Owner")) {
                # For .sh files always preserve LF endings; never re-introduce a BOM
                if ($_.Extension -eq '.sh') {
                    $new = $new -replace "`r`n", "`n"
                }
                [System.IO.File]::WriteAllText($_.FullName, $new, $utf8NoBom)
                Write-Host ('  ' + $_.FullName.Substring($repoRoot.Path.Length + 1)) -ForegroundColor DarkGreen
                $script:count++
            }
        }
    }

Write-Host ''
Write-Host "Replaced Shivam990q -> $Owner in $count file(s)." -ForegroundColor Green
