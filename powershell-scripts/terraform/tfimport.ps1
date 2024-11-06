$path = $args[0]
$list = Get-Content "$PSScriptRoot\tfimport.yaml" -Raw | ConvertFrom-Yaml

if ($list.Length -gt 0) {
  foreach ($item in $list) {
    Write-Host "Importing: $($item.name)" -ForegroundColor Green
    terraform -chdir="$path" import $item.name $item.id
  }
}
