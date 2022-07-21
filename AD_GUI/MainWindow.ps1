#Runs as ADMIN
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName 'System.Web'

#Config
$domain = "provhc"

#Imports all the child classes
Import-Module $PSScriptRoot\GUI\Single_User.ps1
Import-Module $PSScriptRoot\GUI\Termination.ps1
Import-Module $PSScriptRoot\GUI\User_Creation_Confirm.ps1
Import-Module $PSScriptRoot\GUI\Functions\Error_Handler.ps1
Import-Module $PSScriptRoot\GUI\Copy_User.ps1
Import-Module $PSScriptRoot\GUI\Script_Toolbox.ps1
Import-Module $PSScriptRoot\GUI\Functions\Functions.ps1

Import-Module ActiveDirectory 
Connect-MsolService

#Generates Logs
$date = Get-Date -Format "yyyy/MM/dd"
Start-Transcript -Path $PSScriptRoot\Logs\$date.log -Append
Write-Host ("
######################################################`n
Created by Jaden Heinbach`n
Report Issues to 'Jaden.Heinbach@pacshc.com'`n
Script is still in beta`n
Use at your own risk`n
######################################################")
#---------------------------------------------------------------------------------------------------------

#Main GUI in XML format
$Main_Gui = $ScriptDir + "\GUI\Format\Main_GUI_1.2.xaml"

#Turns the XML file into PS1
$input_XAML=Get-Content -Path $Main_Gui -Raw
$input_XAML=$input_XAML -replace 'mc:Ignorable="d"','' -replace "x:N","N" -replace '^<Win.*','<Window'
[XML]$XAML=$input_XAML

#Creates the GUI
$reader = New-Object System.Xml.XmlNodeReader $XAML
try{
    $MainWindow=[Windows.Markup.XamlReader]::Load($reader)
}catch{
    Write-Host $_.Exception
    throw
}

$xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    try{
        Set-Variable -Name "var_$($_.Name)" -Value $MainWindow.FindName($_.Name) -ErrorAction Stop
    }catch{
        throw
    }

}

$var_Sep_Date.SelectedDate = [datetime]::Now

#-------------------------------------

#Menu navigation
$var_btn_User_Creation.add_Click{
    Single_User
}
#Main Window button
$var_btn_Main.add_Click{
    $var_tabControl.Items[0].IsSelected = $true
}
#User termination button
$var_btn_User_Termination.Add_Click{
    Terminate
}

$var_btn_ScriptToolbox.Add_Click{
    Toolbox
}
#-------------------------------------

#Shows Main GUI
$MainWindow.ShowDialog() | Out-Null