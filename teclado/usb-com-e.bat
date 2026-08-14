@echo off
:: Arquivo UNICO. Nao precisa de .ps1.
:: Desfaz o mapa da tecla E (senao o USB tambem perde o E),
:: desliga SO o teclado do notebook, deixa o USB com todas as teclas.
net session >nul 2>&1
if errorlevel 1 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$lines = Get-Content -LiteralPath '%~f0'; $n = ($lines | Select-String -Pattern '^___PS___$' | Select-Object -First 1).LineNumber; Invoke-Expression (($lines | Select-Object -Skip $n) -join [Environment]::NewLine)"
goto :eof
___PS___
function Test-IsExternalKeyboard([string]$InstanceId) {
  $id = $InstanceId
  $seen = @{}
  while ($id -and -not $seen.ContainsKey($id)) {
    $seen[$id] = $true
    if ($id -match '^(USB\\|BTHENUM\\|BTHLEDEVICE\\)') { return $true }
    $parent = (Get-PnpDeviceProperty -InstanceId $id -KeyName 'DEVPKEY_Device_Parent' -ErrorAction SilentlyContinue).Data
    if (-not $parent) { break }
    $id = $parent
  }
  return $false
}

$mapa = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout' -Name 'Scancode Map' -ErrorAction SilentlyContinue
if ($mapa) {
  Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout' -Name 'Scancode Map' -Force
  Write-Host 'Mapa da tecla E removido (ele matava o E no USB tambem).'
  $precisaReiniciar = $true
} else {
  $precisaReiniciar = $false
}

$all = @(Get-PnpDevice -Class Keyboard -ErrorAction SilentlyContinue)
Write-Host 'Teclados encontrados:'
foreach ($d in $all) {
  $tipo = if (Test-IsExternalKeyboard $d.InstanceId) { 'USB/BT' } else { 'interno' }
  Write-Host ("  [{0}] ({1}) {2}" -f $d.Status, $tipo, $d.FriendlyName)
}

$interno = @($all | Where-Object { -not (Test-IsExternalKeyboard $_.InstanceId) })
foreach ($d in $interno) {
  Write-Host ("Desabilitando interno: {0}" -f $d.FriendlyName)
  try {
    Disable-PnpDevice -InstanceId $d.InstanceId -Confirm:$false -ErrorAction Stop
    Write-Host 'OK.'
  } catch {
    Write-Host ("Aviso: {0}" -f $_.Exception.Message)
  }
}

Write-Host ''
Write-Host 'Teclado do notebook desligado. No USB a tecla E funciona.'
if ($precisaReiniciar) {
  Write-Host 'Reiniciando em 5 segundos para o E do USB voltar. Plugue o USB depois.'
  shutdown.exe /r /t 5 /c "Plugue o teclado USB depois do reboot. A tecla E vai funcionar nele."
} else {
  Write-Host 'Plugue o teclado USB agora.'
  cmd /c pause
}
