$path = $args[0]
$list = Get-Content "$PSScriptRoot\tfmove.yaml" -Raw | ConvertFrom-Yaml

if ($list.Length -gt 0) {
  foreach ($item in $list.GetEnumerator()) {
    Write-Host "Moving: $($item.old)" -ForegroundColor Green
    terraform -chdir="$path" state mv $item.old $item.new
  }
}
