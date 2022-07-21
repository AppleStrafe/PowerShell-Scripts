if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
$date = Get-Date -Format "yyyy/MM/dd"
Start-Transcript -Path $PSScriptRoot\Logs\$date.log -Append

$adminNames = @("*admin*") #Jobtitle list for admins
$bomName = @("*bom*","*buisness*") #Jobtitle list for BOMS
$nurseName = @("*nurse*","*lvn*","rehab") #Jobtitle list for Nurses
$donName = @("*don*","*director of nursing*") #Jobtitle list for DONS
$dorName = @("* dor*","*director of rehab*") #Jobtitle list for DORS
$medicalrecName = @("*Medical records*") #Jobtitle list for Medical Records
$recepName = @("*receptionist*") #Jobtitle list for Receptionist
$marketingName = @("*Marketing*","*Marketer*","*Sales*") #Jobtitle list for Marketing
$hrName = @("*hr*","*payroll*") #Jobtitle list for HR
$admissionName = @("*admission*") #Jobtitle list for Admissions
$maintenanceName = @("*maint*") #Jobtitle list for Maintenance
$activitiesName = @("*activi*") #Jobtitle list for Activities
$socialName = @("*Social*") #Jobtitle list for Social Services

$plumList = Import-Csv -path $PSScriptRoot\Plumv2.csv #Imports facilities to search

###This code adds all groups that are not a DG or FolderRedirection to Admins "Requested by Jordan"###
### DO NOT RECOMMEND USING as it can brick their account ###
Function Admin($ou){
    foreach($title in $adminNames){
        $list = Get-ADUser -Filter "Description -like '$title'" -SearchBase "OU=Users,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"

        $groups = Get-ADGroup -Filter * -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com" | Select Name

        foreach($i in $list){

            $userOldGroups = Get-ADPrincipalGroupMembership $i.SamAccountName | select name

            foreach($group in $groups){
                if($group.Name -like "*FolderRedirection*" -or $group.Name -Like "*DG*"){}
                else{
                    Get-ADGroup -Filter "Name -eq '$($group.Name)'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com" |Add-ADGroupMember -Members $i.SamAccountName
                    Write-Host "added $($i.SamAccountName) to $($found.Name)"
                }
            }
            
        }
    }
}

#Adds these groups to people with the jobtitles in $bomName
Function Bom($ou){
    foreach($title in $bomName){
        $list = Get-ADUser -Filter "Description -like '$title'" -SearchBase "OU=Users,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"

        #groups you would like to search for "Ex. '*user*' returns FolderRedirectionUsers and Fld_ABRV_Users"
        $groups = @("fld_*_ADR","fld_*_businessoffice","*deparmenthead*","*bom*")

        foreach($i in $list){
            $userOldGroups = Get-ADPrincipalGroupMembership $i.SamAccountName | select name

            foreach($group in $groups){
                $find_groups = Get-ADGroup -Filter "Name -Like '$group'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"
                foreach($found in $find_groups){
                    Get-ADGroup -Filter "Name -eq '$($found.Name)'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com" |Add-ADGroupMember -Members $i.SamAccountName
                    Write-Host "added $($i.SamAccountName) to $($found.Name)"
                }
            }
            
            
        }
    }
}

#Adds these groups to people with the jobtitles in $nurseName
Function Nurses($ou){
    foreach($title in $nurseName){
        $list = Get-ADUser -Filter "Description -like '$title'" -SearchBase "OU=Users,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"

        #groups you would like to search for "Ex. '*user*' returns FolderRedirectionUsers and Fld_ABRV_Users"
        $groups = @("*nursing*")

        foreach($i in $list){
            $userOldGroups = Get-ADPrincipalGroupMembership $i.SamAccountName | select name
            foreach($group in $groups){
                $find_groups = Get-ADGroup -Filter "Name -Like '$group'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"
                foreach($found in $find_groups){
                    Get-ADGroup -Filter "Name -eq '$($found.Name)'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com" |Add-ADGroupMember -Members $i.SamAccountName
                    Write-Host "added $($i.SamAccountName) to $($found.Name)"
                }
            }
            
            
        }
    }
}

#Adds these groups to people with the jobtitles in $donName
Function Don($ou){
    foreach($title in $donName){
        $list = Get-ADUser -Filter "Description -like '$title'" -SearchBase "OU=Users,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"

        #groups you would like to search for "Ex. '*user*' returns FolderRedirectionUsers and Fld_ABRV_Users"
        $groups = @("*nursing*","*don*","*department*")

        foreach($i in $list){
            $userOldGroups = Get-ADPrincipalGroupMembership $i.SamAccountName | select name
            foreach($group in $groups){
                $find_groups = Get-ADGroup -Filter "Name -Like '$group'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"
                foreach($found in $find_groups){
                    Get-ADGroup -Filter "Name -eq '$($found.Name)'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com" |Add-ADGroupMember -Members $i.SamAccountName
                    Write-Host "added $($i.SamAccountName) to $($found.Name)"
                }
            }
            
            
        }

    }
}

