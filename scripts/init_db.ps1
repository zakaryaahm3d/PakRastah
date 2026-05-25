# init_db.ps1 — PowerShell shim for init_db.sh
# Requires Git Bash on PATH (ships with Git for Windows).
$ProjectDir = Split-Path -Parent $PSScriptRoot
& "bash" "$PSScriptRoot\init_db.sh"
