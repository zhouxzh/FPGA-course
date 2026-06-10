param(
    [int]$Width = 128,
    [int]$Height = 72,
    [int]$ClkFreq = 12000000,
    [int]$BaudRate = 1000000,
    [string]$Python = "python",
    [string]$Iverilog = "iverilog",
    [string]$Vvp = "vvp",
    [switch]$UseWsl
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

function Test-Tool {
    param([string]$Name)

    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Convert-To-WslPath {
    param([string]$Path)

    $fullPath = (Resolve-Path -LiteralPath $Path).Path
    $drive = $fullPath.Substring(0, 1).ToLowerInvariant()
    $rest = $fullPath.Substring(2).Replace("\", "/")
    return "/mnt/$drive$rest"
}

if (-not $UseWsl -and -not (Test-Tool $Iverilog)) {
    if (Test-Tool "wsl") {
        Write-Host "Native '$Iverilog' was not found; running the simulation through WSL."
        $UseWsl = $true
    }
}

if ($UseWsl) {
    if (-not (Test-Tool "wsl")) {
        throw "WSL was requested but 'wsl.exe' was not found."
    }

    $wslDir = Convert-To-WslPath $ScriptDir
    $cmd = "cd '$wslDir' && make sim WIDTH=$Width HEIGHT=$Height CLK_FREQ=$ClkFreq BAUD_RATE=$BaudRate"
    wsl -- bash -lc $cmd
    exit $LASTEXITCODE
}

foreach ($tool in @($Python, $Iverilog, $Vvp)) {
    if (-not (Test-Tool $tool)) {
        throw "Required command '$tool' was not found. Install Icarus Verilog, use -UseWsl, or pass the command path."
    }
}

$BuildDir = "build"
$Top = "sobel_system_tb"
$VvpOut = Join-Path $BuildDir "$Top.vvp"
$VcdOut = Join-Path $BuildDir "$Top.vcd"

if (($Width -eq 128) -and ($Height -eq 72)) {
    $InputHex = "data/input_rgb.hex"
} else {
    $InputHex = Join-Path $BuildDir "input_rgb.hex"
}

$PgmOut = Join-Path $BuildDir "sobel_out.pgm"
$InputPng = Join-Path $BuildDir "input_rgb.png"
$SobelPng = Join-Path $BuildDir "sobel_out.png"

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

& $Python tools/gen_input_rgb.py --width $Width --height $Height --output $InputHex

$rtl = @(
    "rtl/uart_rx.v",
    "rtl/image_frame_rx.v",
    "rtl/rgb_to_gray.v",
    "rtl/sobel_core.v",
    "rtl/video_stream_model.v",
    "rtl/sobel_system.v"
)

$defines = @(
    "-DIMG_WIDTH=$Width",
    "-DIMG_HEIGHT=$Height",
    "-DCLK_FREQ=$ClkFreq",
    "-DBAUD_RATE=$BaudRate",
    "-DINPUT_RGB_HEX=`"$InputHex`"",
    "-DOUTPUT_PGM=`"$PgmOut`"",
    "-DVCD_FILE=`"$VcdOut`""
)

& $Iverilog -g2005-sv @defines -o $VvpOut "tb/sobel_system_tb.v" @rtl
& $Vvp $VvpOut
& $Python tools/convert_images.py --width $Width --height $Height --input-rgb $InputHex --sobel-pgm $PgmOut --input-png $InputPng --sobel-png $SobelPng

Write-Host "Simulation finished."
Write-Host "Output image: $SobelPng"
Write-Host "Waveform: $VcdOut"
