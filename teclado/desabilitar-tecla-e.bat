@echo off
:: ATENCAO: a tecla E some em TODOS os teclados, inclusive USB.
:: Prefira so-a-tecla-e.bat (religa o teclado interno e desliga so o E).
net session >nul 2>&1
if errorlevel 1 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout" /v "Scancode Map" /t REG_BINARY /d 0000000000000000020000000000120000000000 /f
if errorlevel 1 (
  echo Falhou. Clique duas vezes de novo e aceite o UAC.
  pause
  exit /b 1
)
shutdown /r /t 5 /c "Tecla E desabilitada. Reiniciando..."
