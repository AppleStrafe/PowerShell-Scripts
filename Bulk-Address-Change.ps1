if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

#group you wanna grab the users from. EX. "PACS Email Signature"
$users = Get-AdGroupMember -Identity 'PACS Email Signature' | Select SamAccountName

#old streetAddress
$oldStreet =  "*N. University Ave.*"

#address you would like to change to
$Streetaddress = "262 N. University Ave."
$City = "Farmington,"
$State = "UT"
$Zipcode = "84025"

foreach($user in $users){
    #Gets each user
    $user = Get-ADUser $user.SamAccountName -properties * | Select StreetAddress,SamAccountName
    Foreach($i in $user){
        #checks to make sure they had the old address or its currently blank
        if ($i.StreetAddress -like $oldStreet -or $i.StreetAddress -eq $null){
            $i.SamAccountName,$Streetaddress,$City,$State,$Zipcode | Export-Csv -Path $PSScriptRoot/Updated_Addresses.csv -Append
            Set-ADUser $i.SamAccountName -Streetaddress $Streetaddress -City $City -State $State -PostalCode $Zipcode
            Write-Host -ForegroundColor Blue "$($i.SamAccountName) has been updated!"
        }else{
            Write-Host -ForegroundColor DarkRed "$($i.SamAccountName) Does not have old address"
        }
    }
}