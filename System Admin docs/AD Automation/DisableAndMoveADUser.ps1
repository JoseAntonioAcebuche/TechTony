# ============================================================
# Disable-And-Move-ADUser.ps1
# Disables AD account, logs to CSV, then moves to Disabled Users OU
# ============================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$Username,

    [Parameter(Mandatory=$false)]
    [string]$Reason = "No reason provided",

    [Parameter(Mandatory=$false)]
    [string]$DisabledOU = "OU=Disabled Users,OU=Shadow,DC=ACEBUCHE,DC=local",

    [Parameter(Mandatory=$false)]
    [string]$LogPath = "C:\AD_Logs\disabled_accounts.csv"
)

# --- 1. Check if user exists ---
try {
    $user = Get-ADUser -Identity $Username -Properties DisplayName, Description, DistinguishedName, Enabled
} catch {
    Write-Host "ERROR: User '$Username' not found in AD." -ForegroundColor Red
    exit 1
}

# --- 2. Check kung already disabled na ---
if (-not $user.Enabled) {
    Write-Host "WARNING: '$Username' is already disabled." -ForegroundColor Yellow
}

# --- 3. Disable the account ---
try {
    Disable-ADAccount -Identity $user
    Write-Host "OK: Account '$Username' disabled." -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to disable account. $_" -ForegroundColor Red
    exit 1
}

# --- 4. Stamp description with disable date ---
$dateStamp = Get-Date -Format "yyyy-MM-dd HH:mm"
$oldDesc = $user.Description
$newDesc = "DISABLED: $dateStamp | $Reason | Prev: $oldDesc"
Set-ADUser -Identity $user -Description $newDesc

# --- 5. Log to CSV ---
$logDir = Split-Path $LogPath
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$logEntry = [PSCustomObject]@{
    Date           = $dateStamp
    Username       = $Username
    DisplayName    = $user.DisplayName
    PreviousOU     = $user.DistinguishedName
    Reason         = $Reason
    DisabledBy     = $env:USERNAME
    ComputerName   = $env:COMPUTERNAME
}

$logEntry | Export-Csv -Path $LogPath -Append -NoTypeInformation -Encoding UTF8
Write-Host "OK: Logged to '$LogPath'." -ForegroundColor Green

# --- 6. Move to Disabled Users OU ---
try {
    Move-ADObject -Identity $user.DistinguishedName -TargetPath $DisabledOU
    Write-Host "OK: Moved '$Username' to Disabled Users OU." -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to move account. $_" -ForegroundColor Red
    exit 1
}

Write-Host "`nDone! '$Username' has been disabled, logged, and moved." -ForegroundColor Cyan
