# ==========================

$listOfSiteCollections = "C:\Temp\FixLocaleForSites.txt"

$tenant = "layer8"
$appSitePrefix = '//' + $tenant + '-'

# ==========================

$fixTimeZone = "NO"
$fixLocale = "YES"

$NewCulture = "en-au"
#$NewTimeZoneID = 76     #Melbourne
#$NewTimeZoneID = 19     #Adelaide
$NewTimeZoneID = 73     #Perth

function Set-SPORegionalSettings([String]$SiteURL)
{
    Write-host -f Yellow "Processing Web:"$SiteURL

    #Setup the context
    Connect-PnPOnline -Url $SiteURL -UseWebLogin
    $Ctx = Get-PnPContext

    #Get the Web
    $Web = $Ctx.Web
    $Ctx.Load($Web)
    $Ctx.Load($Web.Webs)
    $Ctx.ExecuteQuery()

    $Webs = $Web.Webs
    $Ctx.Load($Webs)
    $Ctx.ExecuteQuery()

    $Ctx.Load($Web.RegionalSettings);
    $Ctx.Load($Web.RegionalSettings.TimeZone);
    $Ctx.ExecuteQuery();

    $oldtzid = $Web.RegionalSettings.TimeZone.Id
    $oldLCID = $Web.RegionalSettings.LocaleId
    $c1 = [System.Globalization.CultureInfo]::GetCultureInfo([int]$Web.RegionalSettings.LocaleId)
    Write-Host " * Current: "$Web.RegionalSettings.TimeZone.Description "  ~~ "$Web.RegionalSettings.LocaleId"-"$c1.DisplayName

    # update site settings
    # =====================================================================

    if ($fixTimeZone -eq 'YES') {
        # load the new time zone
        $Ctx.Load($Web.RegionalSettings.TimeZones);
        $Ctx.ExecuteQuery();

        $tz = $Web.RegionalSettings.TimeZones.GetById($NewTimeZoneID)
        $Ctx.Load($tz);
        $Ctx.ExecuteQuery();
        
        #set the time zone
        $Web.RegionalSettings.TimeZone = $tz

        #update web
        $Web.RegionalSettings.Update()
        $Web.Update();
        $Ctx.ExecuteQuery();
    }

    if ($fixLocale -eq 'YES') {
        #set the culture
        $culture=[System.Globalization.CultureInfo]::CreateSpecificCulture($NewCulture)
        $Web.RegionalSettings.LocaleId=$culture.LCID

        #update web
        $Web.RegionalSettings.Update()
        $Web.Update();
        $Ctx.ExecuteQuery();
    }

    #refresh
    $Ctx.Load($Web);
    $Ctx.Load($Web.RegionalSettings);
    $Ctx.Load($Web.RegionalSettings.TimeZone);
    $Ctx.ExecuteQuery();
    
    $newtzid = $Web.RegionalSettings.TimeZone.Id;
    $newLCID = $Web.RegionalSettings.LocaleId;

    if ($fixTimeZone -eq 'YES') {
        if ($newtzid -ne $oldtzid)
        {
            Write-Host "    ! Wrong TimeZone detected" -foreground red
            $updated = $true
        }
    }

    if ($fixLocale -eq 'YES') {
        if( $newLCID -ne $oldLCID)
        {
            Write-Host "    ! Wrong Region/Locale detected"  -foreground red
            $updated = $true
        }
    }

    #output
    if($updated -eq $true)
    {
        $c1 = [System.Globalization.CultureInfo]::GetCultureInfo([int]$Web.RegionalSettings.LocaleId)
        Write-Host " > Updated: "$Web.RegionalSettings.TimeZone.Description "  ~~ "$Web.RegionalSettings.LocaleId"-"$c1.DisplayName -foreground green
        Write-Host ""
    }

    #Iterate through each subsite of the current web and call the function recursively
    ForEach($Subweb in $Web.Webs)
    {
        $nextUrl = $Subweb.URL 
        if ($nextUrl -match $appSitePrefix) {
            write-host -f Red " ** IGNORE   " $nextUrl
        }
        else {
            Set-SPORegionalSettings -SiteURL $nextUrl 
            write-host -f DarkCyan "~~ Wait 5000ms"
            Start-Sleep -Milliseconds 5000
            write-host ''
        }
    }
}

#Call the function
$siteCollections = Get-Content $listOfSiteCollections

foreach ($siteURL in $siteCollections){
    Set-SPORegionalSettings -SiteURL $siteURL
    write-host -f DarkCyan "~~ Wait 5000ms"
    
    Start-Sleep -Milliseconds 5000
    write-host ''
}
