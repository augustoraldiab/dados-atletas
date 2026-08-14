@echo off
:: Botao direito -> Executar como administrador.
:: Liga de novo o teclado interno do notebook.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0reabilitar-teclado-notebook.ps1"
