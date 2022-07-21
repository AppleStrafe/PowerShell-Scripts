#FILE OF FACILITY LIST YOU WOULD LIKE TO AUDIT MUST BE IN SAME DIRECTORY
$file = "Plumv3.csv"

$excel = New-object -comobject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
$workbook = $excel.Workbooks.Add()

#list of facilities you would like to audit
$List = Import-Csv -path $PSScriptRoot\$file

Foreach ($facility in $List) {
   Write-Host -ForegroundColor Cyan "$($facility.facility) is currently running"
   $sheet = $workbook.Worksheets.Add()
   $sheet.Name = $facility.facility
   $Cells = $sheet.cells

   #Header of sheets
   $Cells.item(1,1) = "Name"
   $Cells.item(1,2) = "SamAccountName"
   $Cells.item(1,3) = "Title"
   $Cells.item(1,4) = "Groups"

   #Gets all users in the Facility
   $users = Get-ADUser -Filter * -SearchBase "OU=Users,OU=$($facility.facility),OU=PACS Facilities,DC=provhc,DC=com" -properties * | Select Name,description,SamAccountName,Title
   foreach($user in $users){
         $groups = ""

         #Gets all groups of user
         $group = Get-ADPrincipalGroupMembership $user.SamAccountName | Select Name
         foreach($i in $group){
            $groups += $i.Name + " | "
         }

         #exports to Excel
         $row = $sheet.UsedRange.Rows.Count + 1
         $Cells.item($row,1) = $user.name
         $Cells.item($row,2) = $user.SamAccountName
         $Cells.item($row,3) = $user.description
         $Cells.item($row,4) = $groups
   }
   $sheet.UsedRange.EntireColumn.AutoFit()
}
$workbook.SaveAs("$PSScriptRoot\Audit_LOG.xlsx")
$workbook.Close()
$excel.Quit()