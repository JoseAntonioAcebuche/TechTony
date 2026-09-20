# ============================================================
# Active Directory User Management Menu  (v2)
# - OU + Security Group selection
# - Login username exists check
# - Bulk Add / Bulk Disable
# - Disable = Disable + remove from ALL groups (single shared function)
# - Full audit logging
# - Email notifications (credential stored via Export-Clixml, NOT plaintext)
# ============================================================

Import-Module ActiveDirectory -ErrorAction SilentlyContinue

# ==================== PASSWORD SETTINGS ====================
$DefaultPassword   = "P@ssw0rd@2025"   # Palitan kung gusto mo ng ibang default
$UseRandomPassword = $false            # $true = random password per user/reset (mas secure)
# ===========================================================

# ==================== EMAIL SETTINGS ====================
$EnableEmailNotification = $true       # $false kung ayaw muna ng email
$SmtpServer = "smtp.gmail.com"
$SmtpPort   = 587
$SmtpFrom   = "futjeongkuen@gmail.com"
$SmtpTo     = "joseantonioacebuche@gmail.com"   # pwede multiple: @("a@x.com","b@x.com")
$SmtpUseSsl = $true
# Ang Gmail App Password ay NASA ENCRYPTED FILE na (gawin via menu option 14).
# Naka-bind lang sa user + machine na gumawa nito.
# =========================================================

# ==================== PATHS ====================
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$LogFile   = Join-Path $ScriptDir "AD-User-Management-Log.txt"
$CredFile  = Join-Path $ScriptDir "smtp-cred.xml"        # encrypted (menu 14) - fallback lang
$PassFile  = Join-Path $ScriptDir "smtp-password.txt"    # PRIORITY: 1 line lang, ang App Password
# ===============================================

