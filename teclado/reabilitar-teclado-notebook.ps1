#Requires -RunAsAdministrator
# Liga de novo o teclado interno do notebook.

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

Get-PnpDevice -Class Keyboard -ErrorAction SilentlyContinue |
  Where-Object { -not (Test-IsExternalKeyboard $_.InstanceId) } |
  ForEach-Object {
    Write-Host ("Habilitando: {0}" -f $_.FriendlyName)
    try {
      Enable-PnpDevice -InstanceId $_.InstanceId -Confirm:$false -ErrorAction Stop
    } catch {
      Write-Host ("Falhou: {0}" -f $_.Exception.Message)
    }
  }

Write-Host 'Teclado do notebook religado (a tecla E presa pode voltar).'
pause
