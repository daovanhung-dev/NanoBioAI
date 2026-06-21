#!/usr/bin/env bash

CODEX_SKIPPED_STEPS=()

write_codex_step() {
  printf '\n==> %s\n' "$1"
}

add_codex_skipped_step() {
  local step="$1"
  local reason="$2"
  local message="SKIPPED: ${step} - ${reason}"
  CODEX_SKIPPED_STEPS+=("$message")
  printf '%s\n' "$message"
}

invoke_native_command() {
  local step="$1"
  shift
  write_codex_step "$step"
  printf 'Command:'
  printf ' %q' "$@"
  printf '\n'

  set +e
  "$@"
  local exit_code=$?
  set -e

  if [[ "$exit_code" -ne 0 ]]; then
    {
      printf 'FAILED: %s\n' "$step"
      printf 'Command:'
      printf ' %q' "$@"
      printf '\nExit code: %s\n' "$exit_code"
    } >&2
    exit "$exit_code"
  fi
}

complete_codex_check() {
  local name="$1"
  printf '\n'
  if [[ "${#CODEX_SKIPPED_STEPS[@]}" -gt 0 ]]; then
    printf '%s COMPLETED WITH SKIPPED STEPS\n' "$name"
    printf '%s\n' "${CODEX_SKIPPED_STEPS[@]}"
  else
    printf '%s PASSED\n' "$name"
  fi
}
