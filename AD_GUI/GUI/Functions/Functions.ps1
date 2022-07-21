Function Add_Templates {
    $var_cb_User_Template.Items.Add("(default)")
    $var_cb_User_Template.Items.Add("Admin")
    $var_cb_User_Template.Items.Add("AIT")
    $var_cb_User_Template.Items.Add("BOM")
    $var_cb_User_Template.Items.Add("Payroll-HR")
    $var_cb_User_Template.Items.Add("Receptionist")
    $var_cb_User_Template.Items.Add("Medical_Records")
    $var_cb_User_Template.Items.Add("Activites")

    $var_cb_User_Template.SelectedIndex = 0
    $var_cb_Office_License.SelectedIndex = 0
}

#Gets the groups for the list box
Function Get_Groups {
    
    #Imports Template sheet
    try {
        $path = $ScriptDir + "\GUI\CSV\Templates.xlsx"
        $Sheet = Import-Excel -Path $path -WorksheetName $var_cb_User_Template.Text
    }
    catch {
		Write-Host $_.Exception
        Error_Handler("Can't access templates due to another program having it open. Please close and try again")
    }

    $var_lb_Groups.Items.Clear()
    try {
        $global:facility = $global:List | Where-Object OU -eq $var_cb_Facility_List.Text | Select-Object

        $global:OU = $facility.OU

        #Creates the Header for Template groups
        $Template_Itm = new-object System.Windows.Controls.ListboxItem
        $Template_Itm.IsEnabled = $false
        $Template_Itm.Content = '---Template Groups Below---'
        $var_lb_Groups.Items.Add($Template_Itm)

        $ID = $facility.FACID.Split(',')

        #Checks if there are more than one FACID
        if ($ID.Count -ge 2) {

            #Turns the XML file into PS1
            $input_XAML = Get-Content -Path "$ScriptDir\GUI\Format\FACID.xaml" -Raw
            $input_XAML = $input_XAML -replace 'mc:Ignorable="d"', '' -replace "x:N", "N" -replace '^<Win.*', '<Window'
            [XML]$XAML = $input_XAML

            #Creates the GUI
            $reader = New-Object System.Xml.XmlNodeReader $XAML
            try {
                $FACID_GUI = [Windows.Markup.XamlReader]::Load($reader)
            }
            catch {
                Write-Host $_.Exception
                throw
            }

            $xaml.SelectNodes("//*[@Name]") | ForEach-Object {
                try {
                    Set-Variable -Name "var_$($_.Name)" -Value $FACID_GUI.FindName($_.Name) -ErrorAction Stop
                }
                catch {
                    throw
                }

            }

            Foreach($facid in $ID){
                $facility_ID = Get-ADGroup -Filter "Name -eq '$facid'" -Properties Name,Description | select Name,Description
                $var_FACID_Datagrid.AddChild([pscustomobject]@{Name="$($facility_ID.Name)";Description="$($facility_ID.Description)"})
       
            }

            $var_FACID_Datagrid.IsReadOnly = $true

            $var_FACID_Datagrid.Add_SelectionChanged{
                $var_Select_FACID.IsEnabled = $true
            }

            $var_Select_FACID.Add_Click{
                $FACID_GUI.Hide()
                Group_List_Add -group "$($var_FACID_Datagrid.SelectedItem.Name)" -color "green" -selected $true
            }

            $FACID_GUI.ShowDialog()
        }else{
            try{
                $FACID = Get-ADGroup -filter "Name -eq '$($facility.FACID)'" -properties Name | select Name
                Group_List_Add -group "$($FACID.Name)" -color "green" -selected $true
            }catch{}
        }

        #Grabs the Groups out of the template sheet and adds them to the list box
        $Sheet | Select 'groups', 'HQ_groups'
        foreach ($fac_Group in $sheet.groups) {
            try {
                $group = Get-ADGroup -filter "Name -like '$fac_Group'" -properties Name -searchbase "OU=Groups,OU=$global:OU,OU=PACS Facilities,DC=$domain,DC=com" | Select Name
                Group_List_Add -group "$($group.Name)" -color "green" -selected $true
            }
            catch {}
        }
        foreach ($hq_Group in $sheet.HQ_groups) {
            try {
                $group = Get-ADGroup -filter "Name -eq '$hq_Group'" -properties Name, Description -searchbase "OU=PACS HQ,DC=$domain,DC=com" | Select Name
                Group_List_Add -group "$($group.Name)" -color "green" -selected $true
            }
            catch {}
        }

        #Creates the Header for Select more groups below
        $Groups_Itm = new-object System.Windows.Controls.ListboxItem
        $Groups_Itm.IsEnabled = $false
        $Groups_Itm.Content = '---Select More Groups Below---'
        $var_lb_Groups.Items.Add($Groups_Itm)

        #Pulls groups from the facility and adds them to the List Box
        $groups = Get-ADGroup -filter * -properties Name, Description -searchbase "OU=Groups,OU=$global:OU,OU=PACS Facilities,DC=$domain,DC=com" | Select Name, Description
        Foreach ($group in $groups) {
            Group_List_Add -group "$($group.Name)" -color "red" -selected $false
        }
            
    }
    catch {
        $var_lb_Groups.Items.Add("Please select Facility")
        Write-Host $_.Exception
    }
}

