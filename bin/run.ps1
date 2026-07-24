#!/usr/bin/env pwsh

$out_file = $env:CMD_OUTPUT

if (!$out_file) {
  # Other option
  # $cmd = $args[0]
  # $rest = $args[1..$args.Length]
  # & "$cmd" @rest

  "$args" | Invoke-Expression
} else {
  "$args" | Invoke-Expression | Tee-Object -FilePath $out_file

  # Use if above produces errors
  # Out-File -FilePath $out_file -InputObject $output -Encoding utf8NoBOM
}


