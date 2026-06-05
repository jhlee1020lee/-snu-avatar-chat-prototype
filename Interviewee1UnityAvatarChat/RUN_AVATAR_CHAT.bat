@echo off
setlocal
cd /d "%~dp0"

set "LAUNCHER=LaunchAvatarChat.ps1"

if not exist "%LAUNCHER%" (
  echo LaunchAvatarChat.ps1 not found.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0%LAUNCHER%"
if errorlevel 1 pause
