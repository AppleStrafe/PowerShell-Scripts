#forces powershell to run as administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

Import-Module ActiveDirectory
Connect-AzureAD

Do{
    #Group you would like to quarry for users
    $group = $null
    do{
        $group = Read-Host -prompt "Please enter the group you want to search for"
    }While($group -like "")

    #New domain you want to add to users
    $newDomain = $null
    do{
        $newDomain = Read-Host -Prompt "Please enter the Domain you wish to change to"
    }While($newDomain -notlike "@*.com")
    
    
    #finds all users with the old domain
    $users = Get-AdGroupMember -Identity "$($group)" | Select SamAccountName

    #Shows list of Users
    Write-Host "Found the following Users in group $group`n"
    Get-AdGroupMember -Identity "$($group)" | Format-Table SamAccountName

    #Asks user if he wants to continue
    $continue = Read-Host -Prompt "Do you want to continue? (Y/N)"
    if ($continue.ToLower() -eq "y"){
        foreach ($user in $users){
            $info = Get-ADUser -filter "SamAccountName -eq '$($user.SamAccountName)'" -Properties * | select Name,EmailAddress,SamAccountName,ProxyAddresses

            #if user has multiple proxy addresses already it appends them
            $proxy = $null
            foreach($email in $info.ProxyAddresses){
                #if new domain already exisits in Proxy cancel
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
                        echo "$($user.name)`t$($user.ProxyAddresses)`t$($proxy + ',SMTP:' + $user.SamAccountName)" >> $PSScriptRoot\Payroll_EmailChange.csv
                    }Catch{
                        Write-Host -ForegroundColor DarkRed "WARNING: Can not access LOG file"
                    }

                    try{
                        Get-AzureADUser -SearchString "$($user.SamAccountName)$oldDomain" | revoke-azureaduserallrefreshtoken
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
