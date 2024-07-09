# Import module
Write-Output "Importing module"
# Note: Import-Module path may need to be changed if pihome is not the default location
Import-Module -Name 'C:\Program Files (x86)\PIPC\OSIsoft.PowerShell'
Get-Command -Module OSIsoft.PowerShell

# Run script
Write-Output "Running script GetData.ps1"
$FileSuffix = (Get-Date -Format "yyyy-MM-dd-HH-mm-ss")
.\GetData.ps1 -FileSuffix $FileSuffix

# Verify results
Write-Output "Verifying results"
try {
    $PIData = Import-Csv -Path (".\cds_data." + $FileSuffix + ".csv")
} catch {
    Write-Output ("Unable to find file " + "cds_data." + $FileSuffix + ".csv")
    exit 1
}
try {
    $CdsData = Import-Csv -Path (".\pi_data." + $FileSuffix + ".csv")
} catch {
    Write-Output ("Unable to find file " + "pi_data." + $FileSuffix + ".csv")
    exit 1
}

# Define a maximum difference threshold for comparing floating point values
$Threshold =  0.001

# Check that the files were found
if ($null -eq $PIData -and $null -eq $CdsData) {
    Write-Output "Neither dataset was found!"
    exit 1
}

if ($null -eq $PIData) {
    Write-Output "PI dataset was not found!"
    exit 1
}

if ($null -eq $CdsData) {
    Write-Output "Cds dataset was not found!"
    exit 1
}

# Check that they are the same length
if ($PIData.Count -ne $CdsData.Count) {
    Write-Output "Datasets are not the same length!"
    Write-Output "PI Count: " + $PIData.Count
    Write-Output "Cds Count: " + $CdsData.Count
    exit 1
}

# Check that they are not of zero length (no data)
if ($PIData.Count -eq 0) {
    Write-Output "The datasets are of zero length"
    exit 1
}

# Check that the data in both datasets matches
for ($i = 0; $i -lt $PIData.Count; $i++) {
    if ($PIData[$i].TimeStamp -ne $CdsData[$i].TimeStamp) {
        Write-Output "Timestamp mismatch!"
        Write-Output "Index: " + $i
        Write-Output "PI Timestamp: " + $PIData[$i].TimeStamp
        Write-Output "Cds Timestamp: " + $CdsData[$i].TimeStamp
        exit 1
    }

    # Determine if the value is numeric
    $NumericData = $False
    try {
        if ($null -ne [float]::Parse($PIData[$i].Value)) {
            $NumericData = $True
        }
    } catch {}


    if ($NumericData) {
        if ([Math]::Abs([float]::Parse($PIData[$i].Value) - [float]::Parse($CdsData[$i].Value)) -gt $Threshold) {
            Write-Output "Value mismatch!"
            Write-Output "Index: " + $i
            Write-Output "PI Data: " + $PIData[$i].Value
            Write-Output "Cds Data: " + $CdsData[$i].Value
            exit 1
        }
    } else {
        if ($PIData[$i].Value -ne $CdsData[$i].Value) {
            Write-Output "Value mismatch!"
            Write-Output "Index: " + $i
            Write-Output "PI Data: " + $PIData[$i].Value
            Write-Output "Cds Data: " + $CdsData[$i].Value
            exit 1
        }
    }
}

Write-Output "Tests complete! No mismatches detected!"