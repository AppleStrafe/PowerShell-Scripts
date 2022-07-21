Function Error_Handler($error){
    #Error GUI in XML format
    $Error_Gui = $ScriptDir + "\GUI\Format\Error_Window_1.0.xaml"

    #Turns the XML file into PS1
    $input_XAML=Get-Content -Path $Error_Gui -Raw
    $input_XAML=$input_XAML -replace 'mc:Ignorable="d"','' -replace "x:N","N" -replace '^<Win.*','<Window'
    [XML]$XAML=$input_XAML

    #Creates the GUI
    $reader = New-Object System.Xml.XmlNodeReader $XAML
    try{
        $Error_Window=[Windows.Markup.XamlReader]::Load($reader)
    }catch{
        Write-Host $_.Exception
        throw
    }

    $xaml.SelectNodes("//*[@Name]") | ForEach-Object {
        try{
            Set-Variable -Name "var_$($_.Name)" -Value $Error_Window.FindName($_.Name) -ErrorAction Stop
        }catch{
            throw
        }

    }

    #TODO - Allow for input
    $var_txt_Error.AddText($error)

    $Error_Window.ShowDialog() | Out-Null
}