#forces powershell to run as administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

Import-Module ActiveDirectory
Connect-AzureAD

Do{
    #Old domain of users you want to update
    $account = $null
    do{
        $account = Read-Host -prompt "Please enter the User you want to search for"
    }While($account -notlike "*.*")

    #New domain you want to add to users
    $newDomain = $null
    do{
        $newDomain = Read-Host -Prompt "Please enter the Domain you wish to change to"
    }While($newDomain -notlike "@*.com")
    
    
    #finds all users with the old domain
    $users = Get-ADUser -Filter "SamAccountName -eq '$account'" -properties * | select Name,EmailAddress,SamAccountName,ProxyAddresses

    #Shows list of Users
    Write-Host "Found the following Users`n"
    Get-ADUser -Filter "SamAccountName -eq '$account'" -properties * | Format-Table Name

    #Asks user if he wants to continue
    $continue = Read-Host -Prompt "Do you want to continue? (Y/N)"
    if ($continue.ToLower() -eq "y"){
        foreach ($user in $users){

            #if user has multiple proxy addresses already it appends them
            $proxy = $null
            foreach($email in $user.ProxyAddresses){
                if($email -like "*$newDomain"){
                    $continue = "n"
                    break
                }else{
                    $proxy += ","+$email.ToLower()
                }
            }

            #Checks if it should continue
            if($continue.ToLower() -eq "y"){
                try{
                    #Sets the proxy addresses
                    Set-ADUser $user.SamAccountName `
                    -replace @{ProxyAddresses="SMTP:$($user.SamAccountName+$newDomain)$proxy" -split ","} `
                    -emailaddress "$($user.SamAccountName)$newDomain" `
                    -UserPrincipalName "$($user.SamAccountName)$newDomain"

                    #Logs to an Output.csv sheet
                    try{
                        $output = [pscustomobject]@{
                                  'User' = $user.name 
                                  'Old Proxys' = $user.ProxyAddresses 
                                  'Updated Proxys' = $proxy + ',SMTP:' + $user.SamAccountName
                                  }
                        $output | Export-Csv -Append -Path $PSScriptRoot\EmailChange.csv
                    }Catch{
                        Write-Host -ForegroundColor DarkRed "WARNING: Can not access LOG file"
                    }

                    try{
                        Get-AzureADUser -SearchString "$($user.SamAccountName)$newDomain" | revoke-azureaduserallrefreshtoken
                    }catch{
                        Write-Host "Error logging $($user.SamAccountName) out of O365 sessions"
                    }

                }Catch{
                    Write-Host -ForegroundColor Red "Could not update $($user.Name)"
                    Write-Host $_.Exception
                }
            }else{

                Write-Host -ForegroundColor Gray "$($User.Name) already has this domain"

            }
    
        }
        Write-Host -ForegroundColor Green "Done updating $($users.Name.Count) users!"
    }else{
        Write-Host -ForegroundColor Red "Terminating..."
    }

    do{
        $restart = Read-Host -Prompt "Do you want to restart? (Y/N)"
    }while($restart.length -gt 1)
}While($restart.ToLower() -eq "y")
