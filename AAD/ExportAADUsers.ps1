# Install-Module AzureAD

# Connect to Azure
Connect-AzureAD

$path = 'C:\ExportData\AAD_USERS.csv' 

# Get the basic list of users
$Users = Get-AzureADUser -All $true -Filter "AccountEnabled eq true and UserType eq 'Member'"
$UserDetails = @()

# For each user retrieve the details (hidden in extended properties)

$logText = 'Found ' + $Users.Count + " Users "
Write-Host $logText -f Green

for($i = 0; $i -le $Users.Count -1; $i++) {

    $managerName = ""
    $managerUserPrincipalName = ""
    $managerDepartment = ""

    $user = $Users[$i] | Select-Object -Property *

    $logText = "  " + ($i + 1) + "/" + $Users.Count + " ... " + $user.ObjectId + " - " + $user.UserPrincipalName
    Write-Host $logText -f Yellow

    if ($user.UserPrincipalName)
    {
        $manager = Get-AzureADUserManager -ObjectId  $user.UserPrincipalName
        $managerName = $manager.DisplayName
        $managerUserPrincipalName = $manager.UserPrincipalName
        $managerDepartment = $manager.Department
    }

    $UserDetails += [PSCustomObject] @{
        ObjectId = $user.ObjectId
        DisplayName = $user.DisplayName
        UserPrincipalName = $user.UserPrincipalName
        JobTitle = $user.JobTitle
        Department = $user.Department
        Office = $user.PhysicalDeliveryOfficeName
        ManagerDisplayName = $managerName
        ManagerUserPrincipalName = $managerUserPrincipalName
        ManagerDepartment = $managerDepartment
    }
}

try {
    $UserDetails | Export-Csv -Path $path -NoTypeInformation
    Write-Host "Exported all user details" -ForegroundColor Green
} 
catch {
    Write-Host "$error" -ForegroundColor red
}
