@echo off
:: Para o filtro (o E do notebook volta).
net session >nul 2>&1
if errorlevel 1 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0e-nativo-usb-ok.ps1" -Role stop
