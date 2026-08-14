@echo off
:: Botao direito -> Executar como administrador.
:: Desliga SO o teclado do notebook. Teclado USB fica inteiro, incluindo E.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0desabilitar-teclado-notebook.ps1"
if errorlevel 1 (
  echo Rode como administrador: botao direito neste arquivo.
  pause
)
