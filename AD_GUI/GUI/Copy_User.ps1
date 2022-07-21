Function user_Copy{
    
    #Copy GUI in XAML format
    $User_Copy_GUI= $PSScriptRoot + ".\Format\User_Copy_1.0.xaml"

    #Turns the XAML file into powershell runable
    $input_XAML=Get-Content -Path $User_Copy_GUI -Raw
    $input_XAML=$input_XAML -replace 'mc:Ignorable="d"','' -replace "x:N","N" -replace '^<Win.*','<Window'
    [XML]$XAML=$input_XAML

    #Creates the GUI
    $reader = New-Object System.Xml.XmlNodeReader $XAML
    try{
        $User_Copy_Window=[Windows.Markup.XamlReader]::Load($reader)
    }catch{
        Write-Host $_.Exception
        throw
    }

    #Pulls the variables from the XAML file
    $XAML.SelectNodes("//*[@Name]") | ForEach-Object {
        try{
            Set-Variable -Name "var_$($_.Name)" -Value $User_Copy_Window.FindName($_.Name) -ErrorAction Stop
        }catch{
            Write-Host $_.Exception
            throw
        }

    }

    #Pulls users from AD
    $CN = Get-ADUser -Filter * -Properties Name,Description -searchbase "OU=Users,OU=$global:OU,OU=PACS Facilities,DC=$domain,DC=com" | Select Name,Description

    #Shows the users you can copy from
    $var_Datagrid.ItemsSource = $CN
    $var_Datagrid.IsReadOnly = $true

    #Enables the Copy button on selection
    $var_Datagrid.Add_SelectionChanged{
        $var_Copy_User.IsEnabled = $true
    }

    #Creates the add click event for copy
    $var_Copy_User.Add_Click{
        #Hides the copy window
        $User_Copy_Window.Hide()
        #Pulls the selected user from the list
        $data = $var_Datagrid.SelectedItem
        #Grabs the username from selected user
        $username = Get-ADUser -Filter "Name -like '$($data.Name)'" -properties * -searchbase "OU=Users,OU=$global:OU,OU=PACS Facilities,DC=provhc,DC=com" | Select SamAccountName
        #Gets all the groups from selected user
        $groups = Get-ADPrincipalGroupMembership $username.SamAccountName | Select Name
        #clears the listbox of previous groups
        $var_lb_Groups.Items.Clear()
        #Adds the groups to the list box
        foreach ($group in $groups){
            #Strips all DG's besides the 'ALL DG'
            If ($group.name -like "*DG*" -and $group.name -notlike "*all DG*"){
                
            }else{
                $var_lb_Groups.Items.Add($group.Name)
            }
        }
        $var_lb_Groups.SelectAll()
    }

    #Shows the copy window
    $User_Copy_Window.ShowDialog()
}