if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

Try{
    Uninstall-Module MSOnline
}catch{}

try{
    Uninstall-Module AzureAD
}catch{}

Install-Module MSOnline
Install-Module AzureADPreview
Set-ExecutionPolicy Unrestricted -Scope CurrentUser
Register-PSRepository -Default
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module -Name ImportExcel -Scope CurrentUser -Force


Write-Host 'Finished installing all modules!
Press any key to Exit...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');