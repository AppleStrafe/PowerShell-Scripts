#forces powershell to run as administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) `
    { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

Import-Module ActiveDirectory

Do{
    #Old domain of users you want to update
    $oldDomain = $null
    do{
        $oldDomain = Read-Host -prompt "Please enter the Domain you want to search for"
    }While($oldDomain -notlike "@*.com")

    #New domain you want to add to users
    $newDomain = $null
    do{
        $newDomain = Read-Host -Prompt "Please enter the Domain you wish to change to"
    }While($newDomain -notlike "@*.com")


    #finds all users with the old domain
    $users = Get-ADUser -Filter "proxyaddresses -like 'SMTP:*$oldDomain' -and ProxyAddresses -notlike 'SMTP:*$newDomain'" `
                                -properties * | select Name,EmailAddress,SamAccountName,ProxyAddresses

    #Shows list of Users
    Write-Host "Found the following Users`n"
    Get-ADUser -Filter "proxyaddresses -like 'SMTP:*$oldDomain' -and ProxyAddresses -notlike 'SMTP:*$newDomain'" -properties * | Format-Table Name

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
                        echo "$($user.name)`t$($user.ProxyAddresses)`t$($proxy + ',SMTP:' + $user.SamAccountName)" >> $PSScriptRoot\Output.csv
                    }Catch{
                        Write-Host -ForegroundColor DarkRed "WARNING: Can not access LOG file"
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
    $restart = Read-Host -Prompt "Do you want to restart? (Y/N)"
}While($restart.ToLower() -eq "y")
