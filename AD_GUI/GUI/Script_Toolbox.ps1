Function Toolbox{
    $var_tabControl.Items[3].IsSelected = $true
    $Scripts = Get-ChildItem -Path "$ScriptDir\Script Toolbox"

    foreach($item in $Scripts){
        $var_dg_ScriptToolbox.Items.add($item.FullName)
    }

    $var_btn_runScript.Add_Click{
        Write-Host $var_dg_ScriptToolbox.SelectedItem
        start-process -FilePath powershell.exe -ArgumentList "-file `"$($var_dg_ScriptToolbox.SelectedItem)`""
    }
}