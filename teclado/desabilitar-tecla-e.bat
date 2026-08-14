@echo off
:: ATENCAO: a tecla E some em TODOS os teclados, inclusive USB.
:: Se for usar teclado externo, use desabilitar-teclado-notebook.bat
:: Rode como Administrador. O notebook reinicia sozinho.

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout" /v "Scancode Map" /t REG_BINARY /d 0000000000000000020000000000120000000000 /f
if errorlevel 1 (
  echo Falhou. Clique com o botao direito neste arquivo e escolha Executar como administrador.
  pause
  exit /b 1
)
shutdown /r /t 5 /c "Tecla E desabilitada. Reiniciando..."
