    #Confirm GUI in XAML format
    $Confirm_Window= $PSScriptRoot + "\Format\Confirm_Window.xaml"

    #Turns the XAML file into powershell runable
    $input_XAML=Get-Content -Path $Confirm_Window -Raw
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
            Set-Variable -Name "term_$($_.Name)" -Value $UserConfirmWindow.FindName($_.Name) -ErrorAction Stop
        }catch{
           throw
        }

    }

Function Terminate{
    $var_tabControl.Items[2].IsSelected = $true

    $var_btn_Term_Confirm.Add_Click{
        Terminate_User_Confirm
    }

    $var_cb_Litigation.Add_Checked{
        $var_cb_Non_Litigation.IsChecked = $false
        $var_cb_PACS_HQ.IsChecked = $false
    }

    $var_cb_Non_Litigation.Add_Checked{
        $var_cb_Litigation.IsChecked = $false
        $var_cb_PACS_HQ.IsChecked = $false
    }

    $var_cb_PACS_HQ.Add_Checked{
        $var_cb_Litigation.IsChecked = $false
        $var_cb_Non_Litigation.IsChecked = $false
    }

    $var_cb_Pacs_HQ.Add_Unchecked{
        Check_Litigation
    }

    $var_cb_Non_Litigation.Add_Unchecked{
        Check_Litigation
    }

    $var_cb_Litigation.Add_Unchecked{
        Check_Litigation
    }

}
Function Terminate_User_Confirm{
    
    $filled_Out = $true

    #Makes sure the log-on name is in the correct format.
    if ($var_Txt_Log_On_Name.Text -NotLike "*.*"){
        Error_Handler("$($var_Txt_Log_On_Name.Text) is not in username format. EX. 'Jaden.Heinbach'")
        $filled_Out = $false    
    }

    #Checks to make sure ticket # entered is a valid ticket #
    if($var_Txt_Ticket.Text -NotLike "#*"){
        Error_Handler("$($var_Txt_Ticket.Text) is not in ticket format. EX. '#123456'")
        $filled_Out = $false
    }

    #if everything returns as good. proceeds to run this code
    if($filled_Out){
        $term_User = Get-ADUser -Filter "SamAccountName -eq '$($var_Txt_Log_On_Name.Text)'" -Properties * | Select Name,Description,distinguishedName,EmailAddress,MemberOf
        if ($term_User -ne $null){
            $location = $term_User.distinguishedName.split(",")
            $term_txt_Confirm.Text = "Name:`n$($term_User.Name) `n Description:`n$($term_User.Description)`n Facility:`n$($location[2])"
            $term_btn_Confirm.Add_Click{
                $UserConfirmWindow.hide()
                Disable_User
            }
            $term_btn_Cancel.Add_Click{
                $UserConfirmWindow.hide()
            }
            $UserConfirmWindow.Show()
        }else{
            Error_Handler("$($term_User.Name) does not exist in AD")
        }
    }else{
        Error_Handler("$($term_User.Name) An error has occured $($_.Exception)")
    }

    
}

#-----------------------------------

#Makes sure a check box is checked
function Check_Litigation{
    if(($var_cb_Non_Litigation.IsChecked -eq $false) -and ($var_cb_PACS_HQ.IsChecked -eq $false) -and ($var_cb_Litigation.IsChecked -eq $false)){
        $var_cb_Litigation.IsChecked = $true
    }else{
        return
    }
}

