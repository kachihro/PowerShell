Connect-PnPOnline –Url https://<tenantname>.sharepoint.com/sites/<sitename> –UseWebLogin

$ctx = Get-PnPContext
$ctx.Site.DisableAppViews = $true;
$ctx.Site.DisableFlows = $true;
$ctx.ExecuteQuery();


# https://flow.microsoft.com
# https://powerapps.microsoft.com
