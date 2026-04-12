$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

xelatex -interaction=nonstopmode -halt-on-error chapter5.tex
if ($LASTEXITCODE -ne 0) {
    throw "xelatex build failed"
}

xelatex -interaction=nonstopmode -halt-on-error chapter5.tex
if ($LASTEXITCODE -ne 0) {
    throw "xelatex build failed"
}