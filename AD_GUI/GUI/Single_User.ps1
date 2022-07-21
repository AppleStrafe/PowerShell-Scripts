#----------------------------------------------------------------------------
#Import-Module $PSScriptRoot\User_Creation_Confirm.ps1

#Add user function
Function Single_User{
#----------------------------------------------------------------------------
    $var_tabControl.Items[1].IsSelected = $true

    #Adds the templates to the drop down
    $var_cb_User_Template.Items.Clear()
    $var_cb_Office_License.Items.Clear()
    Add_Templates

    #Adds facilities to the ComboBox
    $global:List = Import-Csv -path $PSScriptRoot\CSV\Facilities.csv
    $global:O365_License = Import-Csv -path $PSScriptRoot\CSV\O365_License.csv

    $var_cb_Facility_List.Items.Clear()

    Foreach ($facility in $List){
        $var_cb_Facility_List.Items.Add($facility.OU)
    }

    Foreach ($license in $O365_License){
        $var_cb_Office_License.Items.Add($license.Name)
    }

    #gets the o365 license ID
    $global:license_ID = $global:O365_License | Where-Object Name -eq $var_cb_Office_License.Text | Select-Object

    $var_cb_Facility_List.Add_DropDownClosed{
        Get_Groups
    }

    $var_cb_User_Template.Add_DropDownClosed{
        Get_Groups
    }

#----------------------------------------------------------------------------
    #Next button Event
    $var_btn_Next.Add_Click{
        #Turns the name into the LOG on name
        $Name = $var_txt_FullName.Text.Split(' ')
        $Log_On =  $var_txt_FullName.Text.replace(' ','.')
        $continue = $true

        #Checks if user exists
        $userx =  Get-aduser -filter {samAccountName -eq $Log_On}
        if ($userx){
            Error_Handler("$userx already exists in AD")
            $continue = $false
        }

        #Checks the name field to make sure it complies with policy
        if ($Name.Count -gt 3 -or $Name.count -eq 1 ){
            Error_Handler("Full name field does not meet company policy")
            $continue = $false
        }

        #If all checks are good continue to confirmation window
        if ($continue){
            User_Creation_Confirm
        }
    }

    #Copy user button
    $var_btn_Copy.Add_Click{
        #checks if facility is selected or not
        if([string]::IsNullOrWhiteSpace($var_cb_Facility_List.Text)){
            Error_Handler("Please select the facility")
        }else{
            #if facility is not null run the below code
            user_Copy
        }
    }

    $var_Group_Search.Add_Click{
        Group_Search($var_Search_Box.Text)
    }
}
#-----------------------------------