#makes user go bye bye
function Disable_User{
    $term_User = Get-ADUser -Filter "SamAccountName -eq '$($var_Txt_Log_On_Name.Text)'" -Properties * | Select Name,Description,distinguishedName,EmailAddress,MemberOf
    $TermDate = "$($var_Sep_Date.SelectedDate | Convert-String -Example '01/01/2022 00:00:00=01/01/2022'), $($var_Txt_Ticket.Text)" #the Date of Separation & Ticket Number
    $CuryyMM = Get-Date -Format "yyyy.MM" #Finds current Year & Month and puts in Year.Month Format for Non-Litigation Moving
    $user = $var_Txt_Log_On_Name.Text
    $upn = $term_User.EmailAddress
    
    #random password creator
    $length = 16 #set length of password to generate
    $nonAlphaChars = 5 #set amount of special characters to include
    $pwd = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars) #Generates random password string.
    $secpas = ConvertTo-SecureString -String $pwd -AsPlainText -Force #converts randomly generated password into a secure string


    #change user's password to randomly generated secure string password
    try{
        Set-ADAccountPassword `
             -Identity $user `
             -NewPassword $secpas -Reset
    }Catch{
        Error_Handler("Could not change password")
    }

    #Disables Change Password at next login, Sets user cannot change password, Adds Term date to description, Hides from global exchange address list.
    try{
        Set-ADUser `
            -Identity $User `
            -ChangePasswordAtLogon 0 `
            -CannotChangePassword 1 `
            -Description ("Separated " + $TermDate) `
            -add @{msExchHideFromAddressLists = "TRUE"} 
    }Catch{
        Error_Handler("Could not change account properties")
    }


    #Add membership to _Disabled Users group
    try{
        Add-ADGroupMember `
            -Identity "_Disabled Users" `
            -Members $user 
    }Catch{
        Error_Handler("Could not add group _disabled user")
    }
    
    #sets primary group to _Disabled Users
    try{
        Set-ADUser `
            -Identity $User `
            -replace @{primaryGroupID = "7921"} 
    }Catch{
        Error_Handler("Could not set primary group to _Disabled users")
    }

    #disables the user account.
    try{
        Disable-ADAccount `
            -Identity $user
    }Catch{
        Error_Handler("Could not Disable account")
    }

    #moves user to the correct OU
    try{
        MoveUser
    }Catch{
        Error-Handler("Could not move user")
    }

    #removes all licensing but Exchange plan 1
    try{
        RemoveLicense
    }catch{
        Error_Handler("Could not take away O365 Licenses")
    }

    #checks for PowerDMS
    if($term_User.MemberOf -contains "PowerDMSViewUsers"){
        Error_Handler("This account contains PowerDMS access!`nPlease disable account in PowerDMS")
    }
}

function MoveUser{
    $exists = Get-ADOrganizationalUnit `
        -Filter "Name -eq '$CuryyMM'" `
        -SearchBase "OU=Non-Litigation Sites - 6 months hold before deleting,OU=_Hold Requested,OU=PACS Facilities,DC=provhc,DC=com" -Properties Name | Select Name

    if($exists -eq $null){
        New-ADOrganizationalUnit `
            -Path "OU=Non-Litigation Sites - 6 months hold before deleting,OU=_Hold Requested,OU=PACS Facilities,DC=provhc,DC=com" `
            -Name "$CuryyMM"
    }

    if($var_cb_Non_Litigation.IsChecked){
        Get-ADUser $user | Move-ADObject `
            -TargetPath "OU=$($CuryyMM),OU=Non-Litigation Sites - 6 months hold before deleting,OU=_Hold Requested,OU=PACS Facilities,DC=provhc,DC=com"
    }elseif($var_cb_PACS_HQ.IsChecked){
        Get-ADUser $user | Move-ADObject `
            -TargetPath "OU=(3 yrs) _Hold Requested -Forwarded,OU=PACS HQ,DC=provhc,DC=com"
    }elseif($var_cb_Litigation.IsChecked){
        Get-ADUser $user | Move-ADObject `
            -TargetPath "OU=Litigation Hold Sites,OU=_Hold Requested,OU=PACS Facilities,DC=provhc,DC=com" 
    }else{
        Error_Handler("An error has occured")
    }
}

function RemoveLicense{
    (get-MsolUser -UserPrincipalName $upn).licenses.AccountSkuId | foreach{Set-MsolUserLicense -UserPrincipalName $upn -RemoveLicenses $_}
    Set-MsolUserLicense -UserPrincipalName $upn -AddLicenses providencegroup:EXCHANGESTANDARD -Verbose
    Set-MsolUser -UserPrincipalName $upn -BlockCredential $true
}