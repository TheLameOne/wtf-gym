#!/usr/bin/env pwsh
# run_all.ps1 — launch guru_app and trainer_app simultaneously
# Requires two Android emulators running (e.g. emulator-5554 and emulator-5556).
# Usage: .\run_all.ps1

$root = $PSScriptRoot

Write-Host "Starting guru_app (member DK)..."
Start-Process powershell -ArgumentList `
    "-NoExit", "-Command", "Set-Location '$root\guru_app'; flutter pub get; flutter run"

Start-Sleep -Seconds 2   # stagger to avoid pub cache conflicts

Write-Host "Starting trainer_app (trainer Aarav)..."
Start-Process powershell -ArgumentList `
    "-NoExit", "-Command", "Set-Location '$root\trainer_app'; flutter pub get; flutter run"
