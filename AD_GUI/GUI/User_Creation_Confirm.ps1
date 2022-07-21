
$date_Time = Get-Date -Format "dd/MM/yyyy HH:mm"
$rand = new-object System.Random

#Word bank for passwords
$words = Get-Content $PSScriptRoot\CSV\Passwords.csv | Sort-Object {Get-Random} -unique | select -first 1000


#----------------------------------------------------------------------------

Function User_Creation_Confirm{
#----------------------------------------------------------------------------
    #Confirm GUI in XAML format
    $Confirm_Gui= $PSScriptRoot + "\Format\User_Creation_Confirm_1.0.xaml"

    #Turns the XAML file into powershell runable
    $input_XAML=Get-Content -Path $Confirm_Gui -Raw
    $input_XAML=$input_XAML -replace 'mc:Ignorable="d"','' -replace "x:N","N" -replace '^<Win.*','<Window'
    [XML]$XAML=$input_XAML

    #Creates the GUI
    $reader = New-Object System.Xml.XmlNodeReader $XAML
    try{
        $UserConfirmWindow=[Windows.Markup.XamlReader]::Load($reader)
    }catch{
        Write-Host $_.Exception
        throw
    }

    #Pulls the variables from the XAML file
    $xaml.SelectNodes("//*[@Name]") | ForEach-Object {
        try{
            Set-Variable -Name "var_$($_.Name)" -Value $UserConfirmWindow.FindName($_.Name) -ErrorAction Stop
        }catch{
           throw
        }

    }

#----------------------------------------------------------------------------
    #Next button Event
    $var_btn_Confirm.Add_Click{
        create_User
        $UserConfirmWindow.Hide()
        $var_txt_FullName.Clear()
        $var_txt_JobTitle.Clear()
    }
    #Regenerate the password Button
    $var_btn_PassRegen.Add_Click{
        $var_tb_Password.Clear()
        $var_tb_Password.AddText((Create_Password))
    }

    #Calls the Confirm_Data function
    Confirm_Data

    #Opens the window
    $UserConfirmWindow.ShowDialog() | Out-Null
}

#Populates the text boxes for the GUI
function Confirm_Data{
    $facility = $global:List | Where-Object OU -eq $var_cb_Facility_List |Select-Object
    $Name=$var_txt_FullName.Text.Split(' ')

    #First Name
    $var_tb_First.AddText(( Get-Culture ).TextInfo.ToTitleCase( $Name[0].ToLower()))

    #Last Name
    $var_tb_Last.AddText(( Get-Culture ).TextInfo.ToTitleCase( $Name[-1].ToLower()))

    #Full Name
    $var_tb_FullName.AddText(( Get-Culture ).TextInfo.ToTitleCase($var_txt_FullName.Text))

    #Log-On Name
    if($Name.count -eq 3){
        $var_tb_Log_On.AddText($var_tb_First.Text.ToLower()+'.'+$Name[1].SubString(0,1)+"."+$var_tb_Last.Text.ToLower())
    }else{
        $var_tb_Log_On.AddText($var_txt_FullName.Text.Replace(' ','.').ToLower())
    }

    #Email
    $email = $global:facility.UPNSuffix
    $var_tb_Email.AddText($var_tb_Log_On.Text.ToLower()+'@'+$email)

    #Facility
    $var_tb_Facility.AddText($global:OU)

    #Password
    $var_tb_Password.AddText((Create_Password))

    Foreach($group in $var_lb_Groups.SelectedItems){
        $group = $group.ToString().Replace("System.Windows.Controls.ListBoxItem: ","")
        [Void] $var_lb_Groups_Add.Items.Add($group.Trim())
    }

    #Job Title
    $var_tb_Job.AddText($var_txt_JobTitle.Text)

    #check boxes
    $var_ch_Force_Reset.IsChecked=$var_ch_Must_Reset.IsChecked
    $var_ch_Final_Cant_Change.IsChecked=$var_ch_Cant_Change.IsChecked
}
#Generates a password
Function Create_Password
{ 
  $minLength = 8
  $maxLength = 12 
  $length = Get-Random -Minimum $minLength -Maximum $maxLength
  $nonAlphaChars = 2
  return [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars)



  # query the smaller list of words for single entry (2 times)
  #$word1 = $words | Sort-Object {Get-Random} -unique | select -first 1  
  #$word2 = $words | Sort-Object {Get-Random} -unique | select -first 1  

  # create random digits
  #$number1 = Get-Random -Minimum 1 -Maximum 99
  
  # concatenante and return new random password
  #return (Get-Culture).TextInfo.ToTitleCase($word1) + (Get-Culture).TextInfo.ToTitleCase($word2) + $number1

}

