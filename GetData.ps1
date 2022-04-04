Write-Output "Starting"

# Read appsettings
Write-Output "Reading appsettings"
$Appsettings = Get-Content -Path appsettings.json | ConvertFrom-Json

# Define the number of digits after the decimal point to round float data to
$NumDigits = 3
# A list of types that need to be rounded
$RoundedTypes = "Float16", "Float32", "Float64"

Function Get-ADHToken($Resource, $ClientId, $ClientSecret) {
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

        # If the value is a float then round digits
        if ($Round) {
            $Dataset[$i].Value = [math]::Round($Dataset[$i].Value, $NumDigits)
        }
    }

    Return $Dataset
}

# Create connection to PI Data Archive
Write-Output "Connecting to PI Data Archive"
if ($null -eq $Appsettings.Username) {
    $Con = Connect-PIDataArchive -PIDataArchiveMachineName $Appsettings.DataArchiveName
} else {
    $Password = ConvertTo-SecureString -String $Appsettings.Password -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Appsettings.Username, $Password
    $Con = Connect-PIDataArchive -PIDataArchiveMachineName $Appsettings.DataArchiveName -WindowsCredential $Credential
}

# Create an auth header
Write-Output "Retrieving token"
$AuthHeader = @{
    Authorization = "Bearer " + (Get-ADHToken -Resource $Appsettings.Resource -ClientId $Appsettings.ClientId -ClientSecret $Appsettings.ClientSecret)
}

# Collect data for each Id
foreach ($PointId in $Appsettings.PointIds) {

    # Get PI Point configuration
    $PIpoint = Get-PIPoint -ID $PointId -Attributes pointtype -Connection $Con
    $Round = $RoundedTypes -contains $PIpoint.Attributes.pointtype

    # Retrieve data from ADH
    # Note: the maximum number of events returned by an SDS data call is 250,000. However, we are using paginated data calls to get many more events over multiple calls.
    # See https://docs.osisoft.com/bundle/data-hub/page/developer-guide/sequential-data-store-dev/sds-read-data.html for more information.
    Write-Output "Retrieving data from ADH"
    $BaseUrl = $Appsettings.Resource + "/api/" + $Appsettings.ApiVersion + "/Tenants/" + $Appsettings.TenantId + "/Namespaces/" + $Appsettings.NamespaceId
    $StreamId = If ($null -eq $Appsettings.DataArchiveAlias) {"PI_" + $Appsettings.DataArchiveName + "_" + $PointId} Else {"PI_" + $Appsettings.DataArchiveAlias + "_" + $PointId}
    $StreamUrl = $BaseUrl + "/Streams/" + $StreamId + "/Data?startIndex=" + $Appsettings.StartIndex + "&endIndex=" + $Appsettings.EndIndex + "&count=250000&continuationToken="
    $ADHData = @()
    $ContinuationToken = ""
    Do {
        $TenantRequest = Invoke-WebRequest -Uri ($StreamUrl + $ContinuationToken) -Method Get -Headers $AuthHeader -UseBasicParsing
        $RequestContent = $TenantRequest.Content | ConvertFrom-Json

        $ADHData += $RequestContent.Results
        $ContinuationToken = $RequestContent.ContinuationToken
    } While ($null -ne $ContinuationToken)

    # Process data
    $ADHData = $ADHData | Select-Object @{Name="StreamId"; Expression={$StreamId}}, Timestamp, Value
    $ADHData = ProcessDataset -Dataset $ADHData -Round $Round

    # Retrieve data from PI Server
    # Note: instead of using the EndIndex, the count is used to avoid differences due to snapshot data.
    # See the REAME for more information.
    Write-Output "Retrieving data from PI Data Archive"
    $PIData = Get-PIValue -PointId $PointId -Connection $Con -StartTime $Appsettings.StartIndex -Count $ADHData.Count

    # Process data
    $PIData  = $PIData | Select-Object StreamId, Timestamp, @{Name="Value"; Expression={If ($_.Value.GetType() -eq [OSIsoft.PI.Net.EventState]) {$_.Value.get_StateSet()} else {$_.Value}}}
    $PIData  = ProcessDataset -Dataset $PIData -Round $Round

    # Append ADH data to file
    Write-Output "Outputing ADH data to file"
    $ADHData | Export-Csv -Path .\adh_data.csv -NoTypeInformation -Append

    # Append PI data to file
    Write-Output "Outputing PI data to file"
    $PIData | Export-Csv -Path .\pi_data.csv  -NoTypeInformation -Append
}



Write-Output "Complete!"
