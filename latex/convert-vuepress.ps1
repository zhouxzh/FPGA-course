$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

$utf8 = New-Object System.Text.UTF8Encoding($false)
$generatedMarkdownDir = Join-Path $scriptDir 'generated-markdown'
$generatedMermaidDir = Join-Path $scriptDir 'generated-mermaid'
$pandocResourcePath = '../src/book;.'

$documentJobs = @(
	@{ Input = '../src/book/README.md'; Temp = 'generated-markdown/README.md'; Output = 'chapters/preface.tex'; Stem = 'preface'; UseLuaFilter = $true },
	@{ Input = '../src/book/chapter1.md'; Temp = 'generated-markdown/chapter1.md'; Output = 'chapters/chapter1.tex'; Stem = 'chapter1'; UseLuaFilter = $false },
	@{ Input = '../src/book/chapter2.md'; Temp = 'generated-markdown/chapter2.md'; Output = 'chapters/chapter2.tex'; Stem = 'chapter2'; UseLuaFilter = $false },
	@{ Input = '../src/book/chapter3.md'; Temp = 'generated-markdown/chapter3.md'; Output = 'chapters/chapter3.tex'; Stem = 'chapter3'; UseLuaFilter = $false },
	@{ Input = '../src/book/chapter4.md'; Temp = 'generated-markdown/chapter4.md'; Output = 'chapters/chapter4.tex'; Stem = 'chapter4'; UseLuaFilter = $false },
	@{ Input = '../src/book/chapter5.md'; Temp = 'generated-markdown/chapter5.md'; Output = 'chapters/chapter5.tex'; Stem = 'chapter5'; UseLuaFilter = $false },
	@{ Input = '../src/book/chapter6.md'; Temp = 'generated-markdown/chapter6.md'; Output = 'chapters/chapter6.tex'; Stem = 'chapter6'; UseLuaFilter = $false },
	@{ Input = '../src/book/chapter7.md'; Temp = 'generated-markdown/chapter7.md'; Output = 'chapters/chapter7.tex'; Stem = 'chapter7'; UseLuaFilter = $false },
	@{ Input = '../src/book/chapter8.md'; Temp = 'generated-markdown/chapter8.md'; Output = 'chapters/chapter8.tex'; Stem = 'chapter8'; UseLuaFilter = $false },
	@{ Input = '../src/book/chapter9.md'; Temp = 'generated-markdown/chapter9.md'; Output = 'chapters/chapter9.tex'; Stem = 'chapter9'; UseLuaFilter = $false }
)

function Reset-GeneratedDirectory {
	param(
		[string]$Path
	)

	if (Test-Path $Path) {
		Get-ChildItem $Path -Force | Remove-Item -Recurse -Force
	} else {
		New-Item -ItemType Directory -Path $Path | Out-Null
	}
}

function Invoke-CommandOrThrow {
	param(
		[string]$FilePath,
		[string[]]$ArgumentList
	)

	& $FilePath @ArgumentList
	if ($LASTEXITCODE -ne 0) {
		throw "Command failed: $FilePath $($ArgumentList -join ' ')"
	}
}

function Convert-MermaidBlocks {
	param(
		[string]$SourcePath,
		[string]$TempPath,
		[string]$Stem
	)

	$content = [System.IO.File]::ReadAllText((Resolve-Path $SourcePath), $utf8)
	$diagramIndex = [ref]0
	$pattern = '(?ms)^[ \t]*```mermaid[^\r\n]*\r?\n(?<Diagram>.*?)^[ \t]*```[ \t]*\r?\n?'
	$rewritten = [regex]::Replace($content, $pattern, {
		param($match)

		$diagramIndex.Value += 1
		$diagramName = '{0}-mermaid-{1}' -f $Stem, $diagramIndex.Value
		$diagramSourcePath = Join-Path $generatedMermaidDir ($diagramName + '.mmd')
		$diagramImagePath = Join-Path $generatedMermaidDir ($diagramName + '.png')
		$diagramCode = $match.Groups['Diagram'].Value.TrimEnd("`r", "`n") + [Environment]::NewLine

		[System.IO.File]::WriteAllText($diagramSourcePath, $diagramCode, $utf8)
		Invoke-CommandOrThrow 'pnpm' @('exec', 'mmdc', '-q', '-i', $diagramSourcePath, '-o', $diagramImagePath)

		return [Environment]::NewLine + '![Mermaid Diagram](generated-mermaid/' + ($diagramName + '.png') + ')' + [Environment]::NewLine + [Environment]::NewLine
	})

	[System.IO.File]::WriteAllText((Join-Path $scriptDir $TempPath), $rewritten, $utf8)
}

Reset-GeneratedDirectory $generatedMarkdownDir
Reset-GeneratedDirectory $generatedMermaidDir

foreach ($job in $documentJobs) {
	Convert-MermaidBlocks -SourcePath $job.Input -TempPath $job.Temp -Stem $job.Stem

	$pandocArgs = @(
		'-f', 'markdown',
		$job.Temp,
		'--top-level-division=chapter',
		'--syntax-highlighting=idiomatic',
		'-t', 'latex',
		'--extract-media=chapters/',
		"--resource-path=$pandocResourcePath",
		'-o', $job.Output
	)

	if ($job.UseLuaFilter) {
		$pandocArgs += '--lua-filter=remove-numbering.lua'
	}

	Invoke-CommandOrThrow 'pandoc' $pandocArgs
}

Get-ChildItem chapters/chapter*.tex | ForEach-Object {
	$content = [System.IO.File]::ReadAllText($_.FullName, $utf8)
	$content = [regex]::Replace(
		$content,
		'\\pandocbounded\{\\includegraphics\[keepaspectratio,alt=\{Mermaid Diagram\}\]\{([^}]+generated-mermaid/[^}]+)\}\}',
		'\pandocbounded{\includegraphics[width=\linewidth,height=0.82\textheight,keepaspectratio,alt={Mermaid Diagram}]{$1}}'
	)
	$content = [regex]::Replace($content, '(\\pandocbounded\{.*?\})(\\\\)(\r?\n)', '$1$3')
	[System.IO.File]::WriteAllText($_.FullName, $content, $utf8)
}

Invoke-CommandOrThrow 'latexmk' @('-xelatex', '-interaction=nonstopmode', '-file-line-error', '-synctex=1', '-halt-on-error', 'FPGA.tex')