#Creates the user in both AD and O365
function create_User{
    $userx =  Get-aduser -filter {samAccountName -eq $var_tb_Log_On.Text}
    if ($userx)
        {
        Error_Handler("User already exists $userx")
        }
        else
        {
            #Tries to create an account in AD/O365
            try{
                #Active Directory Creation
                #Read data from each field and assign variable
                $firstname = $var_tb_First.Text
                $lastname = $var_tb_Last.Text
                $username = $var_tb_Log_On.Text
                $email = $var_tb_Email.Text
                $OU = $var_tb_Facility.Text
                $password = $var_tb_Password.Text.Trim()
                $jobtitle = $var_tb_Job.Text
                [boolean]$mustreset = $var_ch_Force_Reset.IsChecked

                #Creates the account in AD
                New-ADUser `
                    -SamAccountName $username `
                    -Path "OU=Users,OU=$OU,OU=PACS Facilities,DC=provhc,DC=com" `
                    -Name "$firstname $lastname" `
                    -UserPrincipalName $email `
                    -GivenName $firstname `
                    -SurName $lastname `
                    -AccountPassword (ConvertTo-secureString $password.Trim() -AsPlainText -Force) `
                    -ChangePasswordAtLogon $mustreset `
                    -PasswordNeverExpires $var_Never_Expires.IsChecked `
                    -CannotChangePassword $var_ch_Cant_Change.IsChecked `
                    -Enabled $True `
                    -DisplayName "$firstname $lastname" `
                    -Description $jobtitle `
                    -Title $jobtitle `
                    -EmailAddress $email `
                    -OtherAttributes @{proxyAddresses = "SMTP:$email"} `
                    -verbose
                #Set-ADAccountPassword -Identity $username -NewPassword (ConvertTo-SecureString $password -AsPlainText -force)

                #Assigns the groups to the User in AD
                Foreach($group in $var_lb_Groups_Add.Items){
                    try{
                        Write-Host "$group added to $username"
                        Get-ADGroup -filter "Name -eq '$group'" -properties * |Add-ADGroupMember -Members $username
                    }catch{
                        Error_Handler("$group not found $($_.Exception)")
                    }
                }
                
                #Prints the info out into console
                Write-host "Successfully added $firstname $lastname"
                Write-Host ""
                Write-Host "Username: $username"
                Write-Host "Email: $email"
                Write-Host "Password: $password"
                Write-Host ""

                #Exports data to a .csv
                try {
                    echo "$firstname,$lastname,$username,$email,$OU,$password,$jobtitle,$($global:license_ID.ID),$date_Time" >> $PSScriptRoot\CSV\Logs\Account_Creations.csv
                }catch{
                    Error_Handler("CSV Log file not found or currently open. $($_.Exception)")
                }

                #Calls the O365 Function to create the account in office
                Try{
                    O365_Creation
                }catch{
                    Error_Handler("Could not add user to O365. $($_.Exception)")
                }
            }catch{
                Write-Host $_.Exception
                Error_Handler("Could not add user to AD $($_.Exception)")
            }
    }
}

#O365 user creation function
function O365_Creation{

    $upn = $var_tb_Email.Text
    $firstname = $var_tb_First.Text
    $lastname = $var_tb_Last.Text
    $password = $var_tb_Password.Text.Trim()

    New-MsolUser `
        -UserPrincipalName $upn `
        -DisplayName "$firstname $lastname"`
        -FirstName "$firstname" `
        -LastName "$lastname" `
        -PreferredDataLocation "US" `
        -Password (ConvertTo-SecureString $password -AsPlainText -force)
        

       Set-MsolUser -UserPrincipalName $upn -UsageLocation US -Verbose
       Set-MsolUserLicense -UserPrincipalName $upn -AddLicenses $global:license_ID.ID -Verbose

       write-host "$upn assigned license"
    Write-host ($upn + ' Created in O365')

    #MFA Enabling
    try{
        $mf= New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
        $mf.RelyingParty = "*"
        $mfa = @($mf)

        Set-MsolUser -UserPrincipalName "$upn" -StrongAuthenticationRequirements $mfa
    }Catch{
        Error_Handler("Could not set $upn 2FA. $($_.Exception)")
    }
    

}

#-----------------------------------
