# ====================================================

$listOfSiteCollections = "C:\Temp\SITES-TO-CHECK.txt"
$outputFile = "C:\Temp\Found-Nintex-Forms.csv"

$tenant = "layer8"
$appSitePrefix = '//' + $tenant + '-'

# ====================================================

#Delete the Output File, if exists
if (Test-Path $outputFile) { Remove-Item $outputFile }
  
function FindNintexForms([String]$siteURL)
{
    try{
        #Array to hold list forms
        $ListForms = @()

        #Setup the context
        Connect-PnPOnline -Url $siteUrl -UseWebLogin
        $Ctx = Get-PnPContext

        #Get the Web
        $Web = $Ctx.Web
        $Ctx.Load($Web)
        $Ctx.Load($Web.Webs)
        $Ctx.ExecuteQuery()
        
        Write-host -f Cyan "* Web:"$Web.Url
         
        #Get All Lists from the web
        $Lists = $Web.Lists
        $Ctx.Load($Lists);
        $Ctx.ExecuteQuery()

        #Iterate through each document library in the web
        ForEach($l in $Lists)
        {
            $list = $Web.Lists.GetByTitle($l.Title)
            $Ctx.Load($list)
            $Ctx.ExecuteQuery()

            $Ctx.Load($list.RootFolder)
            $Ctx.Load($list.ContentTypes)
            $Ctx.ExecuteQuery()

            If($list.Hidden -eq $False)
            {
                #check to see if there a NINTEX FORM for the default CT
                $defaultCt = $list.ContentTypes[0]
    
                if ($defaultCt.NewFormUrl -like '*NFLaunch*')
                {
                    Write-Host -f Green "   >> Found Nintex Form :"$list.Title

                    $ListForms += [PSCustomObject] @{
                        SiteUrl = $Web.url
                        ListTitle = $list.Title
                        ListUrl = $list.RootFolder.ServerRelativeUrl
                        NewFormUrl = $defaultCt.NewFormUrl
                    }
                }
            }
        }

        #Export the Findings to CSV File
        $ListForms | Export-CSV $outputFile -NoTypeInformation -Append
 
        #Iterate through each subsite of the current web and call the function recursively
        ForEach($Subweb in $Web.Webs)
        {
            $nextUrl = $Subweb.URL 

            if ($nextUrl -match $appSitePrefix) {
                write-host -f Red " ** IGNORE   " $nextUrl
            }
            else {
                #Call the function recursively to process all subsites underneaththe current web
                Check-NintexForms -SiteURL $Subweb.URL 
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
    FindNintexForms -SiteURL $siteURL
    write-host -f DarkCyan " ~~ Wait 2000ms"
    Start-Sleep -Milliseconds 2000
    write-host ''
}
