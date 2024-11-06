$path = $args[0]
$tfplan = terraform -chdir="$path" plan -no-color

[string[]]$strArr = $tfplan

[string[]]$createArr = @()
[string[]]$destroyArr = @()
[string[]]$replaceArr = @()
[string[]]$updateArr = @()

foreach ($line in $strArr) {
  if ($line -like "*will be created*") {
    $createArr += ($line.Replace(" # ", "")).Split(" ")[1]
  }
  elseif ($line -like "*will be destroyed*") {
    $destroyArr += $line.Replace(" # ", "").Split(" ")[1]
  }
  elseif ($line -like "*must be replaced*") {
    $replaceArr += $line.Replace(" # ", "").Split(" ")[1]
  }
  elseif ($line -like "*will be updated in-place*") {
    $updateArr += $line.Replace(" # ", "").Split(" ")[1]
  }
}
$numberOfChanges = $createArr.Length + $destroyArr.Length + $replaceArr.Length + $updateArr.Length

if ($createArr.Length -gt 0) {
  Write-Host ""
  Write-Host "The following resources will be created" -ForegroundColor "green"
  $createArr
}

if ($destroyArr.Length -gt 0) {
  Write-Host ""
  Write-Host "The following resources will be destroyed" -ForegroundColor "red"
  $destroyArr
}

if ($replaceArr.Length -gt 0) {
  Write-Host ""
  Write-Host "The following resources will be replaced" -ForegroundColor "magenta"
  $replaceArr
}

if ($updateArr.Length -gt 0) {
  Write-Host ""
  Write-Host "The following resources will be updated" -ForegroundColor "yellow"
  $updateArr
}

if ($numberOfChanges -eq 0) {
  Write-Host ""
  Write-Host "No changes. Your infrastructure matches the configuration." -ForegroundColor "green"
}
Write-Host ""