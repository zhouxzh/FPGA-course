$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

$latexmk = Get-Command latexmk -ErrorAction SilentlyContinue
if ($latexmk) {
    latexmk -xelatex -interaction=nonstopmode -file-line-error -synctex=1 -halt-on-error chapter2.tex
    if ($LASTEXITCODE -ne 0) {
        throw "latexmk build failed"
    }
    exit 0
}

$xelatex = Get-Command xelatex -ErrorAction SilentlyContinue
if (-not $xelatex) {
    throw "Neither latexmk nor xelatex was found in PATH."
}

for ($pass = 1; $pass -le 2; $pass++) {
    xelatex -interaction=nonstopmode -file-line-error -synctex=1 -halt-on-error chapter2.tex
    if ($LASTEXITCODE -ne 0) {
        throw "xelatex build failed on pass $pass"
    }
}
