<#
.SYNOPSIS
  Displays a summarized Terraform plan for all Terraform subfolders in the specified path.
.DESCRIPTION
  This script recursively searches for Terraform subfolders within a specified root folder that contain a specific file (e.g., 'common.tf').
  For each valid subfolder, it initializes Terraform, generates a plan, and outputs a summary of the planned changes.
  The summary includes resources to be created, destroyed, replaced, or updated, and handles both errors and warnings.
  The output is color-coded for better readability.
.PARAMETER rootFolderPath
  The root folder path where the Terraform subfolders are located.
.PARAMETER fileThatNeedsToExistInFolder
  The file that must exist in a subfolder for it to be processed (e.g., 'common.tf').
#>

param(
  $rootFolderPath,
  $fileThatNeedsToExistInFolder
)

$ErrorActionPreference = 'Continue'

# Only get folders that contain the file defined in $fileThatNeedsToExistInFolder
$stacks = Get-ChildItem -Directory -Path $rootFolderPath
Where-Object { $_.FullName -notlike '*\.*' }
Where-Object { $_.GetFiles($fileThatNeedsToExistInFolder).Count -gt 0 }

# Loop through each subfolder, initialize Terraform, generate a plan, and write a summary of changes
$stacks | ForEach-Object -Parallel {

  # Variables
  $stack = $_
  $red = "`e[38;5;1m"
  $white = "`e[0m"
  $green = "`e[38;5;2m"
  $orange = "`e[38;5;3m"
  $whiteOnBlue = "`e[48;5;27m"

  # Set the current location to the Terraform subfolder
  Set-Location $stack.FullName

  # Remove the .terraform folder if it exists
  if (Test-Path('./.terraform')) { Remove-Item -Recurse -Force -Path './.terraform' }

  # Create a terraform plan file as json
  terraform init -lock=false -no-color >/dev/null
  terraform plan -lock=false -no-color --out="./plan.txt" >/dev/null
  terraform show -json './plan.txt' > './plan.json'

  # Create a custom object from the json plan file
  $obj = Get-Content './plan.json' |  ConvertFrom-Json

  # Write Errors and Warnings and continue to the next stack if there are errors
  if ($obj.diagnostics) {
    foreach ($diag in $obj.diagnostics) {
      if ($diag.severity -eq 'error') {
        Write-Output "$($whiteOnBlue) $($stack.name) $($White)"
        Write-Output "$($Red) $($stack.Name): $($_.Exception.Message) $($White)"
        Write-Output "$($Red) Error: $($diag.summary) $($White)"
        Write-Output $diag.detail
      }
      elseif ($diag.severity -eq 'warning') {
        Write-Output "$($whiteOnBlue) $($stack.name) $($White)"
        Write-Output "$($orange) Warning: $($diag.summary) $($White)"
        Write-Output $diag.detail
      }
    }
    if ($obj.errored) {
      continue
    }
  }

  # Filter out resources with no changes
  $selection = @(
    @{n = 'Name'; e = { $_.address } }
    @{n = 'Action'; e = { $_.change.actions } }
  )
  $filteredChanges = $obj.resource_changes | Select-Object $selection | Where-Object { $_.Action -ne 'no-op' } | Sort-Object Name | Format-Table -AutoSize

  # Write changes
  if ($filteredChanges.length -eq 0) {
    Write-Output "$($whiteOnBlue) $($stack.name) $($White)"
    Write-Output "$($green) No changes detected $($White)"
    Write-Output ' '
  }
  else {
    Write-Output "$($whiteOnBlue) $($stack.name) $($White)"
    $filteredChanges | Format-Table -AutoSize
    Write-Output ' '
  }
} -ThrottleLimit 20

Write-Output "$($W)$($stack.name): No changes detected $($White)"