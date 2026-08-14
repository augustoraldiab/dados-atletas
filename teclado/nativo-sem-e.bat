@echo off
:: Religa o teclado NATIVO do notebook e desliga SO a tecla E.
:: As outras teclas do notebook continuam. O E some tambem no USB.
:: Arquivo unico, sem .ps1. Clique duas vezes; reinicia em 5 segundos.

net session >nul 2>&1
if errorlevel 1 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-PnpDevice -Class Keyboard -ErrorAction SilentlyContinue | ForEach-Object { try { Enable-PnpDevice -InstanceId $_.InstanceId -Confirm:$false -ErrorAction Stop } catch {} }"

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout" /v "Scancode Map" /t REG_BINARY /d 0000000000000000020000000000120000000000 /f
if errorlevel 1 (
  echo Falhou. Feche e clique duas vezes de novo; aceite o UAC.
  pause
  exit /b 1
)

echo Teclado nativo religado. Tecla E desligada. Reiniciando...
shutdown /r /t 5 /c "Tecla E desabilitada. Teclado nativo permanece. Reiniciando..."
