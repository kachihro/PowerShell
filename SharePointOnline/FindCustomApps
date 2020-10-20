$cred = Get-Credential

$orgName = "TENANT" 
$adminUrl = "https://$orgName-admin.sharepoint.com" 
Connect-PnPOnline $adminUrl -Credentials $cred

function ListApps ($url)
{    
   Connect-PnPOnline -Url $url -Credentials $cred    
   $apps = Get-PnPAppInstance
   foreach ($app in $apps)    
   {        
      $logLine = $url + " - " + $app.Title        
      $logLine    
   }
}

#get a list of group sites
$groupSiteCollections = Get-PnPTenantSite -Template GROUP#0
foreach ($sc in $groupSiteCollections) { ListApps $sc.Url }

#get a list of classic sites
$classicSiteCollections = Get-PnPTenantSite 
foreach ($sc in $classicSiteCollections) { ListApps $sc.Url }
