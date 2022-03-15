# Import module
Write-Output "Importing module"
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
if ($null -eq $PIData -or $null -eq $ADHData) {
    Write-Output "One or both datasets were not found!"
    exit 1
}

# Check that they are the same length
if ($PIData.Count -ne $ADHData.Count) {
    Write-Output "Datasets are not the same length!"
    exit 1
}

# Check that the data in both datasets matches
for ($i = 0; $i -lt $PIData.Count; $i++) {
    if ($PIData[$i].TimeStamp -ne $ADHData[$i].TimeStamp) {
        Write-Output "Timestamp mismatch!"
        $i
        $PIData[$i].TimeStamp
        $ADHData[$i].TimeStamp
        exit 1
    }
    if ([float]::Parse($PIData[$i].Value) -ne [float]::Parse($ADHData[$i].Value)) {
        Write-Output "Value mismatch!"
        $i
        $PIData[$i].Value
        $ADHData[$i].Value
        exit 1
    }
}
