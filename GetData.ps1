Write-Output "Starting"
Import-Module -Name 'C:\Program Files (x86)\PIPC\OSIsoft.PowerShell' -Verbose
Get-Command -Module OSIsoft.PowerShell
Get-Module

# Get needed variables
Write-Output "Reading appsettings"
$Appsettings = Get-Content -Path appsettings.json | ConvertFrom-Json
$TenantId = $Appsettings.TenantId
$NamespaceId = $Appsettings.NamespaceId
$ApiVersion = $Appsettings.ApiVersion
$Resource = $Appsettings.Resource
$ClientId = $Appsettings.ClientId
$ClientSecret = $Appsettings.ClientSecret
$PointId = $Appsettings.PointId
$StreamId = $Appsettings.StreamId
$StartIndex = $Appsettings.StartIndex
$EndIndex = $Appsettings.EndIndex
$DataArchiveName = $Appsettings.DataArchiveName
$Username = $Appsettings.Username

Function Get-ADHToken($TenantId, $Resource, $ClientId, $ClientSecret) {
    # Get the authentication endpoint from the discovery URL
    $DiscoveryUrlRequest = Invoke-WebRequest -Uri ($Resource + "/identity/.well-known/openid-configuration") -Method Get -UseBasicParsing
    $DiscoveryBody = $DiscoveryUrlRequest.Content | ConvertFrom-Json
    $TokenUrl = $DiscoveryBody.token_endpoint

    # Use the client ID and Secret to get the needed bearer token
    $TokenForm = @{
        client_id = $ClientId
        client_secret = $ClientSecret
        grant_type = "client_credentials"
    }

    $TokenRequest = Invoke-WebRequest -Uri $TokenUrl -Body $TokenForm -Method Post -ContentType "application/x-www-form-urlencoded" -UseBasicParsing
    $TokenBody = $TokenRequest.Content | ConvertFrom-Json

    Return $TokenBody.access_token
}

Function ProcessDataset($Dataset, $Round) {
    for ($i = 0; $i -lt $Dataset.Count; $i++) {
        # Parse the timestamp if it is a string
        if ($Dataset[$i].TimeStamp.GetType().Name -eq "String") {
            $Dataset[$i].TimeStamp = [datetime]::Parse($Dataset[$i].TimeStamp)
        }

        # Convert the timestamp to universal time
        $Dataset[$i].TimeStamp = $Dataset[$i].TimeStamp.ToUniversalTime()

        # If the value is a float then round to 5 digits
        if ($Round) {
            $Dataset[$i].Value = [math]::round($Dataset[$i].Value, 5)
        }
    }

    Return $Dataset
}

# Create connection to PI Data Archive
Write-Output "Connecting to PI Data Archive"
if ($null -eq $Username) {
    $Password = ConvertTo-SecureString -String $Appsettings.Password
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $Password
    $Con = Connect-PIDataArchive -PIDataArchiveMachineName $DataArchiveName -WindowsCredential $Credential
} else {
    $Con = Connect-PIDataArchive -PIDataArchiveMachineName $DataArchiveName
}

# Get PI Point configuration
$PIpoint = Get-PIPoint -ID $PointId -AllAttributes -Connection $Con
$Type = $PIpoint.Attributes.pointtype
$Round = $false

if ($Type -eq "Float16" -or $Type -eq "Float32" -or $Type -eq "Float64") {
    $Round = $true
}

# Create an auth header
Write-Output "Retrieving token"
$AuthHeader = @{
    Authorization = "Bearer " + (Get-ADHToken -TenantId $TenantId -Resource $Resource -ClientId $ClientId -ClientSecret $ClientSecret)
}

# Retrieve data from ADH
Write-Output "Retrieving data from ADH"
$BaseUrl = $Resource + "/api/" + $ApiVersion + "/Tenants/" + $TenantId + "/Namespaces/" + $NamespaceId
$TenantRequest = Invoke-WebRequest -Uri ($BaseUrl + "/Streams/" + $StreamId + "/Data?startIndex=" + $StartIndex + "&endIndex=" + $EndIndex) -Method Get -Headers $AuthHeader -UseBasicParsing

# Output ADH data to file
Write-Output "Outputing ADH data to file"
$ADHData = $TenantRequest.Content | ConvertFrom-Json
$ADHData = ProcessDataset -Dataset $ADHData -Round $Round
$ADHData | Export-Csv -Path .\adh_data.csv -NoTypeInformation

# Retrieve data from PI Server
Write-Output "Retrieving data from PI Data Archive"
$PIData = Get-PIValue -PointId $PointId -Connection $Con -StartTime $StartIndex -Count $ADHData.Count

# Output PI data to file
Write-Output "Outputing PI data to file"
$PIData  = $PIData | Select-Object Timestamp, Value
$PIData = ProcessDataset -Dataset $PIData -Round $Round
$PIData | Export-Csv -Path .\pi_data.csv  -NoTypeInformation

Write-Output "Complete!"
