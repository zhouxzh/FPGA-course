param(
    [int]$Width = 128,
    [int]$Height = 72,
    [int]$ClkFreq = 12000000,
    [int]$BaudRate = 1000000
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

if (-not (Get-Command "wsl" -ErrorAction SilentlyContinue)) {
    throw "WSL was not found. Install WSL first, or use run_sim.ps1 for native Windows Icarus Verilog."
}

function Convert-To-WslPath {
    param([string]$Path)

    $fullPath = (Resolve-Path -LiteralPath $Path).Path
    $drive = $fullPath.Substring(0, 1).ToLowerInvariant()
    $rest = $fullPath.Substring(2).Replace("\", "/")
    return "/mnt/$drive$rest"
}

$wslDir = Convert-To-WslPath $ScriptDir
$cmd = "cd '$wslDir' && make sim WIDTH=$Width HEIGHT=$Height CLK_FREQ=$ClkFreq BAUD_RATE=$BaudRate"
wsl -- bash -lc $cmd
exit $LASTEXITCODE