#Adds the groups to the list
Function Group_List_Add() {
    [cmdletbinding()]
    Param (
        [parameter(Mandatory)]
        [string]$group,
        [parameter(Mandatory)]
        [string]$color,
        [parameter(Mandatory)]
        [bool]$selected
    )

    $Highlight_Itm = new-object System.Windows.Controls.ListboxItem
    $Highlight_Itm.Content = $group
    $Highlight_Itm.Foreground = $color
    $Highlight_Itm.IsSelected = $selected
    [Void] $var_lb_Groups.Items.Add($Highlight_Itm)
}

#Search AD for a group
Function Group_Search($search){
    
    #Turns the XML file into PS1
    $input_XAML = Get-Content -Path "$ScriptDir\GUI\Format\Group_Search.xaml" -Raw
    $input_XAML = $input_XAML -replace 'mc:Ignorable="d"', '' -replace "x:N", "N" -replace '^<Win.*', '<Window'
    [XML]$XAML = $input_XAML

    #Creates the GUI
    $reader = New-Object System.Xml.XmlNodeReader $XAML
    try {
        $Group_Search_GUI = [Windows.Markup.XamlReader]::Load($reader)
    }catch {
        Write-Host $_.Exception
    }

    $xaml.SelectNodes("//*[@Name]") | ForEach-Object {
        try {
            Set-Variable -Name "var_$($_.Name)" -Value $Group_Search_GUI.FindName($_.Name) -ErrorAction Stop
        }catch {
            Write-Host $_.Exception
        }

    }

    if([string]::IsNullOrWhiteSpace($search)){
        Error_Handler("Please enter a name")
    }else{
        
        try{
            $groups = Get-ADGroup -Filter "Name -like '*$search*'" -Properties Name,Description | Select Name,Description
            if($groups.count -gt 0){
                foreach($i in $groups){
                    $var_Group_Datagrid.AddChild([pscustomobject]@{Name="$($i.Name)";Description="$($i.Description)"})
                }

                $var_Group_Datagrid.Add_SelectionChanged{
                    $var_Select_Group.IsEnabled = $true
                }

                $var_Select_Group.Add_Click{
                    $Group_Search_GUI.Hide()
                    Group_List_Add -group "$($var_Group_Datagrid.SelectedItem.Name)" -color "green" -selected $true
                }

                $Group_Search_GUI.ShowDialog()
            }else{Error_Handler("No group with name $search")}
        }catch{
            Error_Handler("Check logs for more details")
            Write-Host $_.Exception
        }

    }
}