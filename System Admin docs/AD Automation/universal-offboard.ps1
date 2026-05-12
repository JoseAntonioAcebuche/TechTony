# ============================================================
#  UNIVERSAL — User Offboarding Script
#  OU Structure: MainOU > Department > Users
#  Disabled OU : MainOU > Disabled
#
#  PAANO I-CUSTOMIZE:
#  1. Palitan ang $domain ng domain ng company
#  2. Palitan ang $mainOU kung iba ang pangalan
#  3. I-run bilang Administrator sa Domain Controller
#
#  GAGAWIN NG SCRIPT:
#  ✓ Idi-disable ang account
#  ✓ Aalisin sa lahat ng Security Groups
#  ✓ Ililipat sa Disabled OU
#  ✓ May log file para sa record
# ============================================================

# ██████████████████████████████████████████████████████████
# ██  I-EDIT LANG DITO — WALA NANG IBA KAILANGAN BAGUHIN  ██
# ██████████████████████████████████████████████████████████

$domain  = "DC=ACEBUCHE,DC=local"   # <- Palitan ng domain ng company
$mainOU  = "Shadow"                  # <- Palitan kung iba ang Main OU

# ██████████████████████████████████████████████████████████
# ██            HUWAG NA BAGUHIN PAGKATAPOS NITO           ██
# ██████████████████████████████████████████████████████████

$csvFile    = ".\offboard.csv"
$logFile    = ".\offboard-log.txt"
$disabledOU = "OU=Disabled,OU=$mainOU,$domain"

# ── I-check kung may Disabled OU, kung wala gumawa ───────────
try {
    Get-ADOrganizationalUnit -Identity $disabledOU -ErrorAction Stop | Out-Null
} catch {
    Write-Host " Gumagawa ng Disabled OU..." -ForegroundColor Yellow
    New-ADOrganizationalUnit -Name "Disabled" -Path "OU=$mainOU,$domain"
    Write-Host " Disabled OU nagawa na." -ForegroundColor Green
}

# ── Start ────────────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   UNIVERSAL — User Offboarding Script     " -ForegroundColor Cyan
Write-Host "   Domain : $domain                        " -ForegroundColor Cyan
Write-Host "   Main OU: $mainOU                        " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# I-check kung mayroon ang CSV
if (-not (Test-Path $csvFile)) {
    Write-Host " ERROR: Hindi mahanap ang $csvFile" -ForegroundColor Red
    Write-Host " Tiyakin na nandoon ang offboard.csv" -ForegroundColor Red
    exit
}

# Basahin ang CSV
$users = Import-Csv $csvFile
Write-Host " $($users.Count) users ang ipo-process..." -ForegroundColor Yellow
Write-Host ""

$success = 0
$failed  = 0
$log     = @()
$log    += "============================================"
$log    += "  Offboarding Log — $domain"
$log    += "  Petsa: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$log    += "============================================"
$log    += ""

# ── Loop sa bawat user ───────────────────────────────────────
foreach ($user in $users) {

    $username = $user.Username.Trim()
    $reason   = $user.Reason.Trim()

    Write-Host " Processing: $username ($reason)" -ForegroundColor Yellow

    # I-check kung existing ang user
    $adUser = Get-ADUser -Filter { SamAccountName -eq $username } `
              -Properties MemberOf, DisplayName -ErrorAction SilentlyContinue

    if (-not $adUser) {
        Write-Host "   [SKIP] Hindi mahanap ang user: $username" -ForegroundColor DarkYellow
        $log += "SKIP   | $username | Hindi mahanap sa AD"
        $failed++
        continue
    }

    try {
        $displayName = $adUser.DisplayName

        # 1. Idi-disable ang account
        Disable-ADAccount -Identity $username
        Write-Host "   [OK] Account disabled" -ForegroundColor Green

        # 2. Alisin sa lahat ng groups (maliban sa Domain Users)
        $groups = $adUser.MemberOf
        foreach ($group in $groups) {
            try {
                Remove-ADGroupMember -Identity $group -Members $username -Confirm:$false
            } catch {
                # Ignore kung hindi maalis sa ilang default groups
            }
        }
        Write-Host "   [OK] Inalis sa lahat ng groups" -ForegroundColor Green

        # 3. I-move sa Disabled OU
        Move-ADObject -Identity $adUser.DistinguishedName -TargetPath $disabledOU
        Write-Host "   [OK] Nilipat sa Disabled OU ($mainOU > Disabled)" -ForegroundColor Green

        # 4. Mag-add ng description kung kailan na-offboard
        Set-ADUser -Identity $username `
            -Description "OFFBOARDED: $(Get-Date -Format 'yyyy-MM-dd') | Reason: $reason"

        Write-Host "   [DONE] $displayName ($username) — $reason" -ForegroundColor Green
        Write-Host ""

        $log += "OK     | $displayName | $username | $reason | $(Get-Date -Format 'yyyy-MM-dd')"
        $success++

    } catch {
        Write-Host "   [FAIL] $username — $($_.Exception.Message)" -ForegroundColor Red
        $log += "FAIL   | $username | $($_.Exception.Message)"
        $failed++
    }
}

# ── Summary ──────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  RESULTA:" -ForegroundColor Cyan
Write-Host "  Na-offboard:  $success users" -ForegroundColor Green
if ($failed -gt 0) {
Write-Host "  May error:    $failed users" -ForegroundColor Red }
Write-Host "============================================" -ForegroundColor Cyan

$log += ""
$log += "--------------------------------------------"
$log += "Na-offboard: $success"
$log += "May error:   $failed"
$log += "--------------------------------------------"
$log | Out-File $logFile -Encoding UTF8

Write-Host ""
Write-Host " Log na-save sa: $logFile" -ForegroundColor Yellow
Write-Host ""
