# ==========================
# CONFIGURE

$tenant = "layer8"
$appSitePrefix = '//' + $tenant + '-'

$listOfSiteCollections = "C:\Temp\CHECK-SITES.txt"
$outputFile = "C:\Temp\FOUND-WORKFLOWS.csv"
# ==========================

$path = "C:\Program Files\WindowsPowerShell\Modules\SharePointPnPPowerShellOnline\3.25.2009.1"

# reference to needed assemblies
Add-Type -Path "$path\Microsoft.SharePoint.Client.dll"
Add-Type -Path "$path\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "$path\Microsoft.SharePoint.Client.Search.dll"
Add-Type -Path "$path\OfficeDevPnP.Core.dll"
Add-Type -Path "$path\Microsoft.SharePoint.Client.WorkflowServices.dll"

#Delete the Output File, if exists
if (Test-Path $outputFile) { Remove-Item $outputFile }
  
function Get-Workflows([String]$siteURL)
{
    try{
        #Array to hold list workflows
        $ListWorkflows = @()

        #Setup the context
        Connect-PnPOnline -Url $siteUrl -UseWebLogin
        $Ctx = Get-PnPContext

        #Get the Web
        $Web = $Ctx.Web
        $Ctx.Load($Web)
        $Ctx.Load($Web.Webs)
        $Ctx.ExecuteQuery()
        
        Write-host -f Yellow "Processing Web:"$Web.Url
         
        #Get All Lists from the web
        $Lists = $Web.Lists
        $Ctx.Load($Lists)
        $Ctx.ExecuteQuery()

        $spWorkflowServicesManager = New-Object Microsoft.SharePoint.Client.WorkflowServices.WorkflowServicesManager($Ctx, $Web); 
        $spWorkflowSubscriptionService = $spWorkflowServicesManager.GetWorkflowSubscriptionService(); 
        $spWorkflowInstanceService = $spWorkflowServicesManager.GetWorkflowInstanceService();

        $Ctx.Load($spWorkflowServicesManager)  
        $Ctx.Load($spWorkflowSubscriptionService)  
        $Ctx.Load($spWorkflowInstanceService)
        $Ctx.ExecuteQuery(); 

        $SiteWorkflows = $spWorkflowSubscriptionService.EnumerateSubscriptions(); 
        $Ctx.Load($SiteWorkflows);                 
        $Ctx.ExecuteQuery();                 
    
        foreach($sw in $SiteWorkflows)
        {
            Write-Host -f Yellow "`t`t Found Site Workflow > '$($sw.Name)'"

            $ListWorkflows += [PSCustomObject] @{
                                    SiteUrl = $Web.url
                                    ListTitle = "<< SITE LEVEL >>"
                                    WorkflowName = $sw.Name
                                    StatusFieldName = $sw.StatusFieldName
                                    }
        }

        #Iterate through each document library in the web
        ForEach($List in $Lists)
        {
            Write-host -f Yellow "`t Processing :"$List.Title
            #Exclude System Lists
            If($List.Hidden -eq $False)
            {
                $spWorkflowSubscriptions = $spWorkflowSubscriptionService.EnumerateSubscriptionsByList($List.Id); 
                $Ctx.Load($spWorkflowSubscriptions);                 
                $Ctx.ExecuteQuery();                 
    
                foreach($wfa in $spWorkflowSubscriptions)
                {
                    Write-Host -f Green "`t`t Found List Workflow > '$($wfa.Name)'"

                    $ListWorkflows += [PSCustomObject] @{
                                            SiteUrl = $Web.url
                                            ListTitle = $List.Title
                                            WorkflowName = $wfa.Name
                                            StatusFieldName = $wfa.StatusFieldName
                                            }
                }
                
            }
        }

        #Export the Findings to CSV File
        $ListWorkflows | Export-CSV $outputFile -NoTypeInformation -Append
 
        #Iterate through each subsite of the current web and call the function recursively
        ForEach($Subweb in $Web.Webs)
        {
            $nextUrl = $Subweb.URL 

            if ($nextUrl -match $appSitePrefix) {
                write-host -f Red " ** IGNORE   " $nextUrl
            }
            else {
                #Call the function recursively to process all subsites underneaththe current web
                Get-Workflows -SiteURL $Subweb.URL 
            }
        }
    }
    catch {
        $_.Exception
        write-host -f Red "Error Generating Checked Out Files Report!" $_.Exception.Message
    }
}
  
#Call the function
$siteCollections = Get-Content $listOfSiteCollections

foreach ($siteURL in $siteCollections){
    if ($siteURL -ne "") 
    {
        Get-Workflows -SiteURL $siteURL
    }
}
