echo "Starting"

# Get needed variables
echo "Reading appsettings"
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
    $TokenBody = $TokenRequest | ConvertFrom-Json

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
echo "Connecting to PI Data Archive"
$Con = Connect-PIDataArchive -PIDataArchiveMachineName $DataArchiveName

# Get PI Point configuration
$PIpoint = Get-PIPoint -ID $PointId -AllAttributes -Connection $Con
$Type = $PIpoint.Attributes.pointtype
$Round = $false

if ($Type -eq "Float16" -or $Type -eq "Float32" -or $Type -eq "Float64") {
    $Round = $true
}

# Create an auth header
echo "Retrieving token"
$AuthHeader = @{
    Authorization = "Bearer " + (Get-ADHToken $TenantId $Resource $ClientId $ClientSecret)
}

# Retrieve data from ADH
echo "Retrieving data from ADH"
$BaseUrl = $Resource + "/api/" + $ApiVersion + "/Tenants/" + $TenantId + "/Namespaces/" + $NamespaceId
$TenantRequest = Invoke-WebRequest -Uri ($BaseUrl + "/Streams/" + $StreamId + "/Data?startIndex=" + $StartIndex + "&endIndex=" + $EndIndex) -Method Get -Headers $AuthHeader -UseBasicParsing

# Output ADH data to file
echo "Outputing ADH data to file"
$ADHData = $TenantRequest.Content | ConvertFrom-Json
$ADHData = ProcessDataset $ADHData $Round
$ADHData | Export-Csv -Path .\adh_data.csv -NoTypeInformation

# Retrieve data from PI Server
echo "Retrieving data from PI Data Archive"
$PIData = Get-PIValue -PointId $PointId -Connection $Con -StartTime $StartIndex -Count $ADHData.Count

# Output PI data to file
echo "Outputing PI data to file"
$PIData  = $PIData | select Timestamp, Value
$PIData = ProcessDataset $PIData $Round
$PIData | Export-Csv -Path .\pi_data.csv  -NoTypeInformation

echo "Complete!"