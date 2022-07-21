#forces powershell to run as administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

#Generates Logs
$date = Get-Date -Format "yyyy/MM/dd"
Start-Transcript -Path $PSScriptRoot\Logs\$date.log -Append

Do{
    #Prompts user for the user youre wanting to change
    $user = Read-Host -Prompt "Please enter the users SamAccountName. EX. 'jaden.heinbach'"

    #Prompts user for the AD Path
    $AD_Path = Read-Host -Prompt "Please enter the AD path to the Groups OU. Can be found in Attribute Editor under Distinguished Name. EX. 'OU=Groups,OU=PACS HQ,DC=provhc,DC=com'"

    #Finds all the groups within the OU
    $groups = Get-ADGroup -Filter * -SearchBase $AD_Path -Properties * | Select Name

    #Shows list of groups
    Write-Host "Found the following groups`n"
    Get-ADGroup -Filter * -SearchBase $AD_Path -Properties * | Format-Table Name

    #Asks user if he wants to continue
    $continue = Read-Host -Prompt "Do you want to continue? (Y/N)"

    If ($continue.ToLower() -eq "y"){
        foreach($group in $groups){
            Try{
                #Adds user to each group in the quarry.
                Get-ADGroup -filter "Name -eq '$($group.Name)'" -properties * |Add-ADGroupMember -Members $user
            }Catch{
                Write-Host -ForegroundColor Red "Could not add $user to $($group.Name)"
            }
        }
    }else{
        Write-Host -ForegroundColor Red "Terminating..."
    }

    #prompts user if they would like to start over
    $stop = Read-Host -Prompt "Would you like to start again? (Y/N)"

}While($stop.ToLower() -eq "y")