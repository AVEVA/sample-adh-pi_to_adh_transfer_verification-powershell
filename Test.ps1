# Import module
Write-Output "Importing module"
# Note: Import-Module path may need to be changed if pihome is not the default location
Import-Module -Name 'C:\Program Files (x86)\PIPC\OSIsoft.PowerShell'
Get-Command -Module OSIsoft.PowerShell

#Run script
Write-Output "Running script GetData.ps1"
.\GetData.ps1

# Verify results
Write-Output "Verifying results"
$PIData = Import-Csv -Path .\pi_data.csv
$ADHData = Import-Csv -Path .\adh_data.csv

# Check that the files were found
if ($null -eq $PIData -and $null -eq $ADHData) {
    Write-Output "Neither dataset was found!"
    exit 1
}

if ($null -eq $PIData) {
    Write-Output "PI dataset was not found!"
    exit 1
}

if ($null -eq $ADHData) {
    Write-Output "ADH dataset was not found!"
    exit 1
}

# Check that they are the same length
if ($PIData.Count -ne $ADHData.Count) {
    Write-Output "Datasets are not the same length!"
    Write-Output "PI Count: " + $PIData.Count
    Write-Output "ADH Count: " + $ADHData.Count
    exit 1
}

# Check that the data in both datasets matches
0..($PIData.Count-1) | % {
    if ($PIData[$i].TimeStamp -ne $ADHData[$i].TimeStamp) {
        Write-Output "Timestamp mismatch!"
        Write-Output "Index: " + $i
        Write-Output "PI Timestamp: " + $PIData[$i].TimeStamp
        Write-Output "ADH Timestamp: " + $ADHData[$i].TimeStamp
        exit 1
    }
    if ([float]::Parse($PIData[$i].Value) -ne [float]::Parse($ADHData[$i].Value)) {
        Write-Output "Value mismatch!"
        Write-Output "Index: " + $i
        Write-Output "PI Data: " + $PIData[$i].Value
        Write-Output "ADH Data: " + $ADHData[$i].Value
        exit 1
    }
}