# ==================== HELPERS ====================
function Write-Log {
    param (
        [string]$Action,
        [string]$Target = "",
        [string]$Result = "Success",
        [string]$Details = ""
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Operator  = "$env:USERDOMAIN\$env:USERNAME"
    $LogEntry  = "$Timestamp | By: $Operator | $Action | Target: $Target | Result: $Result | $Details"
    try { Add-Content -Path $LogFile -Value $LogEntry -ErrorAction Stop }
    catch { Write-Host "Warning: Failed to write to log file." -ForegroundColor DarkYellow }
}

function Send-Notification {
    param ([string]$Subject, [string]$Body)

    if (-not $EnableEmailNotification) { return }

    if (-not (Test-Path $CredFile) -and -not (Test-Path $PassFile)) {
        Write-Host "Email skipped: walang smtp-cred.xml o smtp-password.txt. Gamitin ang menu 14 o gumawa ng smtp-password.txt." -ForegroundColor DarkYellow
        return
    }

    try {
        if (Test-Path $PassFile) {
            # Priority: hiwalay na text file (App Password lang sa unang linya, okay kahit may spaces)
            $AppPassword = ((Get-Content -Path $PassFile -TotalCount 1) -replace '\s', '')
            if ([string]::IsNullOrWhiteSpace($AppPassword)) { throw "smtp-password.txt is empty." }
            $SecurePassword = ConvertTo-SecureString $AppPassword -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential ($SmtpFrom, $SecurePassword)
        }
        else {
            # Fallback: encrypted credential galing sa menu 14
            $Credential = Import-Clixml -Path $CredFile
        }
        $mailParams = @{
            SmtpServer = $SmtpServer
            Port       = $SmtpPort
            From       = $SmtpFrom
            To         = $SmtpTo
            Subject    = $Subject
            Body       = $Body
            UseSsl     = $SmtpUseSsl
            Credential = $Credential
        }
        # Note: Send-MailMessage ay obsolete na pero gumagana pa.
        Send-MailMessage @mailParams -ErrorAction Stop
        Write-Host "Email notification sent." -ForegroundColor DarkGray
    }
    catch {
        Write-Host "Warning: Failed to send email - $($_.Exception.Message)" -ForegroundColor DarkYellow
    }
}

function Setup-EmailCredential {
    Write-Host "`n--- SETUP EMAIL CREDENTIAL ---" -ForegroundColor Yellow
    Write-Host "Username = Gmail address, Password = Gmail App Password (16 chars)." -ForegroundColor Cyan
    try {
        $cred = Get-Credential -UserName $SmtpFrom -Message "Gmail address + App Password"
        if ($cred) {
            $cred | Export-Clixml -Path $CredFile -ErrorAction Stop
            Write-Host "Saved (encrypted) to: $CredFile" -ForegroundColor Green
            Write-Log -Action "SETUP EMAIL CREDENTIAL" -Target $SmtpFrom -Result "Success"
        }
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Action "SETUP EMAIL CREDENTIAL" -Target $SmtpFrom -Result "Failed" -Details $_.Exception.Message
    }
}

function Escape-Filter {
    # Para hindi masira ang -Filter kapag may apostrophe (hal. O'Brien)
    param ([string]$Text)
    return ($Text -replace "'", "''")
}

function New-RandomPassword {
    param ([int]$Length = 14)
    $upper   = 'ABCDEFGHJKLMNPQRSTUVWXYZ'.ToCharArray()
    $lower   = 'abcdefghijkmnopqrstuvwxyz'.ToCharArray()
    $digits  = '23456789'.ToCharArray()
    $symbols = '!@#$%&*?'.ToCharArray()
    $all     = $upper + $lower + $digits + $symbols

    $chars  = @()
    $chars += Get-Random -InputObject $upper
    $chars += Get-Random -InputObject $lower
    $chars += Get-Random -InputObject $digits
    $chars += Get-Random -InputObject $symbols
    while ($chars.Count -lt $Length) { $chars += Get-Random -InputObject $all }
    return -join ($chars | Sort-Object { Get-Random })
}

function Get-PasswordToUse {
    if ($UseRandomPassword) { return (New-RandomPassword) }
    return $DefaultPassword
}

function Test-SamAccountExists {
    param ([string]$SamAccountName)
    $safe = Escape-Filter $SamAccountName
    $found = Get-ADUser -Filter "SamAccountName -eq '$safe'" -ErrorAction SilentlyContinue
    return [bool]$found
}

# ==================== CORE ACTIONS (shared) ====================

# Disable + remove from ALL groups. Ginagamit ng menu 6, menu 7, at submenu ng menu 4.
function Disable-UserFull {
    param ([Parameter(Mandatory)][string]$Identity)

    $User = Get-ADUser -Identity $Identity -Properties MemberOf -ErrorAction Stop

    $RemovedGroups = @()
    $FailedGroups  = @()

    foreach ($GroupDN in @($User.MemberOf)) {
        try {
            $Group = Get-ADGroup -Identity $GroupDN -ErrorAction Stop
            Remove-ADGroupMember -Identity $Group -Members $User -Confirm:$false -ErrorAction Stop
            $RemovedGroups += $Group.Name
        }
        catch {
            $FailedGroups += "$GroupDN ($($_.Exception.Message))"
        }
    }

    Disable-ADAccount -Identity $User -ErrorAction Stop
    Set-ADUser -Identity $User -Description "Disabled $(Get-Date -Format 'yyyy-MM-dd')" -ErrorAction SilentlyContinue

    $result = if ($FailedGroups.Count -gt 0) { "Partial" } else { "Success" }
    Write-Log -Action "DISABLE USER" -Target $Identity -Result $result `
        -Details "Removed groups: $($RemovedGroups -join ', ') | Failed: $($FailedGroups -join '; ')"

    return [pscustomobject]@{
        Removed = $RemovedGroups
        Failed  = $FailedGroups
    }
}

function Show-DisableResult {
    param ($Result, [string]$Identity)
    Write-Host "  DISABLED: $Identity" -ForegroundColor Green
    if ($Result.Removed.Count -gt 0) { Write-Host "  Removed from: $($Result.Removed -join ', ')" -ForegroundColor Green }
    else { Write-Host "  Walang group na natanggal (wala o Domain Users lang)." -ForegroundColor DarkGray }
    if ($Result.Failed.Count -gt 0) { Write-Host "  FAILED to remove: $($Result.Failed -join '; ')" -ForegroundColor Red }
}

function Invoke-PasswordReset {
    param ([Parameter(Mandatory)][string]$Identity)

    $NewPass    = Get-PasswordToUse
    $SecurePass = ConvertTo-SecureString $NewPass -AsPlainText -Force

    Set-ADAccountPassword -Identity $Identity -NewPassword $SecurePass -Reset -ErrorAction Stop
    Set-ADUser -Identity $Identity -ChangePasswordAtLogon $true -ErrorAction Stop

    Write-Log -Action "RESET PASSWORD" -Target $Identity -Result "Success" -Details "Force change at next logon"
    Send-Notification -Subject "AD Notification: Password Reset - $Identity" `
        -Body "Password for '$Identity' has been reset.`nChange password required at next logon.`nTimestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    return $NewPass
}

# Gumagawa ng user. Ginagamit ng Add-NewUser at Bulk-AddUsers.
function New-ADUserFromData {
    param (
        [string]$FirstName, [string]$LastName, [string]$LoginUsername, [string]$UPN,
        [string]$OU, [string]$Department, [string]$Title, [string]$Group,
        [string]$Password, [string]$LogAction = "ADD USER"
    )

    $DisplayName = "$FirstName $LastName".Trim()
    $SecurePass  = ConvertTo-SecureString $Password -AsPlainText -Force

    # Splatting: idadagdag lang ang optional parameters kapag may laman
    $params = @{
        Name                  = $DisplayName
        GivenName             = $FirstName
        Surname               = $LastName
        DisplayName           = $DisplayName
        SamAccountName        = $LoginUsername
        Path                  = $OU
        AccountPassword       = $SecurePass
        Enabled               = $true
        ChangePasswordAtLogon = $true
        ErrorAction           = 'Stop'
    }
    if (-not [string]::IsNullOrWhiteSpace($UPN))        { $params.UserPrincipalName = $UPN }
    if (-not [string]::IsNullOrWhiteSpace($Department)) { $params.Department = $Department }
    if (-not [string]::IsNullOrWhiteSpace($Title))      { $params.Title = $Title }

    try {
        New-ADUser @params
        Write-Log -Action $LogAction -Target $LoginUsername -Result "Success" -Details "OU: $OU | Group: $Group | DisplayName: $DisplayName"
    }
    catch {
        Write-Log -Action $LogAction -Target $LoginUsername -Result "Failed" -Details $_.Exception.Message
        return [pscustomobject]@{ Created = $false; GroupAdded = $false; Error = $_.Exception.Message }
    }

    $groupAdded = $false
    $groupError = ""
    if (-not [string]::IsNullOrWhiteSpace($Group)) {
        try {
            Add-ADGroupMember -Identity $Group -Members $LoginUsername -ErrorAction Stop
            $groupAdded = $true
            Write-Log -Action "ADD TO GROUP" -Target $LoginUsername -Result "Success" -Details "Group: $Group"
        }
        catch {
            $groupError = $_.Exception.Message
            Write-Log -Action "ADD TO GROUP" -Target $LoginUsername -Result "Failed" -Details "Group: $Group | Error: $groupError"
        }
    }

    return [pscustomobject]@{ Created = $true; GroupAdded = $groupAdded; Error = $groupError }
}

# ==================== MENU ====================
function Show-Menu {
    Clear-Host
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "     ACTIVE DIRECTORY USER MANAGEMENT" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1.  Add New User (with OU + Group selection)"
    Write-Host "2.  Bulk Add Users (from CSV)" -ForegroundColor Yellow
    Write-Host "3.  Search User (by Name / Login Username)"
    Write-Host "4.  Find / Manage User (Search + Actions)"
    Write-Host "5.  Search / List OUs + Containers"
    Write-Host "6.  Disable User Account (+ remove from all groups)"
    Write-Host "7.  Bulk Disable Users (+ remove from all groups)" -ForegroundColor Yellow
    Write-Host "8.  Enable User Account"
    Write-Host "9.  Reset User Password"
    Write-Host "10. Unlock User Account"
    Write-Host "11. Add User to Group"
    Write-Host "12. Remove User from Group"
    Write-Host "13. Delete User"
    Write-Host "14. Setup Email Credential (Gmail App Password)"
    Write-Host "0.  Exit"
    Write-Host ""
    Write-Host "Password Mode : $(if ($UseRandomPassword) { 'Random per user' } else { 'Default password' })" -ForegroundColor DarkGray
    Write-Host "Log File      : $LogFile" -ForegroundColor DarkGray
    Write-Host "Email Notify  : $(if ($EnableEmailNotification) { 'Enabled' } else { 'Disabled' })" -ForegroundColor DarkGray
    Write-Host ""
}

# ==================== 1. ADD USER ====================
function Add-NewUser {
    Write-Host "`n--- ADD NEW USER ---" -ForegroundColor Yellow

    # ---------- OU / Container ----------
    Write-Host "`nLoading Organizational Units and Containers..." -ForegroundColor Cyan
    try {
        $Locations = @(Get-ADObject -Filter "ObjectClass -eq 'organizationalUnit' -or ObjectClass -eq 'container'" `
            -Properties DistinguishedName, Name, ObjectClass |
            Where-Object {
                $_.DistinguishedName -notlike "*CN=System*" -and
                $_.DistinguishedName -notlike "*CN=Program Data*" -and
                $_.DistinguishedName -notlike "*CN=NTDS Quotas*" -and
                $_.DistinguishedName -notlike "*CN=Microsoft*"
            } |
            Sort-Object DistinguishedName)
    }
    catch {
        Write-Host "Error loading locations: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    if ($Locations.Count -eq 0) {
        Write-Host "No OUs or Containers found!" -ForegroundColor Red
        return
    }

    Write-Host "`nAvailable Locations (OU + Container):" -ForegroundColor Green
    Write-Host ("{0,-5} {1,-12} {2}" -f "No.", "Type", "Path") -ForegroundColor DarkGray
    Write-Host ("-" * 90) -ForegroundColor DarkGray

    for ($i = 0; $i -lt $Locations.Count; $i++) {
        $type = if ($Locations[$i].ObjectClass -eq "organizationalUnit") { "OU" } else { "Container" }
        Write-Host ("{0,3}.  {1,-10} {2}" -f ($i + 1), $type, $Locations[$i].DistinguishedName)
    }

    $OUChoice = Read-Host "`nSelect number"
    if (-not ($OUChoice -match '^\d+$') -or [int]$OUChoice -lt 1 -or [int]$OUChoice -gt $Locations.Count) {
        Write-Host "Invalid selection." -ForegroundColor Red
        return
    }
    $SelectedOU = $Locations[[int]$OUChoice - 1].DistinguishedName
    Write-Host "Selected: $SelectedOU" -ForegroundColor Green

    # ---------- Security Group ----------
    Write-Host "`nLoading Security Groups inside the selected OU..." -ForegroundColor Cyan
    try {
        # 1) Groups na direktang nasa napiling OU
        $GroupSource = $SelectedOU
        $Groups = @(Get-ADGroup -Filter "GroupCategory -eq 'Security'" -SearchBase $SelectedOU -SearchScope OneLevel | Sort-Object Name)

        # 2) Kung walang group, hanapin sa sub-OU na "Users" ng napiling OU
        if ($Groups.Count -eq 0) {
            $UsersSubOU = Get-ADOrganizationalUnit -Filter "Name -eq 'Users'" -SearchBase $SelectedOU -SearchScope OneLevel -ErrorAction SilentlyContinue |
                Select-Object -First 1

            if ($UsersSubOU) {
                $GroupSource = $UsersSubOU.DistinguishedName
                Write-Host "Walang group sa OU mismo. Chine-check ang sub-OU: $GroupSource" -ForegroundColor DarkGray
                $Groups = @(Get-ADGroup -Filter "GroupCategory -eq 'Security'" -SearchBase $GroupSource -SearchScope Subtree | Sort-Object Name)
            }
        }
    }
    catch {
        Write-Host "Error loading groups: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    if ($Groups.Count -eq 0) {
        Write-Host "Walang Security Group sa '$SelectedOU' (pati sa sub-OU na 'Users'). Puwede mong i-skip." -ForegroundColor Yellow
    }

    Write-Host "`nAvailable Security Groups (from: $GroupSource):" -ForegroundColor Green
    for ($i = 0; $i -lt $Groups.Count; $i++) {
        Write-Host ("{0,3}. {1}" -f ($i + 1), $Groups[$i].Name)
    }
    Write-Host ("{0,3}. {1}" -f ($Groups.Count + 1), "Skip (No Group)")

    $GroupChoice   = Read-Host "`nSelect Group number (or last number to skip)"
    $SelectedGroup = $null

    if ($GroupChoice -match '^\d+$') {
        $gIndex = [int]$GroupChoice
        if ($gIndex -ge 1 -and $gIndex -le $Groups.Count) {
            $SelectedGroup = $Groups[$gIndex - 1].Name
            Write-Host "Selected Group: $SelectedGroup" -ForegroundColor Green
        }
        else {
            Write-Host "No group selected." -ForegroundColor Yellow
        }
    }

    # ---------- User details + review ----------
    do {
        Write-Host "`n--- Enter User Details ---" -ForegroundColor Cyan
        $FirstName  = Read-Host "First Name"
        $LastName   = Read-Host "Last Name"
        $UPN        = Read-Host "Email / UPN (ex: j.acebuche@company.com)"
        $Department = Read-Host "Department (optional)"
        $Title      = Read-Host "Job Title (optional)"

        do {
            $LoginUsername = Read-Host "Login Username (ex: j.acebuche)"

            if ([string]::IsNullOrWhiteSpace($LoginUsername)) {
                Write-Host "Login Username cannot be empty." -ForegroundColor Red
                continue
            }

            if (Test-SamAccountExists -SamAccountName $LoginUsername) {
                Write-Host "`nWARNING: Ang Login Username '$LoginUsername' ay NAGAMIT NA!" -ForegroundColor Red
                Write-Host "1. Maglagay ng bagong Login Username"
                Write-Host "2. Cancel"
                $retry = Read-Host "Choose (1 or 2)"
                if ($retry -eq "2") {
                    Write-Host "Cancelled." -ForegroundColor Yellow
                    return
                }
            }
            else { break }
        } while ($true)

        $DisplayName = "$FirstName $LastName"

        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "           REVIEW USER DETAILS" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "First Name      : $FirstName"
        Write-Host "Last Name       : $LastName"
        Write-Host "Display Name    : $DisplayName"
        Write-Host "Login Username  : $LoginUsername"
        Write-Host "Email / UPN     : $UPN"
        Write-Host "Department      : $Department"
        Write-Host "Job Title       : $Title"
        Write-Host "OU              : $SelectedOU"
        Write-Host "Security Group  : $(if ($SelectedGroup) { $SelectedGroup } else { 'None' })"
        Write-Host "Password        : $(if ($UseRandomPassword) { '(random - ipapakita after creation)' } else { $DefaultPassword })"
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Y = Continue / Create user"
        Write-Host "N = Cancel"
        Write-Host "C = Change (i-edit ulit ang details)"
        Write-Host ""

        $Confirm = (Read-Host "Choose (Y / N / C)").ToUpper()

        if ($Confirm -eq "Y") { break }
        elseif ($Confirm -eq "N") {
            Write-Host "Cancelled." -ForegroundColor Yellow
            return
        }
        elseif ($Confirm -eq "C") { Write-Host "`nMag-i-input ulit ng details..." -ForegroundColor Yellow }
        else { Write-Host "Invalid choice. Mag-i-input ulit..." -ForegroundColor Red }

    } while ($true)

    # ---------- Create ----------
    $Password = Get-PasswordToUse
    $r = New-ADUserFromData -FirstName $FirstName -LastName $LastName -LoginUsername $LoginUsername `
            -UPN $UPN -OU $SelectedOU -Department $Department -Title $Title -Group $SelectedGroup `
            -Password $Password -LogAction "ADD USER"

    if (-not $r.Created) {
        Write-Host "`nError creating user: $($r.Error)" -ForegroundColor Red
        return
    }

    Write-Host "`nSuccessfully created user!" -ForegroundColor Green
    Write-Host "Display Name     : $DisplayName" -ForegroundColor Green
    Write-Host "Login Username   : $LoginUsername" -ForegroundColor Green
    Write-Host "OU               : $SelectedOU" -ForegroundColor Green
    Write-Host "Password         : $Password" -ForegroundColor Yellow
    Write-Host "User must change password at next logon." -ForegroundColor Yellow

    if ($SelectedGroup) {
        if ($r.GroupAdded) { Write-Host "Added to Security Group: $SelectedGroup" -ForegroundColor Green }
        else { Write-Host "User created pero failed to add to group: $($r.Error)" -ForegroundColor Yellow }
    }

    # WALANG password sa email
    $emailBody = @"
New AD User Created

Display Name    : $DisplayName
Login Username  : $LoginUsername
Email / UPN     : $UPN
OU              : $SelectedOU
Security Group  : $(if ($SelectedGroup) { $SelectedGroup } else { 'None' })
Group Added     : $(if ($SelectedGroup) { $r.GroupAdded } else { 'N/A' })
Change Password : Required at next logon

Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
    Send-Notification -Subject "AD Notification: New User Created - $LoginUsername" -Body $emailBody
}

# ==================== 2. BULK ADD ====================
function Bulk-AddUsers {
    Write-Host "`n--- BULK ADD USERS FROM CSV ---" -ForegroundColor Yellow
    Write-Host "CSV Format dapat:" -ForegroundColor Cyan
    Write-Host "FirstName,LastName,LoginUsername,UPN,OU,Department,Title,SecurityGroup" -ForegroundColor DarkGray
    Write-Host ""

    $CsvPath = Read-Host "Enter full path of CSV file (ex: C:\Temp\BulkUsers.csv)"

    if (-not (Test-Path $CsvPath)) {
        Write-Host "File not found: $CsvPath" -ForegroundColor Red
        return
    }

    try { $Users = @(Import-Csv -Path $CsvPath) }
    catch {
        Write-Host "Error reading CSV: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    if ($Users.Count -eq 0) {
        Write-Host "CSV is empty." -ForegroundColor Red
        return
    }

    Write-Host "`nFound $($Users.Count) users in CSV." -ForegroundColor Cyan
    if ((Read-Host "Proceed with bulk creation? (yes/no)") -ne "yes") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        return
    }

    $Success = 0
    $Failed  = 0
    $Created = @()

    foreach ($User in $Users) {
        $LoginUsername = "$($User.LoginUsername)".Trim()
        Write-Host "`nProcessing: $LoginUsername ..." -ForegroundColor Cyan

        if ([string]::IsNullOrWhiteSpace($LoginUsername) -or [string]::IsNullOrWhiteSpace($User.OU)) {
            Write-Host "  SKIPPED: Walang LoginUsername o OU sa row na ito." -ForegroundColor Yellow
            Write-Log -Action "BULK ADD USER" -Target $LoginUsername -Result "Skipped" -Details "Missing LoginUsername/OU"
            $Failed++
            continue
        }

        if (Test-SamAccountExists -SamAccountName $LoginUsername) {
            Write-Host "  SKIPPED: Login Username '$LoginUsername' already exists." -ForegroundColor Yellow
            Write-Log -Action "BULK ADD USER" -Target $LoginUsername -Result "Skipped" -Details "Already exists"
            $Failed++
            continue
        }

        $Password = Get-PasswordToUse
        $r = New-ADUserFromData -FirstName $User.FirstName -LastName $User.LastName -LoginUsername $LoginUsername `
                -UPN $User.UPN -OU $User.OU -Department $User.Department -Title $User.Title -Group $User.SecurityGroup `
                -Password $Password -LogAction "BULK ADD USER"

        if ($r.Created) {
            Write-Host "  CREATED: $($User.FirstName) $($User.LastName) ($LoginUsername)" -ForegroundColor Green
            if (-not [string]::IsNullOrWhiteSpace($User.SecurityGroup)) {
                if ($r.GroupAdded) { Write-Host "  ADDED TO GROUP: $($User.SecurityGroup)" -ForegroundColor Green }
                else { Write-Host "  WARNING: Failed to add to group $($User.SecurityGroup) - $($r.Error)" -ForegroundColor Yellow }
            }
            if ($UseRandomPassword) { Write-Host "  Password: $Password" -ForegroundColor Yellow }
            $Created += $LoginUsername
            $Success++
        }
        else {
            Write-Host "  FAILED: $($r.Error)" -ForegroundColor Red
            $Failed++
        }
    }

    Write-Host "`n========== BULK ADD SUMMARY ==========" -ForegroundColor Cyan
    Write-Host "Successful : $Success" -ForegroundColor Green
    Write-Host "Failed     : $Failed" -ForegroundColor Red
    if (-not $UseRandomPassword) { Write-Host "Default Password used: $DefaultPassword" -ForegroundColor Yellow }

    Write-Log -Action "BULK ADD USERS" -Target "CSV: $CsvPath" -Result "Completed" -Details "Success: $Success | Failed: $Failed"

    $emailBody = @"
Bulk Add Users Completed

CSV File   : $CsvPath
Successful : $Success
Failed     : $Failed
Created    : $($Created -join ', ')

Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
    Send-Notification -Subject "AD Notification: Bulk Add Users Completed" -Body $emailBody
}

# ==================== 7. BULK DISABLE ====================
function Bulk-DisableUsers {
    Write-Host "`n--- BULK DISABLE USERS ---" -ForegroundColor Yellow
    Write-Host "This will:" -ForegroundColor Cyan
    Write-Host "  1. Remove the user from ALL groups (except primary group)"
    Write-Host "  2. Disable the user account"
    Write-Host ""

    Write-Host "Paano mo ibibigay ang listahan?" -ForegroundColor Cyan
    Write-Host "1. Manual (type Login Usernames separated by comma)"
    Write-Host "2. From CSV (column: LoginUsername)"
    $Method = Read-Host "Choose (1 or 2)"

    $UserList = @()

    if ($Method -eq "1") {
        $UserInput = Read-Host "Enter Login Usernames (ex: j.delacruz,m.santos,p.reyes)"
        $UserList  = @($UserInput -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
    }
    elseif ($Method -eq "2") {
        $CsvPath = Read-Host "Enter full path of CSV file"
        if (-not (Test-Path $CsvPath)) {
            Write-Host "File not found." -ForegroundColor Red
            return
        }
        try {
            $CsvData = @(Import-Csv -Path $CsvPath)
            if ($CsvData.Count -eq 0) { Write-Host "CSV is empty." -ForegroundColor Red; return }

            if ($CsvData[0].PSObject.Properties.Name -contains "LoginUsername") {
                $UserList = @($CsvData.LoginUsername | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() })
            }
            else {
                $firstCol = $CsvData[0].PSObject.Properties.Name[0]
                $UserList = @($CsvData | ForEach-Object { "$($_.$firstCol)".Trim() } | Where-Object { $_ -ne "" })
            }
        }
        catch {
            Write-Host "Error reading CSV: $($_.Exception.Message)" -ForegroundColor Red
            return
        }
    }
    else {
        Write-Host "Invalid choice." -ForegroundColor Red
        return
    }

    if ($UserList.Count -eq 0) {
        Write-Host "No users provided." -ForegroundColor Red
        return
    }

    Write-Host "`nUsers to disable ($($UserList.Count)):" -ForegroundColor Yellow
    $UserList | ForEach-Object { Write-Host "  - $_" }

    if ((Read-Host "`nDISABLE these users and REMOVE them from all groups? (yes/no)") -ne "yes") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        return
    }

    $Success = 0
    $Failed  = 0
    $Partial = @()

    foreach ($LoginUsername in $UserList) {
        Write-Host "`nProcessing: $LoginUsername ..." -ForegroundColor Cyan
        try {
            $r = Disable-UserFull -Identity $LoginUsername
            Show-DisableResult -Result $r -Identity $LoginUsername
            if ($r.Failed.Count -gt 0) { $Failed++; $Partial += $LoginUsername }
            else { $Success++ }
        }
        catch {
            Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
            Write-Log -Action "DISABLE USER" -Target $LoginUsername -Result "Failed" -Details $_.Exception.Message
            $Failed++
        }
    }

    Write-Host "`n========== BULK DISABLE SUMMARY ==========" -ForegroundColor Cyan
    Write-Host "Successful : $Success" -ForegroundColor Green
    Write-Host "Failed / Partial : $Failed" -ForegroundColor Red
    if ($Partial.Count -gt 0) { Write-Host "Partial (disabled pero may group na hindi natanggal): $($Partial -join ', ')" -ForegroundColor Yellow }

    Write-Log -Action "BULK DISABLE USERS" -Target "Multiple" -Result "Completed" -Details "Success: $Success | Failed/Partial: $Failed"

    $emailBody = @"
Bulk Disable Users Completed

Successful       : $Success
Failed / Partial : $Failed
Partial users    : $($Partial -join ', ')
Action           : Disabled + Removed from all groups

Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
    Send-Notification -Subject "AD Notification: Bulk Disable Users Completed" -Body $emailBody
}

# ==================== 3. SEARCH USER ====================
function Search-User {
    Write-Host "`n--- SEARCH USER ---" -ForegroundColor Yellow
    $Keyword = Escape-Filter (Read-Host "Enter Name or Login Username")

    try {
        $Users = @(Get-ADUser -Filter "Name -like '*$Keyword*' -or SamAccountName -like '*$Keyword*'" `
                    -Properties Enabled, Department, Title, DistinguishedName)

        if ($Users.Count -gt 0) {
            $Users | Select-Object Name, SamAccountName, Enabled, Department, Title, DistinguishedName | Format-Table -AutoSize
        }
        else { Write-Host "No user found." -ForegroundColor Red }
    }
    catch { Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red }
}

# ==================== 4. FIND / MANAGE USER ====================
function Find-UserOU {
    Write-Host "`n--- FIND / MANAGE USER ---" -ForegroundColor Yellow
    $Identity = Escape-Filter (Read-Host "Enter Login Username or Name (partial ok)")

    try {
        $Users = @(Get-ADUser -Filter "SamAccountName -like '*$Identity*' -or Name -like '*$Identity*'" `
                    -Properties DistinguishedName, Enabled, Department, Title)

        if ($Users.Count -eq 0) {
            Write-Host "User not found." -ForegroundColor Red
            return
        }

        Write-Host "`nFound $($Users.Count) user(s):" -ForegroundColor Cyan
        Write-Host ("{0,-4} {1,-25} {2,-20} {3,-10} {4}" -f "No.", "Name", "Login Username", "Enabled", "OU Path") -ForegroundColor DarkGray
        Write-Host ("-" * 100) -ForegroundColor DarkGray

        for ($i = 0; $i -lt $Users.Count; $i++) {
            $ouPath  = $Users[$i].DistinguishedName -replace '^CN=.*?(?<!\\),', ''
            $enabled = if ($Users[$i].Enabled) { "Yes" } else { "No" }
            Write-Host ("{0,3}. {1,-25} {2,-20} {3,-10} {4}" -f ($i + 1), $Users[$i].Name, $Users[$i].SamAccountName, $enabled, $ouPath)
        }

        Write-Host ""
        $Selection = Read-Host "Select user number (or 0 to cancel)"
        if ($Selection -eq "0" -or -not ($Selection -match '^\d+$') -or [int]$Selection -lt 1 -or [int]$Selection -gt $Users.Count) {
            Write-Host "Cancelled." -ForegroundColor Yellow
            return
        }

        $Login = $Users[[int]$Selection - 1].SamAccountName

        do {
            # I-refresh ang details tuwing balik sa submenu para updated ang Enabled status
            $SelectedUser = Get-ADUser -Identity $Login -Properties DistinguishedName, Enabled, Department, Title, LockedOut, MemberOf

            Write-Host "`n========================================" -ForegroundColor Cyan
            Write-Host "  Selected: $($SelectedUser.Name) ($Login)  |  Enabled: $($SelectedUser.Enabled)" -ForegroundColor Cyan
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host "1. View Full Details"
            Write-Host "2. Reset Password"
            Write-Host "3. Disable Account (+ remove from all groups)"
            Write-Host "4. Enable Account"
            Write-Host "5. Unlock Account"
            Write-Host "6. Delete User"
            Write-Host "7. Add to Group"
            Write-Host "8. Remove from Group"
            Write-Host "0. Back"
            Write-Host ""

            $Action = Read-Host "Choose action"

            switch ($Action) {
                "1" {
                    Write-Host "`n--- Full Details ---" -ForegroundColor Green
                    Write-Host "Name             : $($SelectedUser.Name)"
                    Write-Host "Login Username   : $($SelectedUser.SamAccountName)"
                    Write-Host "Enabled          : $($SelectedUser.Enabled)"
                    Write-Host "Locked Out       : $($SelectedUser.LockedOut)"
                    Write-Host "Department       : $($SelectedUser.Department)"
                    Write-Host "Title            : $($SelectedUser.Title)"
                    Write-Host "DistinguishedName: $($SelectedUser.DistinguishedName)"
                    $groupNames = @($SelectedUser.MemberOf | ForEach-Object { ($_ -split ',')[0] -replace '^CN=', '' })
                    Write-Host "Groups           : $(if ($groupNames.Count) { $groupNames -join ', ' } else { '(none)' })"
                }
                "2" {
                    if ((Read-Host "Reset password of '$Login'? (yes/no)") -eq "yes") {
                        try {
                            $NewPass = Invoke-PasswordReset -Identity $Login
                            Write-Host "Password reset successfully. New password: $NewPass" -ForegroundColor Green
                        }
                        catch {
                            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                            Write-Log -Action "RESET PASSWORD" -Target $Login -Result "Failed" -Details $_.Exception.Message
                        }
                    }
                }
                "3" {
                    if ((Read-Host "Disable '$Login' and remove from all groups? (yes/no)") -eq "yes") {
                        try {
                            $r = Disable-UserFull -Identity $Login
                            Show-DisableResult -Result $r -Identity $Login
                            Send-Notification -Subject "AD Notification: User Disabled - $Login" `
                                -Body "User '$Login' disabled.`nGroups removed: $($r.Removed -join ', ')`nFailed: $($r.Failed -join '; ')`nTimestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                        }
                        catch {
                            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                            Write-Log -Action "DISABLE USER" -Target $Login -Result "Failed" -Details $_.Exception.Message
                        }
                    }
                }
                "4" {
                    try {
                        Enable-ADAccount -Identity $Login -ErrorAction Stop
                        Write-Host "Account enabled." -ForegroundColor Green
                        Write-Log -Action "ENABLE USER" -Target $Login -Result "Success"
                    }
                    catch {
                        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                        Write-Log -Action "ENABLE USER" -Target $Login -Result "Failed" -Details $_.Exception.Message
                    }
                }
                "5" {
                    try {
                        Unlock-ADAccount -Identity $Login -ErrorAction Stop
                        Write-Host "Account unlocked." -ForegroundColor Green
                        Write-Log -Action "UNLOCK USER" -Target $Login -Result "Success"
                    }
                    catch {
                        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                        Write-Log -Action "UNLOCK USER" -Target $Login -Result "Failed" -Details $_.Exception.Message
                    }
                }
                "6" {
                    if ((Read-Host "DELETE user '$Login'? This cannot be undone! (yes/no)") -eq "yes") {
                        try {
                            Remove-ADUser -Identity $Login -Confirm:$false -ErrorAction Stop
                            Write-Host "User deleted." -ForegroundColor Green
                            Write-Log -Action "DELETE USER" -Target $Login -Result "Success"
                            Send-Notification -Subject "AD Notification: User Deleted - $Login" `
                                -Body "User '$Login' has been deleted.`nTimestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                            return
                        }
                        catch {
                            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                            Write-Log -Action "DELETE USER" -Target $Login -Result "Failed" -Details $_.Exception.Message
                        }
                    }
                }
                "7" {
                    $Group = Read-Host "Enter Group Name"
                    try {
                        Add-ADGroupMember -Identity $Group -Members $Login -ErrorAction Stop
                        Write-Host "Added to group '$Group'." -ForegroundColor Green
                        Write-Log -Action "ADD TO GROUP" -Target $Login -Result "Success" -Details "Group: $Group"
                    }
                    catch {
                        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                        Write-Log -Action "ADD TO GROUP" -Target $Login -Result "Failed" -Details "Group: $Group | $($_.Exception.Message)"
                    }
                }
                "8" {
                    $Group = Read-Host "Enter Group Name"
                    try {
                        Remove-ADGroupMember -Identity $Group -Members $Login -Confirm:$false -ErrorAction Stop
                        Write-Host "Removed from group '$Group'." -ForegroundColor Green
                        Write-Log -Action "REMOVE FROM GROUP" -Target $Login -Result "Success" -Details "Group: $Group"
                    }
                    catch {
                        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                        Write-Log -Action "REMOVE FROM GROUP" -Target $Login -Result "Failed" -Details "Group: $Group | $($_.Exception.Message)"
                    }
                }
                "0" { return }
                default { Write-Host "Invalid choice." -ForegroundColor Red }
            }

            if ($Action -ne "0") { Read-Host "`nPress Enter to continue..." | Out-Null }

        } while ($Action -ne "0")
    }
    catch { Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red }
}

# ==================== 5. SEARCH OU ====================
function Search-OU {
    Write-Host "`n--- SEARCH / LIST OUs + CONTAINERS ---" -ForegroundColor Yellow
    Write-Host "1. List ALL (OU + Container)"
    Write-Host "2. Search by keyword"
    $Choice = Read-Host "Choose (1 or 2)"

    try {
        if ($Choice -eq "1") {
            Get-ADObject -Filter "ObjectClass -eq 'organizationalUnit' -or ObjectClass -eq 'container'" `
                -Properties Name, DistinguishedName, ObjectClass |
                Where-Object {
                    $_.DistinguishedName -notlike "*CN=System*" -and
                    $_.DistinguishedName -notlike "*CN=Program Data*"
                } |
                Select-Object Name, ObjectClass, DistinguishedName |
                Sort-Object DistinguishedName |
                Format-Table -AutoSize
        }
        elseif ($Choice -eq "2") {
            $Keyword = Escape-Filter (Read-Host "Enter keyword to search (ex: HR, Users, IT, Finance)")
            $Results = @(Get-ADObject -Filter "(ObjectClass -eq 'organizationalUnit' -or ObjectClass -eq 'container') -and Name -like '*$Keyword*'" `
                -Properties Name, DistinguishedName, ObjectClass)

            if ($Results.Count -gt 0) {
                $Results | Select-Object Name, ObjectClass, DistinguishedName | Format-Table -AutoSize
            }
            else { Write-Host "No location found matching '$Keyword'." -ForegroundColor Red }
        }
        else { Write-Host "Invalid choice." -ForegroundColor Red }
    }
    catch { Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red }
}

# ==================== 6. DISABLE USER ====================
function Disable-User {
    Write-Host "`n--- DISABLE USER ---" -ForegroundColor Yellow
    $Identity = Read-Host "Enter Login Username"

    if ([string]::IsNullOrWhiteSpace($Identity)) { Write-Host "Cancelled." -ForegroundColor Yellow; return }

    if ((Read-Host "Disable '$Identity' and remove from all groups? (yes/no)") -ne "yes") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        return
    }

    try {
        $r = Disable-UserFull -Identity $Identity
        Show-DisableResult -Result $r -Identity $Identity
        Send-Notification -Subject "AD Notification: User Disabled - $Identity" `
            -Body "User '$Identity' disabled.`nGroups removed: $($r.Removed -join ', ')`nFailed: $($r.Failed -join '; ')`nTimestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Action "DISABLE USER" -Target $Identity -Result "Failed" -Details $_.Exception.Message
    }
}

# ==================== 8. ENABLE USER ====================
function Enable-User {
    Write-Host "`n--- ENABLE USER ---" -ForegroundColor Yellow
    $Identity = Read-Host "Enter Login Username"

    try {
        Enable-ADAccount -Identity $Identity -ErrorAction Stop
        Write-Host "User '$Identity' has been enabled." -ForegroundColor Green
        Write-Host "Note: hindi ibinabalik ang dating groups. I-add manually kung kailangan." -ForegroundColor DarkGray
        Write-Log -Action "ENABLE USER" -Target $Identity -Result "Success"
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Action "ENABLE USER" -Target $Identity -Result "Failed" -Details $_.Exception.Message
    }
}

# ==================== 9. RESET PASSWORD ====================
function Reset-Password {
    Write-Host "`n--- RESET USER PASSWORD ---" -ForegroundColor Yellow
    if ($UseRandomPassword) { Write-Host "Mode: random password" -ForegroundColor Cyan }
    else { Write-Host "Default Password na gagamitin: $DefaultPassword" -ForegroundColor Cyan }

    $Identity = Read-Host "Enter Login Username"

    if ((Read-Host "I-reset ang password ni '$Identity'? (yes/no)") -ne "yes") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        return
    }

    try {
        $NewPass = Invoke-PasswordReset -Identity $Identity
        Write-Host "`nPassword successfully reset!" -ForegroundColor Green
        Write-Host "User            : $Identity" -ForegroundColor Green
        Write-Host "New Password    : $NewPass" -ForegroundColor Yellow
        Write-Host "Change Password : Required at next logon" -ForegroundColor Yellow
    }
    catch {
        Write-Host "`nError: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Action "RESET PASSWORD" -Target $Identity -Result "Failed" -Details $_.Exception.Message
    }
}

# ==================== 10. UNLOCK ====================
function Unlock-User {
    Write-Host "`n--- UNLOCK USER ---" -ForegroundColor Yellow
    $Identity = Read-Host "Enter Login Username"

    try {
        Unlock-ADAccount -Identity $Identity -ErrorAction Stop
        Write-Host "User '$Identity' has been unlocked." -ForegroundColor Green
        Write-Log -Action "UNLOCK USER" -Target $Identity -Result "Success"
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Action "UNLOCK USER" -Target $Identity -Result "Failed" -Details $_.Exception.Message
    }
}

# ==================== 11. ADD TO GROUP ====================
function Add-UserToGroup {
    Write-Host "`n--- ADD USER TO GROUP ---" -ForegroundColor Yellow
    $User  = Read-Host "Enter Login Username of User"
    $Group = Read-Host "Enter Group Name"

    try {
        Add-ADGroupMember -Identity $Group -Members $User -ErrorAction Stop
        Write-Host "Successfully added '$User' to group '$Group'." -ForegroundColor Green
        Write-Log -Action "ADD TO GROUP" -Target $User -Result "Success" -Details "Group: $Group"
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Action "ADD TO GROUP" -Target $User -Result "Failed" -Details "Group: $Group | $($_.Exception.Message)"
    }
}

# ==================== 12. REMOVE FROM GROUP ====================
function Remove-UserFromGroup {
    Write-Host "`n--- REMOVE USER FROM GROUP ---" -ForegroundColor Yellow
    $User  = Read-Host "Enter Login Username of User"
    $Group = Read-Host "Enter Group Name"

    try {
        Remove-ADGroupMember -Identity $Group -Members $User -Confirm:$false -ErrorAction Stop
        Write-Host "Successfully removed '$User' from group '$Group'." -ForegroundColor Green
        Write-Log -Action "REMOVE FROM GROUP" -Target $User -Result "Success" -Details "Group: $Group"
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Action "REMOVE FROM GROUP" -Target $User -Result "Failed" -Details "Group: $Group | $($_.Exception.Message)"
    }
}

# ==================== 13. DELETE USER ====================
function Delete-User {
    Write-Host "`n--- DELETE USER ---" -ForegroundColor Red
    $Identity = Read-Host "Enter Login Username to DELETE"

    if ((Read-Host "Are you sure you want to delete '$Identity'? (yes/no)") -eq "yes") {
        try {
            Remove-ADUser -Identity $Identity -Confirm:$false -ErrorAction Stop
            Write-Host "User '$Identity' has been deleted." -ForegroundColor Green
            Write-Log -Action "DELETE USER" -Target $Identity -Result "Success"
            Send-Notification -Subject "AD Notification: User Deleted - $Identity" `
                -Body "User '$Identity' has been permanently deleted.`nTimestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        }
        catch {
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            Write-Log -Action "DELETE USER" -Target $Identity -Result "Failed" -Details $_.Exception.Message
        }
    }
    else { Write-Host "Cancelled." -ForegroundColor Yellow }
}

# ==================== MAIN LOOP ====================
do {
    Show-Menu
    $Choice = Read-Host "Select an option"

    switch ($Choice) {
        "1"  { Add-NewUser }
        "2"  { Bulk-AddUsers }
        "3"  { Search-User }
        "4"  { Find-UserOU }
        "5"  { Search-OU }
        "6"  { Disable-User }
        "7"  { Bulk-DisableUsers }
        "8"  { Enable-User }
        "9"  { Reset-Password }
        "10" { Unlock-User }
        "11" { Add-UserToGroup }
        "12" { Remove-UserFromGroup }
        "13" { Delete-User }
        "14" { Setup-EmailCredential }
        "0"  { Write-Host "Exiting..." -ForegroundColor Cyan }
        default { Write-Host "Invalid choice. Please try again." -ForegroundColor Red }
    }

    if ($Choice -ne "0") {
        Write-Host ""
        Read-Host "Press Enter to continue..." | Out-Null
    }

} while ($Choice -ne "0")
