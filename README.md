# sample-adh-pi_to_adh_transfer_verification-powershell

# PI to AVEVA Data Hub Transfer Verification Sample

**Version:** 1.0.0  
  
[![Build Status](https://dev.azure.com/osieng/engineering/_apis/build/status/product-readiness/PI-System/AF-SDK-Getting-Started-Guide?repoName=osisoft%2FAF-SDK-Getting-Started-Guide&branchName=main)](https://dev.azure.com/osieng/engineering/_build/latest?definitionId=2251&repoName=osisoft%2FAF-SDK-Getting-Started-Guide&branchName=main)

Developed against PowerShell 5.1

## Requirements

- PowerShell 5.1+
- PowerShell Tools for the PI System (Included with the PI System Management Tools 2015 and later)
- Register a [Client-Credentials Client](https://datahub.connect.aveva/clients) in your AVEVA Data Hub tenant and create a client secret to use in the configuration of this sample. ([Video Walkthrough](https://www.youtube.com/watch?v=JPWy0ZX9niU))
  - __NOTE__: This sample only requires the `Tenant Member` role to run successfully 
    - see: ['Authorization Allowed for these roles' in the documentation](https://docs.osisoft.com/bundle/ocs/page/api-reference/tenant/tenant-tenants.html#get-tenant) 
  - It is strongly advised to not elevate the permissions of a client beyond what is necessary.

## About this sample

This sample can be used to compare data stored in a PI Data Archive to data writen to AVEVA Data Hub through the PI to AVEVA Data Hub agent.   

The sample retrieves data between the StartIndex and EndIndex for the Stream with StreamId and PI Point with PointId specified in [appsettings.json](appsettings.placeholder.json) and writes them to csv files adh_data.csv and pi_data.csv respectively. If the data is of type float, the application rounds the data to three decimal places to account for the difference in how the two datasources format floating point data.  

Once the data is writen to adh_data.csv and pi_data.csv, the data can be compared in your preffered spreadsheet application or [Test.ps1](Test.ps1) can be adapted to do the comparison automatically using PowerShell.

## Configuring the sample

The sample is configured using the file [appsettings.placeholder.json](appsettings.placeholder.json). Before editing, rename this file to `appsettings.json`. This repository's `.gitignore` rules should prevent the file from ever being checked in to any fork or branch, to ensure credentials are not compromised.

The StartIndex and EndIndex are ISO8601 formatted datetime strings. If other timestamp formats are used, they may result in time offsets due to differences in UTC and local timezones.

AVEVA Data Hub is secured by obtaining tokens from its identity endpoint. Client credentials clients provide a client application identifier and an associated secret (or key) that are authenticated against the token endpoint. You must replace the placeholders in your `appsettings.json` file with the authentication-related values from your tenant and a client-credentials client created in your ADH tenant.

```json
{
    "Resource": "https://uswe.datahub.connect.aveva.com",
    "ApiVersion": "v1",
    "TenantId": "PLACEHOLDER_REPLACE_WITH_TENANT_ID",
    "NamespaceId": "PLACEHOLDER_REPLACE_WITH_NAMESPACE_ID",
    "ClientId": "PLACEHOLDER_REPLACE_WITH_APPLICATION_IDENTIFIER",
    "ClientSecret": "PLACEHOLDER_REPLACE_WITH_APPLICATION_SECRET",
    "DataArchiveName": "PLACEHOLDER_DATA_ARCHIVE_NAME",
    "PointId": 1,
    "StreamId": "PLACEHOLDER_REPLACE_WITH_STREAM_ID",
    "StartIndex": "2022-03-12T00:00:00Z",
    "EndIndex": "2022-03-15T00:00:00Z",
    "Username": "PLACEHOLDER_REPLACE_WITH_USERNAME_TEST_ONLY",
    "Password": "PLACEHOLDER_REPLACE_WITH_PASSWORD_TEST_ONLY"
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

For the main ADH samples page [ReadMe](https://github.com/osisoft/OSI-Samples-OCS)  
For the main AVEVA samples page [ReadMe](https://github.com/osisoft/OSI-Samples)
