param(
    [int]$Width = 128,
    [int]$Height = 72,
    [int]$ClkFreq = 12000000,
    [int]$BaudRate = 1000000,
    [string]$Python = "python",
    [string]$Iverilog = "C:\iverilog\bin\iverilog.exe",
    [string]$Vvp = "C:\iverilog\bin\vvp.exe"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

function Test-Tool {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Invoke-External {
    param(
        [string]$Description,
        [scriptblock]$Command
    )

    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Description failed with exit code $LASTEXITCODE."
    }
}

function Convert-ToVerilogPath {
    param([string]$Path)
    return $Path -replace '\\', '/'
}

$IverilogDir = Split-Path -Parent $Iverilog
$IvlDir = Join-Path (Split-Path -Parent $IverilogDir) "lib\ivl"

foreach ($tool in @($Python, $Iverilog, $Vvp)) {
    if (-not (Test-Tool $tool)) {
        throw "Required command '$tool' was not found. Install Icarus Verilog or pass the command path with -Iverilog/-Vvp."
    }
}

$env:Path = "$IverilogDir;$env:Path"

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

$InputHexDefine = Convert-ToVerilogPath $InputHex
$PgmOutDefine = Convert-ToVerilogPath $PgmOut
$VcdOutDefine = Convert-ToVerilogPath $VcdOut

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

Invoke-External "Input generation" {
    & $Python tools/gen_input_rgb.py --width $Width --height $Height --output $InputHex
}

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
    "-DINPUT_RGB_HEX=\`"$InputHexDefine\`"",
    "-DOUTPUT_PGM=\`"$PgmOutDefine\`"",
    "-DVCD_FILE=\`"$VcdOutDefine\`""
)

Invoke-External "Verilog compilation" {
    & $Iverilog -B $IvlDir -g2005-sv @defines -o $VvpOut "tb/sobel_system_tb.v" @rtl
}

Invoke-External "Simulation" {
    & $Vvp -M $IvlDir $VvpOut
}

Invoke-External "Image conversion" {
    & $Python tools/convert_images.py --width $Width --height $Height --input-rgb $InputHex --sobel-pgm $PgmOut --input-png $InputPng --sobel-png $SobelPng
}

Write-Host "Simulation finished."
Write-Host "Output image: $SobelPng"
Write-Host "Waveform: $VcdOut"
