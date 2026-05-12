# ============================================================
#  ACEBUCHE.local — Bulk User Creation Script
#  OU Structure: Shadow > Users > Department
#
#  PAANO GAMITIN:
#  1. Buksan ang acebuche-users.csv sa Excel
#  2. Punan ng users (huwag burahin ang header row)
#  3. I-save bilang CSV
#  4. Ilagay sa parehong folder ng script na ito
#  5. I-run: .\acebuche-add-users.ps1
# ============================================================

$csvFile = ".\acebuche-users.csv"
$domain = "DC=ACEBUCHE,DC=local"
$logfile =".\acebuche-user-log.txt"
# ── OU paths per department ──────────────────────────────────
$ouMap = @{
    "HR" = "OU=HR,OU=Users,OU=Shadow,$domain"
    "Finance" = "OU=Finance,OU=Users,OU=Shadow,$domain"
    "IT" = "OU=IT,OU=Users,OU=Shadow,$domain"
    "Management" = "OU=Management,OU=Users,OU=Shadow,$domain"
}
# ── Security Group per department ────────────────────────────

if (-not (Test-Path $csvFile)) { Write-Host "HINDI MAHANAP ANG CSV!"; exit }

$users = Import-Csv $csvFile
Write-Host "May $($users.Count) users sa listahan..."

foreach ($u in $users) {
    $displayName = "$($u.FirstName) $($u.LastName)"
    $username = "$($u.FirstName.ToLower()).$($u.LastName.ToLower().Replace(' ',''))"
    $ouPath = $ouMap[$u.Department]

    if (-not $ouPath) {
        Write-Host "[SKIP] $displayName - Mali ang Department"
        continue
    }

    try {
        New-ADUser -Name $displayName `
                   -SamAccountName $username `
                   -UserPrincipalName "$username@ACEBUCHE.local" `
                   -Department $u.Department `
                   -Path $ouPath `
                   -AccountPassword (ConvertTo-SecureString $u.Password -AsPlainText -Force) `
                   -Enabled $true -ChangePasswordAtLogon $true
        Write-Host "[OK] Gawa na si $username" -ForegroundColor Green
    } catch {
        Write-Host "[FAIL] $username - $($_.Exception.Message)" -ForegroundColor Red
    }
}


# ── Summary ──────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  RESULTA:" -ForegroundColor Cyan
Write-Host "  Nagawa:    $success users" -ForegroundColor Green
if ($skipped -gt 0) {
Write-Host "  Nilaktawan: $skipped users" -ForegroundColor Yellow }
if ($failed -gt 0) {
Write-Host "  May error:  $failed users" -ForegroundColor Red }
Write-Host "============================================" -ForegroundColor Cyan

# I-save ang log
$log += ""
$log += "--------------------------------------------"
$log += "Nagawa:     $success"
$log += "Nilaktawan: $skipped"
$log += "May error:  $failed"
$log += "--------------------------------------------"
$log | Out-File $logFile -Encoding UTF8

Write-Host ""
Write-Host " Log na-save sa: $logFile" -ForegroundColor Yellow
Write-Host ""
