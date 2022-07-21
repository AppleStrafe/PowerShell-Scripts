if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
$date = Get-Date -Format "yyyy/MM/dd"
Start-Transcript -Path "$PSScriptRoot\$date.log" -Append

Connect-MsolService

#List of users to create
$Users = Import-Csv -Path "$PSScriptRoot\bulk_user.csv"

foreach ($user in $Users){
    $samName = ($user.SamName).Replace(" ",".")
    $email = ($samName.toLower()+$user.Email).replace(" ","")
    $password = $user.Password
    $jobtitle = $user.Jobtitle
    $first = $null
    $middle = $null
    $last = $null
    $Name = ($user.Name).Split(" ")
    if($Name.count -eq 3){
        $first = (Get-Culture).TextInfo.ToTitleCase($Name[0])
        $middle = (Get-Culture).TextInfo.ToTitleCase($Name[1])
        $last = (Get-Culture).TextInfo.ToTitleCase($Name[2])
    }
    if($Name.count -eq 2){
        $first = (Get-Culture).TextInfo.ToTitleCase($Name[0])
        $last = (Get-Culture).TextInfo.ToTitleCase($Name[1])
    }
    Try{
        if(Get-ADuser -filter "SamAccountName -eq '$($samName.toLower())'"){
            Write-Host "$($User.Name) alread exists"
        }
        else{

            try{
            New-ADUser `
            -SamAccountName $samName.toLower() `
            -Path "OU=Users,OU=$($user.Facility),OU=PACS Facilities,DC=provhc,DC=com" `
            -Name "$($user.Name)" `
            -UserPrincipalName $email `
            -GivenName $first `
            -SurName $last `
            -AccountPassword (ConvertTo-secureString $password.Trim() -AsPlainText -Force) `
            -ChangePasswordAtLogon $falst `
            -PasswordNeverExpires $true `
            -Enabled $True `
            -DisplayName "$($user.Name)" `
            -EmailAddress $email `
            -Description $jobtitle `
            -Title $jobtitle `
            -OtherAttributes @{proxyAddresses = "SMTP:$email"} `
            -verbose            
            Set-ADAccountPassword -Identity $samName.toLower() -NewPassword (ConvertTo-SecureString $password -AsPlainText -force)
            }Catch{
            Write-Host "Something during the user creation proccess was not done for $samName"
            Write-Host $_.Exception
            }

            #Exports to csv
           $first,$last,$middle,$samName.toLower(),$email,$user.Facility,$password | Export-Csv "$PSScriptRoot\Account-Creations#12.csv" -Append
        }

        #O365 user creation function

        $upn = $email.toLower()
        $firstname = $first
        $lastname = $last
        $password = $password

        try{
        New-MsolUser `
            -UserPrincipalName $upn `
            -DisplayName "$($user.Name)"`
            -FirstName "$firstname" `
            -LastName "$lastname" `
            -PreferredDataLocation "US" `
            -Password (ConvertTo-SecureString $password -AsPlainText -force)
        
            Set-MsolUser -UserPrincipalName $upn -UsageLocation US -Verbose
            Set-MsolUserLicense -UserPrincipalName $upn -AddLicenses $user.License -Verbose

            write-host "$upn assigned license"
        }Catch{
            Write-Host "Could not create o365 account"
            Write-Host $_.Exception
        }
        #MFA Enabling
        $mf= New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
        $mf.RelyingParty = "*"
        $mfa = @($mf)

        Set-MsolUser -UserPrincipalName "$upn" -StrongAuthenticationRequirements $mfa

        Write-host ($upn + ' Created in O365')
        Read-Host

    }Catch{
        Write-Host "Error has occured"
        Write-Host $_.Exception
        Read-Host
    }
}

Read-Host