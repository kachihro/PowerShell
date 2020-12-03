$importFile = "C:\Temp\userlist.csv"

#Get User Inputs for Domain, City, Country, Company and Department. The inputs will be the same for all users.
$domain = "tenant.onmicrosoft.com"
$city = "Melbourne"
$company = "Hyper Mega Global Enterprises .NET"

Connect-AzureAD 

$userlist = Import-Csv $importFile

$PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$PasswordProfile.Password = $city +"2020!"

$i=0
foreach ($user in $userlist)
{
    $name = $user.fname.Trim()+" "+$user.lname.Trim()
    $upn = $user.fname.Trim()+"."+$user.lname[0]+"@"+$domain
    $sam = $user.fname.Trim()+"."+$user.lname[0]

    $department = "DPT-" + $user.fname.Trim()
    $office = "OFFICE-" + $user.lname

    New-AzureADUser -PasswordProfile $PasswordProfile -City $city -Company $company -PhysicalDeliveryOfficeName $office -mailNickname $sam -Department $department -DisplayName $name -AccountEnabled $true -GivenName $user.fname -Surname $user.lname -UserPrincipalName $upn

    Write-Host Created user : $name

    $i++
}

