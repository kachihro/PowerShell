# ==========================
# CONFIGURE

$listOfSiteCollections = "C:\Temp\CHECK-SITES.txt"
$outputFile = "C:\Temp\CHECK-SITE-SIZES.csv"

#Delete the Output File, if exists
if (Test-Path $outputFile) { Remove-Item $outputFile }

# ==========================

function FormatBytes ($bytes)
{
    $sigDigits = 2 

    switch ($bytes)
    {
        {$bytes -ge 1TB} {"{0:n$sigDigits}" -f ($bytes/1TB) + " TB" ; break}
        {$bytes -ge 1GB} {"{0:n$sigDigits}" -f ($bytes/1GB) + " GB" ; break}
        {$bytes -ge 1MB} {"{0:n$sigDigits}" -f ($bytes/1MB) + " MB" ; break}
        {$bytes -ge 1KB} {"{0:n$sigDigits}" -f ($bytes/1KB) + " KB" ; break}
        Default { "{0:n$sigDigits}" -f ($bytes) + " Bytes" }
    }
}

function Get-SPOSiteSize([String]$siteURL)
{
    try{
        Write-host -f Yellow "Check storage for :"$siteURL

        $SiteSizes = @()

        #Setup the context
        Connect-PnPOnline -Url $siteUrl -UseWebLogin
        
        $site = Get-PNPSite -Includes Usage

        $formattedSize = FormatBytes $site.Usage.Storage

        $SiteSizes += [PSCustomObject] @{
                        SiteUrl = $siteURL
                        StorageSize = $site.Usage.Storage
                        FormattedSize = $formattedSize
                        }
    

        #Export the Findings to CSV File
        $SiteSizes | Export-CSV $outputFile -NoTypeInformation -Append
    
    }
    catch {
        $_.Exception
        write-host -f Red "Error Generating Checked Out Files Report!" $_.Exception.Message
    }
}
 
#Call the function
$siteCollections = Get-Content $listOfSiteCollections

foreach ($siteURL in $siteCollections){
    Get-SPOSiteSize $siteURL
    write-host -f DarkCyan " ~~ Wait 2000ms"

    Start-Sleep -Milliseconds 2000
    write-host ''
}

