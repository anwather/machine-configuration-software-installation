Configuration SoftwareInstallation {
    Import-DscResource -ModuleName PSDscResources

    Node localhost {
        MsiPackage PowerShell {
            Ensure    = 'Present'
            Path      = "https://github.com/PowerShell/PowerShell/releases/download/v7.3.0/PowerShell-7.3.0-win-x64.msi"
            ProductId = "{1460EC99-E4CB-44A3-98F9-45157F11953A}"
            Arguments = "/quiet /norestart"
        }
    }
}

SoftwareInstallation

$package = New-GuestConfigurationPackage -Configuration .\SoftwareInstallation\localhost.mof -Name SoftwareInstallation -Type AuditAndSet -Version "2.0.0" -Force

$storageAccountName = "smr29110msi" ## Update this value
$resourceGroupName = "software-installation" ## Update this value
$storageContainerName = "software" ## Update this value

$ctx = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName).Context

$blob = Set-AzStorageBlobContent -Blob (Split-Path $package.Path -Leaf) -File $package.Path -Container $storageContainerName -Context $ctx -Force

$SASUri = New-AzStorageBlobSASToken -CloudBlob $blob.ICloudBlob -Permission r -ExpiryTime (Get-Date).AddYears(1) -Context $ctx -FullUri

$parameters = @{
    DisplayName   = "Install PowerShell 7"
    Description   = "Installs PowerShell 7 using Machine Configuration"
    PolicyId      = "63c3708a-136e-4a19-a094-8fb1e1dfcdc3"
    ContentUri    = $SASUri
    PolicyVersion = "2.0.0"
    Platform      = "Windows"
    Mode          = "ApplyAndAutoCorrect"
    Tag           = @{
        InstallPowerShell = "true"
    }
}

New-GuestConfigurationPolicy @parameters

New-AzPolicyDefinition -Name $parameters.PolicyId -Policy .\SoftwareInstallation_DeployIfNotExists.json
