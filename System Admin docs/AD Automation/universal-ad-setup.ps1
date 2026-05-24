# ============================================================
#  UNIVERSAL AD SETUP SCRIPT
#  Pwede gamitin sa kahit anong company
#
#  PAANO I-CUSTOMIZE:
#  1. Palitan ang $domain ng domain ng company
#  2. Palitan ang $departments ng actual na departments
#  3. I-run bilang Administrator sa Domain Controller
#
#  GAGAWIN NG SCRIPT:
#  - Gumawa ng Main OU (Shadow)
#  - Gumawa ng Department OUs
#  - Gumawa ng Users, Computers, Groups sa bawat dept
#  - Gumawa ng Security Groups para sa File Server
# ============================================================

# ██████████████████████████████████████████████████████████
# ██  I-EDIT LANG DITO — WALA NANG IBA KAILANGAN BAGUHIN  ██
# ██████████████████████████████████████████████████████████

$domain      = "DC=ACEBUCHE,DC=local"    # <- Palitan ng domain ng company
$mainOU      = "Shadow"                   # <- Pwedeng palitan (hal. "COMPANY", "CORP")
$departments = @(                         # <- Palitan ng actual na departments
    "IT",
    "Finance",
    "HR",
    "Management"
    "Disabled Users"
    # Dagdag pa kung kailangan:
    # "Operations",
    # "Sales",
    # "Legal"
)

# ██████████████████████████████████████████████████████████
# ██            HUWAG NA BAGUHIN PAGKATAPOS NITO           ██
# ██████████████████████████████████████████████████████████

Clear-Host
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   UNIVERSAL AD SETUP SCRIPT               " -ForegroundColor Cyan
Write-Host "   Domain : $domain                        " -ForegroundColor Cyan
Write-Host "   Main OU: $mainOU                        " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$success = 0
$failed  = 0

# ── STEP 1: Gumawa ng Main OU ────────────────────────────────
Write-Host "[STEP 1] Gumagawa ng Main OU: $mainOU..." -ForegroundColor Yellow
try {
    New-ADOrganizationalUnit -Name $mainOU -Path $domain -ErrorAction Stop
    Write-Host "         [OK] $mainOU nagawa na." -ForegroundColor Green
    $success++
} catch {
    if ($_.Exception.Message -like "*already in use*") {
        Write-Host "         [EXIST] $mainOU - Existing na, OK lang." -ForegroundColor DarkYellow
    } else {
        Write-Host "         [FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""

# ── STEP 2: Gumawa ng Department OUs ────────────────────────
Write-Host "[STEP 2] Gumagawa ng Department OUs..." -ForegroundColor Yellow

foreach ($dept in $departments) {

    Write-Host ""
    Write-Host "  --> $dept" -ForegroundColor White

    # Gumawa ng Department OU
    try {
        New-ADOrganizationalUnit -Name $dept -Path "OU=$mainOU,$domain" -ErrorAction Stop
        Write-Host "      [OK] OU=$dept nagawa." -ForegroundColor Green
        $success++
    } catch {
        if ($_.Exception.Message -like "*already in use*") {
            Write-Host "      [EXIST] OU=$dept - Existing na, OK lang." -ForegroundColor DarkYellow
        } else {
            Write-Host "      [FAIL] OU=$dept - $($_.Exception.Message)" -ForegroundColor Red
            $failed++
            continue
        }
    }

    # Gumawa ng Sub-OUs: Users, Computers, Groups
    $subOUs = @("Users", "Computers", "Groups")
    foreach ($sub in $subOUs) {
        try {
            New-ADOrganizationalUnit -Name $sub -Path "OU=$dept,OU=$mainOU,$domain" -ErrorAction Stop
            Write-Host "      [OK] OU=$sub,OU=$dept nagawa." -ForegroundColor Green
            $success++
        } catch {
            if ($_.Exception.Message -like "*already in use*") {
                Write-Host "      [EXIST] OU=$sub,OU=$dept - Existing na." -ForegroundColor DarkYellow
            } else {
                Write-Host "      [FAIL] OU=$sub,OU=$dept - $($_.Exception.Message)" -ForegroundColor Red
                $failed++
            }
        }
    }
}

Write-Host ""

# ── STEP 3: Gumawa ng Security Groups para sa File Server ────
Write-Host "[STEP 3] Gumagawa ng File Server Security Groups..." -ForegroundColor Yellow
Write-Host ""

foreach ($dept in $departments) {

    $groupPath = "OU=Groups,OU=$dept,OU=$mainOU,$domain"

    # FullControl Group
    $fcGroup = "FS_${dept}_FullControl"
    try {
        New-ADGroup -Name $fcGroup -GroupScope Global -GroupCategory Security `
            -Path $groupPath -Description "File Server Full Control - $dept" -ErrorAction Stop
        Write-Host "  [OK] $fcGroup nagawa." -ForegroundColor Green
        $success++
    } catch {
        if ($_.Exception.Message -like "*already in use*") {
            Write-Host "  [EXIST] $fcGroup - Existing na." -ForegroundColor DarkYellow
        } else {
            Write-Host "  [FAIL] $fcGroup - $($_.Exception.Message)" -ForegroundColor Red
            $failed++
        }
    }

    # ReadOnly Group
    $roGroup = "FS_${dept}_ReadOnly"
    try {
        New-ADGroup -Name $roGroup -GroupScope Global -GroupCategory Security `
            -Path $groupPath -Description "File Server Read Only - $dept" -ErrorAction Stop
        Write-Host "  [OK] $roGroup nagawa." -ForegroundColor Green
        $success++
    } catch {
        if ($_.Exception.Message -like "*already in use*") {
            Write-Host "  [EXIST] $roGroup - Existing na." -ForegroundColor DarkYellow
        } else {
            Write-Host "  [FAIL] $roGroup - $($_.Exception.Message)" -ForegroundColor Red
            $failed++
        }
    }
}

Write-Host ""

# ── STEP 4: Ipakita ang final na structure ───────────────────
Write-Host "[STEP 4] Final OU Structure:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  $domain" -ForegroundColor Cyan
Write-Host "  └── $mainOU" -ForegroundColor White
foreach ($dept in $departments) {
    Write-Host "       ├── $dept" -ForegroundColor White
    Write-Host "       │    ├── Users" -ForegroundColor Gray
    Write-Host "       │    ├── Computers" -ForegroundColor Gray
    Write-Host "       │    └── Groups" -ForegroundColor Gray
    Write-Host "       │         ├── FS_${dept}_FullControl" -ForegroundColor DarkGreen
    Write-Host "       │         └── FS_${dept}_ReadOnly" -ForegroundColor DarkGreen
}

Write-Host ""
