$domain = "DC=ACEBUCHE,DC=local"
$departments = @("IT", "Finance", "HR", "Management")

# 1. Gawa ng Shadow Root
New-ADOrganizationalUnit -Name "Shadow" -Path $domain

# 2. Loop para sa bawat Department at kanilang sub-folders
foreach ($dept in $departments) {
    # Gawa ng Main Department Folder
    $deptPath = "OU=Shadow,$domain"
    New-ADOrganizationalUnit -Name $dept -Path $deptPath
    
    # Gawa ng Sub-folders (Users, Computers, Groups) sa loob ng Dept
    $targetPath = "OU=$dept,OU=Shadow,$domain"
    New-ADOrganizationalUnit -Name "Users" -Path $targetPath
    New-ADOrganizationalUnit -Name "Computers" -Path $targetPath
    New-ADOrganizationalUnit -Name "Groups" -Path $targetPath
    
    Write-Host "[OK] Created structure for $dept" -ForegroundColor Green
}
$MyOUs = @{
    "IT"      = "OU=Users,OU=IT,OU=Shadow,DC=ACEBUCHE,DC=local"
    "Finance" = "OU=Users,OU=Finance,OU=Shadow,DC=ACEBUCHE,DC=local"
    "HR"      = "OU=Users,OU=HR,OU=Shadow,DC=ACEBUCHE,DC=local"
}
#ACEBUCHE.local (Domain)
 └── Shadow (Main Folder)
      ├── IT (Department)
      │    ├── Users (Dito mo ilalagay ang tao)
      │    └── Computers (Dito mo ilalagay ang PC)
      ├── Finance (Department)
      │    ├── Users
      │    └── Computers
      └── HR (Department)
           ├── Users
           └── Computers
