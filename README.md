# PI to CONNECT data services Transfer Verification Sample

**Version:** 1.0.3
  
[![Build Status](https://dev.azure.com/AVEVA-VSTS/Cloud%20Platform/_apis/build/status%2Fproduct-readiness%2FADH%2FAVEVA.sample-adh-pi_to_adh_transfer_verification-powershell?repoName=AVEVA%2Fsample-adh-pi_to_adh_transfer_verification-powershell&branchName=main)](https://dev.azure.com/AVEVA-VSTS/Cloud%20Platform/_build/latest?definitionId=16196&repoName=AVEVA%2Fsample-adh-pi_to_adh_transfer_verification-powershell&branchName=main)

Developed against PowerShell 5.1

## Requirements

- PowerShell 5.1+
- PowerShell Tools for the PI System (Included with the PI System Management Tools 2015 and later)
- Register a [Client-Credentials Client](https://datahub.connect.aveva.com/clients) in your CONNECT data services tenant and create a client secret to use in the configuration of this sample. ([Video Walkthrough](https://www.youtube.com/watch?v=JPWy0ZX9niU))
  - __NOTE__: By default, this sample only requires the `Tenant Member` role or a role with read access to the stream specified in [appsettings.json](appsettings.placeholder.json) to run successfully 
    - see: ['Authorization Allowed for these roles' in the documentation](https://docs.aveva.com/bundle/ocs/page/api-reference/tenant/tenant-tenants.html#get-tenant) 
  - It is strongly advised to not elevate the permissions of a client beyond what is necessary.

## About this sample

This sample can be used to compare data stored in a PI Data Archive to data written to CONNECT data services through the PI to CONNECT data services agent and easily confirm all intended data was sent successfully by the PI to Data Hub agent.   

The sample retrieves data between the StartIndex and EndIndex for the Stream with StreamId and PI Point with PointId specified in [appsettings.json](appsettings.placeholder.json). The data is then written to csv files cds_data.csv and pi_data.csv respectively. If the data is of type float, the application rounds the data to three decimal places to account for the difference in how the two datasources format floating point data. The function used to pull data from the PI Data Archive uses a count equal to the number of events retruned from Cds to ensure that missing snapshot data does not give the appearance of a dropped event. When compression is enabled on a PI Point, the PI to Cds agent only sends archived data.  

Once the data is writen to cds_data.csv and pi_data.csv, the data can be compared in your preffered spreadsheet application or [Test.ps1](Test.ps1) can be adapted to do the comparison automatically using PowerShell.

## Configuring the sample

The sample is configured using the file [appsettings.placeholder.json](appsettings.placeholder.json). Before editing, rename this file to `appsettings.json`. This repository's `.gitignore` rules should prevent the file from ever being checked in to any fork or branch, to ensure credentials are not compromised.

The StartIndex and EndIndex are ISO8601 formatted datetime strings. If other timestamp formats are used, they may result in time offsets due to differences in UTC and local timezones.

CONNECT data services is secured by obtaining tokens from its identity endpoint. Client credentials clients provide a client application identifier and an associated secret (or key) that are authenticated against the token endpoint. You must replace the placeholders in your `appsettings.json` file with the authentication-related values from your tenant and a client-credentials client created in your Cds tenant.

```json
{
    "Resource": "https://uswe.datahub.connect.aveva.com",                        // URL of Cds (Do not change if you are unsure)
    "ApiVersion": "v1",                                                          // Api version used in Cds (Do not change if you are unsure)
    "TenantId": "PLACEHOLDER_REPLACE_WITH_TENANT_ID",                            // Id of your Cds Tenant
    "NamespaceId": "PLACEHOLDER_REPLACE_WITH_NAMESPACE_ID",                      // Id of Namespace in your Cds Tenant where the streams reside
    "ClientId": "PLACEHOLDER_REPLACE_WITH_CLIENT_IDENTIFIER",                    // Client Id to use when connecting to Cds
    "ClientSecret": "PLACEHOLDER_REPLACE_WITH_CLIENT_SECRET",                    // Client secret to use when connecting to Cds
    "DataArchiveName": "PLACEHOLDER_DATA_ARCHIVE_NAME",                          // Name of Data Archive to retrieve data from
    "PointIds": [1,2],                                                           // List of PI Point Ids to retrieve data for. These get automatically translated into corresponding Stream Ids
    "StartIndex": "2022-03-12T00:00:00Z",                                        // Timestamp to start pulling data at in ISO 8601 format
    "EndIndex": "2022-03-15T00:00:00Z",                                          // Timestamp to stop pulling data at in ISO 8601 format
    "DataArchiveAlias": "PLACEHOLDER_REPLACE_WITH_DATA_ARCHIVE_ALIAS_OPTIONAL",  // Optional parameter used if the server name in your Stream Ids is different than the DataArchiveName
    "DATimeout": "00:01:00",                                                     // Timeout used when querying data from Data Archive in the form "hh:mm:ss"
    "CdsTimeout": 60,                                                            // Timeout used when querying data from CONNECT data services in seconds
    "Username": "TEST_ONLY",                                                     // Username to connect to the PI Data Archive with for testing purposes only. If removed or set to null, the credentials of the user running the script are used.
    "Password": "TEST_ONLY"                                                      // Password to connect to the PI Data Archive with for testing purposes only. If removed or set to null, the credentials of the user running the script are used.
}
```

## Running the sample

To run this example from Windows Powershell once the `appsettings.json` is configured, run

```shell
GetData.ps1
```

## Testing the sample

To run the unit test for this sample, run

```shell
TestData.ps1
```

---

Tested against Powershell 5.1  

For the main Cds samples page [ReadMe](https://github.com/AVEVA/AVEVA-Samples-CloudOperations)  
For the main AVEVA samples page [ReadMe](https://github.com/AVEVA/AVEVA-Samples)
