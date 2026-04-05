#!/usr/bin/env bash

out_file="$CMD_OUTPUT"

if [ -z "$out_file" ]; then
  "$@"
else
  "$@" | tee "$out_file"
fi