#Adds these groups to people with the jobtitles in $dorName
Function Dor($ou){
    foreach($title in $dorName){
        $list = Get-ADUser -Filter "Description -like '$title'" -SearchBase "OU=Users,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"

        #groups you would like to search for "Ex. '*user*' returns FolderRedirectionUsers and Fld_ABRV_Users"
        $groups = @("*dor*","*departmentheads*")

        foreach($i in $list){
            $userOldGroups = Get-ADPrincipalGroupMembership $i.SamAccountName | select name
            foreach($group in $groups){
                $find_groups = Get-ADGroup -Filter "Name -Like '$group'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"
                foreach($found in $find_groups){
                    Get-ADGroup -Filter "Name -eq '$($found.Name)'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com" |Add-ADGroupMember -Members $i.SamAccountName
                    Write-Host "added $($i.SamAccountName) to $($found.Name)"
                }
            }
            
            
        }
    }
}

#Adds these groups to people with the jobtitles in $medicalrecName
Function MedicalRec($ou){
    foreach($title in $medicalrecName){
        $list = Get-ADUser -Filter "Description -like '$title'" -SearchBase "OU=Users,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"

        #groups you would like to search for "Ex. '*user*' returns FolderRedirectionUsers and Fld_ABRV_Users"
        $groups = @("*medicalrecords*","*departmentheads*")

        foreach($i in $list){
            $userOldGroups = Get-ADPrincipalGroupMembership $i.SamAccountName | select name
            foreach($group in $groups){
                $find_groups = Get-ADGroup -Filter "Name -Like '$group'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"
                foreach($found in $find_groups){
                    Get-ADGroup -Filter "Name -eq '$($found.Name)'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com" |Add-ADGroupMember -Members $i.SamAccountName
                    Write-Host "added $($i.SamAccountName) to $($found.Name)"
                }
            }
            
            
        }
    }
}

#Adds these groups to people with the jobtitles in $recepName
Function Reception($ou){
    foreach($title in $recepName){
        $list = Get-ADUser -Filter "Description -like '$title'" -SearchBase "OU=Users,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"

        #groups you would like to search for "Ex. '*user*' returns FolderRedirectionUsers and Fld_ABRV_Users"
        $groups = @("*receptionist*","*departmentheads*")

        foreach($i in $list){
            $userOldGroups = Get-ADPrincipalGroupMembership $i.SamAccountName | select name
            foreach($group in $groups){
                $find_groups = Get-ADGroup -Filter "Name -Like '$group'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"
                foreach($found in $find_groups){
                    Get-ADGroup -Filter "Name -eq '$($found.Name)'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com" |Add-ADGroupMember -Members $i.SamAccountName
                    Write-Host "added $($i.SamAccountName) to $($found.Name)"
                }
            }
            
            
        }
    }
}

#Adds these groups to people with the jobtitles in $marketingName
Function Marketing($ou){
    foreach($title in $marketingName){
        $list = Get-ADUser -Filter "Description -like '$title'" -SearchBase "OU=Users,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"

        #groups you would like to search for "Ex. '*user*' returns FolderRedirectionUsers and Fld_ABRV_Users"
        $groups = @("*Marketing*")

        foreach($i in $list){
            $userOldGroups = Get-ADPrincipalGroupMembership $i.SamAccountName | select name
            foreach($group in $groups){
                $find_groups = Get-ADGroup -Filter "Name -Like '$group'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"
                foreach($found in $find_groups){
                    Get-ADGroup -Filter "Name -eq '$($found.Name)'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com" |Add-ADGroupMember -Members $i.SamAccountName
                    Write-Host "added $($i.SamAccountName) to $($found.Name)"
                }
            }
            
            
        }
    }
}

#Adds these groups to people with the jobtitles in $hrName
Function HR($ou){
    foreach($title in $hrName){
        $list = Get-ADUser -Filter "Description -like '$title'" -SearchBase "OU=Users,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"

        #groups you would like to search for "Ex. '*user*' returns FolderRedirectionUsers and Fld_ABRV_Users"
        $groups = @("*payroll*","*departmentheads*")

        foreach($i in $list){
            $userOldGroups = Get-ADPrincipalGroupMembership $i.SamAccountName | select name
            foreach($group in $groups){
                $find_groups = Get-ADGroup -Filter "Name -Like '$group'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"
                foreach($found in $find_groups){
                    Get-ADGroup -Filter "Name -eq '$($found.Name)'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com" |Add-ADGroupMember -Members $i.SamAccountName
                    Write-Host "added $($i.SamAccountName) to $($found.Name)"
                }
            }
            
            
        }
    }
}

