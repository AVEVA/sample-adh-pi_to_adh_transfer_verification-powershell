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

# Create an auth header
echo "Retrieving token"
$AuthHeader = @{
    Authorization = "Bearer " + (Get-ADHToken $TenantId $Resource $ClientId $ClientSecret)
}

# Retrieve data from ADH
echo "Retrieving data from ADH"
$BaseUrl = $Resource + "/api/" + $ApiVersion + "/Tenants/" + $TenantId + "/Namespaces/" + $NamespaceId
$TenantRequest = Invoke-WebRequest -Uri ($BaseUrl + "/Streams/" + $StreamId + "/Data?startIndex=" + $StartIndex + "&endIndex=" + $EndIndex) -Method Get -Headers $AuthHeader -UseBasicParsing

echo "Outputing ADH data to file"
$ADHData = $TenantRequest.Content | ConvertFrom-Json
# Parse and convert timestamps to universal time
for ($i = 0; $i -lt $ADHData.Count; $i++) {$ADHData[$i].TimeStamp = [datetime]::Parse($ADHData[$i].TimeStamp).ToUniversalTime()}
$ADHData | Export-Csv -Path .\adh_data.csv -NoTypeInformation

# Create connection to PI Data Archive
echo "Connecting to PI Data Archive"
$myPI = Connect-PIDataArchive -PIDataArchiveMachineName DFPIServerPrd.osisoft.ext

# Retrieve data from PI Server
echo "Retrieving data from PI Data Archive"
$PIData = Get-PIValue -PointId $PointId -Connection $myPI -StartTime $StartIndex -EndTime $EndIndex

# Convert timestamps to universal time
$PIData  = $PIData | select Timestamp, Value
for ($i = 0; $i -lt $PIData.Count; $i++) {$PIData[$i].TimeStamp = $PIData[$i].TimeStamp.ToUniversalTime()}

echo "Outputing PI data to file"
$PIData | Export-Csv -Path .\pi_data.csv  -NoTypeInformation

echo "Complete!"