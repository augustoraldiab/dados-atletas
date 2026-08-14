@echo off
:: Teclado NATIVO continua ligado, so a tecla E dele some.
:: No teclado USB a tecla E funciona.
:: Arquivo .bat + .ps1 na MESMA pasta.

net session >nul 2>&1
if errorlevel 1 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0e-nativo-usb-ok.ps1" -Role setup
