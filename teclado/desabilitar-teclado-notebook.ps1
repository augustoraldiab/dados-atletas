#Requires -RunAsAdministrator
# Desliga o teclado INTERNO do notebook. USB e Bluetooth continuam,
# inclusive a tecla E. Nao usa Scancode Map (esse mata o E em todos).

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

$all = @(Get-PnpDevice -Class Keyboard -ErrorAction SilentlyContinue)
Write-Host 'Teclados encontrados:'
foreach ($d in $all) {
  $tipo = if (Test-IsExternalKeyboard $d.InstanceId) { 'USB/BT' } else { 'interno' }
  Write-Host ("  [{0}] ({1}) {2}" -f $d.Status, $tipo, $d.FriendlyName)
}

$interno = @($all | Where-Object { -not (Test-IsExternalKeyboard $_.InstanceId) })
if ($interno.Count -eq 0) {
  Write-Host ''
  Write-Host 'Nao achei teclado interno automaticamente.'
  Write-Host 'No Gerenciador de Dispositivos > Teclados, desabilite o que NAO for o USB.'
  pause
  exit 1
}

$falhou = $false
foreach ($d in $interno) {
  Write-Host ''
  Write-Host ("Desabilitando: {0}" -f $d.FriendlyName)
  try {
    Disable-PnpDevice -InstanceId $d.InstanceId -Confirm:$false -ErrorAction Stop
    Write-Host 'OK.'
  } catch {
    $falhou = $true
    Write-Host ("Falhou: {0}" -f $_.Exception.Message)
  }
}

Write-Host ''
if ($falhou) {
  Write-Host 'Algo falhou. Desabilite manualmente: botao direito no Iniciar > Gerenciador de Dispositivos > Teclados.'
} else {
  Write-Host 'Teclado do notebook desligado. No USB a tecla E funciona.'
}
pause
