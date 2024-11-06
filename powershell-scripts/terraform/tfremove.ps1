$path = $args[0]
$removeItems = (
  'module.st_asuhfbaweuibfwino.azurerm_monitor_diagnostic_setting.this["blob"]',
  'module.st_asuhfbaweuibfwino.azurerm_monitor_diagnostic_setting.this["file"]',
  'module.st_asuhfbaweuibfwino.azurerm_monitor_diagnostic_setting.this["queue"]',
  'module.st_asuhfbaweuibfwino.azurerm_monitor_diagnostic_setting.this["table"]',
  'module.st_funcimmonitoring.azurerm_monitor_diagnostic_setting.this["blob"]',
  'module.st_funcimmonitoring.azurerm_monitor_diagnostic_setting.this["file"]',
  'module.st_funcimmonitoring.azurerm_monitor_diagnostic_setting.this["queue"]',
  'module.st_funcimmonitoring.azurerm_monitor_diagnostic_setting.this["table"]',
  'module.st_monitor_logs.azurerm_monitor_diagnostic_setting.this["blob"]',
  'module.st_monitor_logs.azurerm_monitor_diagnostic_setting.this["file"]',
  'module.st_monitor_logs.azurerm_monitor_diagnostic_setting.this["queue"]',
  'module.st_monitor_logs.azurerm_monitor_diagnostic_setting.this["table"]'
)

if ($removeItems.Length -gt 0) {
  foreach ($item in $removeItems) {
    Write-Host "Removing: $($item)" -ForegroundColor Green
    terraform -chdir="$path" state rm $item
  }
}
