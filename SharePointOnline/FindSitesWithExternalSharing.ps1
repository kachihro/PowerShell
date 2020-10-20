$orgName = "TENANT" 
$outputFile = "C:\Temp\Sites-ExternalSharing.csv"

#Delete the Output File, if exists
if (Test-Path $outputFile) { Remove-Item $outputFile }

$adminUrl = "https://$orgName-admin.sharepoint.com" 
Connect-PnPOnline $adminUrl -UseWebLogin

$sites = Get-PnPTenantSite | select Url, Title, SharingCapability, Template, RelatedGroupId

foreach ($s in $sites){
    $logDetails = @()

    Write-host -f Yellow "Checking :"$s.Url

    if ($s.SharingCapability -ne 'Disabled')
    {
        Write-host -f Magenta ".... "$s.SharingCapability
        $logDetails += [PSCustomObject] @{
                            SiteUrl = $s.Url
                            SiteTitle = $s.Title
                            SharingCapability = $s.SharingCapability
                            SiteTemplate = $s.Template
                            RelatedGroupId = $s.RelatedGroupId
                        }

        $logDetails | Export-CSV $outputFile -NoTypeInformation -Append

    }
}

