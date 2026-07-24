#!/usr/bin/env pwsh

if (!$args) {
  $name = $MyInvocation.MyCommand.name
  Write-Error "usage: $name FILENAME:TAGFILE:EXCMD"
  exit 1
}

if (($args.Length -eq 1) -and (Test-Path -LiteralPath $args[0] -PathType Leaf -ErrorAction SilentlyContinue)) {
  # Get arguments from file to avoid quote and expansion issues
  $segments = (Get-Content $args[0]) -split "`t"
  $segments = $segments[1..($segments.Length - 1)]
} else {
  # Regular arguments

  $args_srg = @"
  $args
"@

  $segments = $args_srg.trim() -Split ':'
}

function Expand-Tilda ([string] $ExpandPath) {
  # Expand references to home directory `~`
  $ExpandPath = if ($ExpandPath -eq '~') { $HOME } else { $ExpandPath }
  if ($ExpandPath -like '~*') {
    $ExpandPath = $HOME + $ExpandPath.Substring(1)
  }

  return $ExpandPath
}

# Check if second item is a drive letter and offset accordingly
if (Get-PSDrive -LiteralName $segments[1] -PSProvider FileSystem -ErrorAction SilentlyContinue) {
  $FILE = $segments[0]
  $TAGFILE = ($segments[1] + ':' + $segments[2])
  $EXCMD = $segments[3]
} else {
  $FILE = $segments[0]
  $TAGFILE = $segments[1]
  $EXCMD = $segments[2]
}

$FILE = Expand-Tilda $FILE
$TAGFILE = Expand-Tilda $TAGFILE

# Complete file paths which are relative to the given tag file
# If FILE does not contain a colon ':', it is likely not an absolute path
if (!($FILE -like '*:*')) {
  # if [ "${FILE:0:1}" != "/" ]; then
  #   FILE="$(dirname "${TAGFILE}")/${FILE}"
  # fi
  $FILE = [IO.Path]::GetDirectoryName($TAGFILE) + "/$FILE"
}

if (!(Test-Path -LiteralPath $FILE -PathType Leaf -ErrorAction SilentlyContinue)) {
  Write-Error "File not found $FILE"
  exit 1
}

$VIMNAME = ''

if (Get-Command -Name 'vim' -ErrorAction SilentlyContinue) {
  $VIMNAME = 'vim'
} elseif (Get-Command -Name 'nvim' -ErrorAction SilentlyContinue) {
  $VIMNAME = 'nvim'
} else {
  Write-Error 'Connot preview tag: vim or nvim unavailable'
  exit 1
}

# NOTE: This does not return anything using windows powershell
# You can try in interactive shell this sample
# nvim -R -i NONE -u NONE -e -m -s $HOME/scoop/apps/neovim/current/share/nvim/runtime/doc/change.txt -c "set nomagic" -c "silent /*!*" -c 'let l=line(".") | new | put =l | print | qa!'

$CENTER = & $VIMNAME -R -i NONE -u NONE -e -m -s $FILE `
          -c 'set nomagic' `
          -c ('silent '+$EXCMD) `
          -c 'let l=line(".") | new | put =l | print | qa!'

try {
  $CENTER = [int]$CENTER
} catch {
  Write-Error "Invalid center: $CENTER"
  exit 1
}

[int]$START_LINE = $CENTER - $env:FZF_PREVIEW_LINES / 2
if ($START_LINE -le 0) {
  $START_LINE = 1
}
[int]$END_LINE = $START_LINE + $env:FZF_PREVIEW_LINES - 1

$BATNAME = ''

if (Get-Command -Name 'batcat' -ErrorAction SilentlyContinue) {
  $BATNAME = 'batcat'
} elseif (Get-Command -Name 'bat' -ErrorAction SilentlyContinue) {
  $BATNAME = 'bat'
}

if (Get-Command -Name $BATNAME -ErrorAction SilentlyContinue) {
  $BAT_STYLE = if ($env:BAT_STYLE) { $env:BAT_STYLE } else { 'numbers' }
  & $BATNAME --style="$BAT_STYLE" `
             --color=always `
             --pager=never `
             --wrap=never `
             --terminal-width="$env:FZF_PREVIEW_COLUMNS" `
             --line-range="${START_LINE}:${END_LINE}" `
             --highlight-line="$CENTER" `
             --language vimhelp `
             $FILE

  exit $?
}

# Using built-ins
$START_LINE = if ($START_LINE -eq 1) { 0 } else { $START_LINE - 1 }
$REVERSE = "$([char]27)[7m"
$RESET = "$([char]27)[27m"

# Line to highlight
$line_highlight = Get-Content -LiteralPath $FILE | Select-Object -Index ($CENTER - 1)
# Get lines for preview, highlight matching line
Get-Content -LiteralPath $FILE | Select-Object -Index ($START_LINE..$END_LINE) |
  ForEach-Object {
    if ($_ -eq $line_highlight) {
      return Write-Output "${REVERSE}${line_highlight}${RESET}"
    }

    return $_
  }
