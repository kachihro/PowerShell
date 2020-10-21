 $listOfGroupEmails = "C:\Temp\GROUPS_ALL.txt"

Import-Module AzureADPreview
Connect-AzureAD 

# define a new template with the extra property on it
$template = Get-AzureADDirectorySettingTemplate | ? {$_.displayname -eq "group.unified.guest"}

# define a new template with the extra property on it
$templateWithSettingAllowGuestsFalse = $template.CreateDirectorySetting()
$templateWithSettingAllowGuestsFalse["AllowToAddGuests"] = $False

function DisableGuestUsers($groupEmail)
{
    #get the specific Group
    Write-host -f Yellow "... Group :"$groupEmail

    $groupID = (Get-AzureADGroup -SearchString $groupEmail).ObjectId
    $currentSettings = Get-AzureADObjectSetting -TargetObjectId $groupID -TargetType Groups

    if ($currentSettings -ne $null)
    {
        Remove-AzureADObjectSetting -Id $currentSettings.Id -TargetObjectId $groupID -TargetType Groups
        Write-host -f Red "!! Removed previous settings !!"
    }

    $newSetting = New-AzureADObjectSetting -TargetType Groups -TargetObjectId $groupID -DirectorySetting $templateWithSettingAllowGuestsFalse
    Write-host -f Green "      *DONE*"

    # Get-AzureADObjectSetting -TargetObjectId $groupID -TargetType Groups | fl Values

}

$office365Groups = Get-Content $listOfGroupEmails

foreach ($grpEmail in $office365Groups){
    DisableGuestUsers -groupEmail $grpEmail
    Write-host "      "
}
