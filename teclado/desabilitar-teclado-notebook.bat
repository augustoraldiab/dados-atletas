@echo off
:: Desliga SO o teclado do notebook. Teclado USB fica inteiro, incluindo E.
net session >nul 2>&1
if errorlevel 1 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0desabilitar-teclado-notebook.ps1"
