# ==========================
# CONFIGURE

$listOfSiteCollections = "C:\Temp\CHECK-SITES.txt"
$outputFile = "C:\Temp\CHECK-SITES-CHECKED-OUT-FILES.csv"

# ==========================

Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking
Import-Module SharePointPnPPowerShellOnline

#Delete the Output File, if exists
if (Test-Path $outputFile) { Remove-Item $outputFile }
  
function Get-SPOCheckedOutFiles([String]$siteURL)
{
    Write-host -f Yellow "Processing Web:"$siteURL

    try{
        #Setup the context
        Connect-PnPOnline -Url $siteUrl -UseWebLogin
        $Ctx = Get-PnPContext

        #Get the Web
        $Web = $Ctx.Web
        $Ctx.Load($Web)
        $Ctx.Load($Web.Webs)
        $Ctx.ExecuteQuery()
 
        #Get All Lists from the web
        $Lists = $Web.Lists
        $Ctx.Load($Lists)
        $Ctx.ExecuteQuery()
  
        #Prepare the CAML query
        $Query = ([Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery())
        $Query.ViewXml = "@
                            <View Scope='RecursiveAll'>
                                <Query>
                                    <Where>
                                        <IsNotNull><FieldRef Name='CheckoutUser' /></IsNotNull>
                                    </Where>
                                </Query>
                                <RowLimit Paged='TRUE'>2000</RowLimit>
                            </View>"
 
        #Array to hold Checked out files
        $CheckedOutFiles = @()
         
        #Iterate through each document library in the web
        ForEach($List in ($Lists | Where-Object {$_.BaseTemplate -eq 101}) )
        {
            Write-host -f Yellow "`t Processing Document Library:"$List.Title
            #Exclude System Lists
            If($List.Hidden -eq $False)
            {
                #Batch Process List items
                Do {
                    $ListItems = Get-PnPListItem -List $List -Query $Query.ViewXml

                    $Query.ListItemCollectionPosition = $ListItems.ListItemCollectionPosition
 
                    #Get All Checked out files
                    ForEach($Item in $ListItems)
                    {
                        Write-Host $Item["FileRef"]

                        #Get the Checked out File data
                        $File = $Web.GetFileByServerRelativeUrl($Item["FileRef"])
                        $Ctx.Load($File)
                        $CheckedOutByUser = $File.CheckedOutByUser
                        $Ctx.Load($CheckedOutByUser)
                        $Ctx.ExecuteQuery()
 
                        Write-Host -f Green "`t`t Checked out File '$($File.Name)' at $($Item['FileRef']), Checked Out By: $($CheckedOutByUser.LoginName), Checked Out By: $($CheckedOutByUser.LoginName), Created Date: $($Item['Created']), Modified Date: $($Item['Modified'])"
                        $CheckedOutFiles += [PSCustomObject] @{
                                                FileName = $File.Name
                                                SiteUrl = $Web.url
                                                FileUrl = $Item['FileRef']
                                                CheckedOutBy = $CheckedOutByUser.LoginName
                                                CreatedDate = $($Item['Created'])
                                                ModifiedDate = $($Item['Modified'])
                                                }
                    }
                } While($Query.ListItemCollectionPosition -ne $Null)
            }
        }

        #Export the Findings to CSV File
        $CheckedOutFiles | Export-CSV $outputFile -NoTypeInformation -Append
 
        #Iterate through each subsite of the current web and call the function recursively
        ForEach($Subweb in $Web.Webs)
        {
            $nextUrl = $Subweb.URL 

            if ($nextUrl -match '//ConocoPhillips-') {
                write-host -f Red " ** IGNORE   " $nextUrl
            }
            else {
                #Call the function recursively to process all subsites underneaththe current web
                Get-SPOCheckedOutFiles -SiteURL $Subweb.URL 
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
        Get-SPOCheckedOutFiles -SiteURL $siteURL
    }
}