#Adds these groups to people with the jobtitles in $admissionName
Function Admissions($ou){
    foreach($title in $admissionName){
        $list = Get-ADUser -Filter "Description -like '$title'" -SearchBase "OU=Users,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"

        #groups you would like to search for "Ex. '*user*' returns FolderRedirectionUsers and Fld_ABRV_Users"
        $groups = @("*admission*","*buisnessoffice*")

        foreach($i in $list){
            $userOldGroups = Get-ADPrincipalGroupMembership $i.SamAccountName | select name
            foreach($group in $groups){
                $find_groups = Get-ADGroup -Filter "Name -Like '$group'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"
                foreach($found in $find_groups){
                    Get-ADGroup -Filter "Name -eq '$($found.Name)'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com" |Add-ADGroupMember -Members $i.SamAccountName
                    Write-Host "added $($i.SamAccountName) to $($found.Name)"
                }
            }
            
            
        }
    }
}

#Adds these groups to people with the jobtitles in $maintenanceName
Function Maintenance($ou){
    foreach($title in $maintenanceName){
        $list = Get-ADUser -Filter "Description -like '$title'" -SearchBase "OU=Users,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"

        #groups you would like to search for "Ex. '*user*' returns FolderRedirectionUsers and Fld_ABRV_Users"
        $groups = @("*maintenance*")

        foreach($i in $list){
            $userOldGroups = Get-ADPrincipalGroupMembership $i.SamAccountName | select name
            foreach($group in $groups){
                $find_groups = Get-ADGroup -Filter "Name -Like '$group'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"
                foreach($found in $find_groups){
                    Get-ADGroup -Filter "Name -eq '$($found.Name)'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com" |Add-ADGroupMember -Members $i.SamAccountName
                    Write-Host "added $($i.SamAccountName) to $($found.Name)"
                }
            }
            
            
        }
    }
}

#Adds these groups to people with the jobtitles in $activitiesName
Function Activities($ou){
    foreach($title in $activitiesName){
        $list = Get-ADUser -Filter "Description -like '$title'" -SearchBase "OU=Users,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"

        #groups you would like to search for "Ex. '*user*' returns FolderRedirectionUsers and Fld_ABRV_Users"
        $groups = @("*activities*")

        foreach($i in $list){
            $userOldGroups = Get-ADPrincipalGroupMembership $i.SamAccountName | select name
            foreach($group in $groups){
                $find_groups = Get-ADGroup -Filter "Name -Like '$group'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"
                foreach($found in $find_groups){
                    Get-ADGroup -Filter "Name -eq '$($found.Name)'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com" |Add-ADGroupMember -Members $i.SamAccountName
                    Write-Host "added $($i.SamAccountName) to $($found.Name)"
                }
            }
            
            
        }
    }
}

#Adds these groups to people with the jobtitles in $socialName
Function SocialServices($ou){
    foreach($title in $socialName){
        $list = Get-ADUser -Filter "Description -like '$title'" -SearchBase "OU=Users,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"

        #groups you would like to search for "Ex. '*user*' returns FolderRedirectionUsers and Fld_ABRV_Users"
        $groups = @("*Social*")

        foreach($i in $list){
            $userOldGroups = Get-ADPrincipalGroupMembership $i.SamAccountName | select name
            foreach($group in $groups){
                $find_groups = Get-ADGroup -Filter "Name -Like '$group'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"
                foreach($found in $find_groups){
                    Get-ADGroup -Filter "Name -eq '$($found.Name)'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com" |Add-ADGroupMember -Members $i.SamAccountName
                    Write-Host "added $($i.SamAccountName) to $($found.Name)"
                }
            }
            
            
        }
    }
}

#Adds these groups to all users in the facility OU
Function General($ou){
    $list = Get-ADUser -Filter * -SearchBase "OU=Users,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com" -Properties * | Select Name,extensionAttribute15,SamAccountName

    #groups you would like to search for "Ex. '*user*' returns FolderRedirectionUsers and Fld_ABRV_Users"
    $groups = @("*User*","*All DG*")

    foreach($i in $list){
        if($i.extensionAttribute15 -eq "NoSync"){write-host "$($i.name) is generic!"}
        else{
            foreach($group in $groups){
                $find_groups = Get-ADGroup -Filter "Name -Like '$group'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com"
                foreach($found in $find_groups){
                    Get-ADGroup -Filter "Name -eq '$($found.Name)'" -SearchBase "OU=Groups,OU=$ou,OU=PACS Facilities,DC=provhc,DC=com" |Add-ADGroupMember -Members $i.SamAccountName
                    Write-Host "added $($i.SamAccountName) to $($found.Name)"
                }
            }
        }     
    }
}

#runs the functions specified for each facility in $plumList
foreach($building in $plumList){

    Write-Host -ForegroundColor Cyan "$($building.facility) is currently running"

    General($building.facility)
    #Admin($building.facility)
    #Bom($building.facility)
    #Nurses($building.facility)
    #Don($building.facility)
    #Dor($building.facility)
    #MedicalRec($building.facility)
    #Reception($building.facility)
    #Marketing($building.facility)
    #HR($building.facility)
    #Admissions($building.facility)
    #Maintenance($building.facility)
    #Activities($building.facility)
    #SocialServices($building.facility)
}