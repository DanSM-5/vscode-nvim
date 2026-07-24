#!/usr/bin/env pwsh

if (!$args) {
  $name = $MyInvocation.MyCommand.name
  Write-Output "usage: $name [--tag] FILENAME[:LINENO][:IGNORED]"
  exit 1
}

if ($args[0] -eq '--tag') {
  $tags_script = "$PSScriptRoot/tagpreview.ps1"
  $new_args = $args[1..($args.Length - 1)]
  & $tags_script @new_args
  exit $?
}

$segments = $args[0].trim("'").trim('"') -Split ':'

# Check if first item is a drive letter and offset accordingly
if (Get-PSDrive -LiteralName $segments[0] -PSProvider FileSystem -ErrorAction SilentlyContinue) {
  $FILE = ($segments[0] + ':' + $segments[1])
  $CENTER = $segments[2]
} else {
  $FILE = $segments[0]
  $CENTER = $segments[1]

  # Expand references to home directory `~`
  $FILE = if ($FILE -eq '~') { $HOME } else { $FILE }
  if ("$FILE" -like '~*') {
    $FILE = $HOME + $FILE.Substring(1)
  }
}

if (Test-Path -LiteralPath $FILE -PathType Container -ErrorAction SilentlyContinue) {
  $fullpath = (Resolve-Path -LiteralPath $FILE).Path
  Write-Output "Path: $fullpath`n"

  erd --layout inverted --color force --level 3 -I --suppress-size -- $FILE 2> $null ||
    eza -A --tree --level=3 --color=always --icons=always --dereference $FILE 2> $null ||
    Get-ChildItem -LiteralPath $FILE ||
    Write-Output "`nCannot access directory $FILE"

  exit
} elseif (!(Test-Path -LiteralPath $FILE -PathType Leaf -ErrorAction SilentlyContinue)) {
  Write-Output "File not found ${FILE}"
  exit 1
}

if (-Not $CENTER) {
  $CENTER = '0'
}

# Sometimes bat is installed as batcat.
if (Get-Command -Name 'batcat' -All -ErrorAction SilentlyContinue) {
  $BATNAME = 'batcat'
} elseif (Get-Command -Name 'bat' -All -ErrorAction SilentlyContinue) {
  $BATNAME = 'bat'
}

if ($BATNAME -and !($env:FZF_PREVIEW_COMMAND)) {
  $BAT_STYLE = if ($env:BAT_STYLE) { $env:BAT_STYLE } else { 'numbers' }
  & $BATNAME --style="$BAT_STYLE" --color=always --pager=never `
      --highlight-line="$CENTER" -- "$FILE"

  exit $?
}

# TODO: Add binary detection
# https://stackoverflow.com/questions/11698525/powershell-possible-to-determine-a-files-mime-type

$DEFAULT_COMMAND = if ($env:FZF_DEFAULT_COMMAND) {
  $env:FZF_DEFAULT_COMMAND
} else {
  "highlight -O ansi -l $FILE || coderay $FILE || rougify $FILE || Get-Content $FILE"
}

$DEFAULT_COMMAND | Invoke-Expression

