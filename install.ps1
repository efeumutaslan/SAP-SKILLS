# SAP-SKILLS installer for Windows PowerShell
# Usage:
#   .\install.ps1                              Install all skills to .\.claude\skills (project)
#   .\install.ps1 -Global                      Install to $env:USERPROFILE\.claude\skills (all projects)
#   .\install.ps1 sap-rap-comprehensive,sap-cap-advanced   Install specific skills
#   .\install.ps1 -Global sap-rap-comprehensive            Combine

[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Skills = @(),

    [switch]$Global,

    [switch]$Help
)

if ($Help) {
    Write-Host "SAP-SKILLS installer"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\install.ps1                       Install all skills to .\.claude\skills"
    Write-Host "  .\install.ps1 -Global               Install all skills to `$env:USERPROFILE\.claude\skills"
    Write-Host "  .\install.ps1 skill1,skill2         Install only the named skills"
    Write-Host "  .\install.ps1 -Global skill1        Install named skills globally"
    exit 0
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceDir = Join-Path $ScriptDir "skills"

if (-not (Test-Path $SourceDir)) {
    Write-Error "Skills directory not found at $SourceDir"
    exit 1
}

if ($Global) {
    $Target = Join-Path $env:USERPROFILE ".claude\skills"
} else {
    $Target = Join-Path (Get-Location) ".claude\skills"
}

New-Item -ItemType Directory -Force -Path $Target | Out-Null

if ($Skills.Count -eq 0) {
    Write-Host "Installing all SAP skills to $Target"
    Copy-Item -Recurse -Force -Path (Join-Path $SourceDir "*") -Destination $Target
    $Count = (Get-ChildItem -Directory $SourceDir).Count
    Write-Host "Installed $Count skills."
} else {
    foreach ($skill in $Skills) {
        $SkillPath = Join-Path $SourceDir $skill
        if (-not (Test-Path $SkillPath)) {
            Write-Warning "Skill '$skill' not found in $SourceDir"
            continue
        }
        Copy-Item -Recurse -Force -Path $SkillPath -Destination $Target
        Write-Host "Installed: $skill"
    }
}

Write-Host ""
Write-Host "Done. Restart Claude Code for the skills to take effect."
