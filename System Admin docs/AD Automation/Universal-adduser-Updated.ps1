# ============================================================
# TOOL NAME: New-BulkADUser (Modular Version)
# PURPOSE: Professional User Onboarding Automation
# CREATED BY: Jose Antonio Acebuche
# ============================================================

function New-BulkADUser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$CSVPath,

        [Parameter(Mandatory=$true)]
        [string]$DomainName,

        [Parameter(Mandatory=$true)]
        [hashtable]$OUMapping,

        [Parameter(Mandatory=$false)]
        [hashtable]$GroupMapping = @{},

        # OPTIONAL: File Server Shares para sa Profiles at Home Directories
        [Parameter(Mandatory=$false)]
        [string]$FileServerPath,

        [Parameter(Mandatory=$false)]
        [string]$HomeDriveLetter = "H:",

        [string]$LogPath = ".\AD_Creation_Log.txt"
    )

    process {
        # STEP 1: Siguraduhin na nahanap ang CSV file bago magpatuloy
        if (-not (Test-Path $CSVPath)) { 
            Write-Error "CSV file not found sa path na: $CSVPath" 
            return 
        }

        # STEP 2: Basahin ang CSV at i-store sa variable na $users
        $users = Import-Csv $CSVPath
        $log = @()

        # STEP 3: Isa-isang i-process ang bawat row sa CSV
        foreach ($u in $users) {
            
            $username = $u.Username.ToLower().Trim()
            $targetOU = $OUMapping[$u.Department]

            # Kung ang Department sa CSV ay wala sa $OUMapping listahan, i-skip ang user
            if (-not $targetOU) {
                Write-Host "[SKIP] No OU path found for Department: $($u.Department)" -ForegroundColor Yellow
                continue
            }

            try {
                # FALLBACK PASSWORD LOGIC:
                # Gagamit ng Password mula sa CSV. Kung blangko o wala, "Welcome@1234" ang gagamitin.
                $rawPassword = if ([string]::IsNullOrWhiteSpace($u.Password)) { "Welcome@1234" } else { $u.Password }
                $securePassword = ConvertTo-SecureString $rawPassword -AsPlainText -Force

                # STEP 4: "SPLAT-ING" - Active Directory User Parameters
                $params = @{
                    Name                  = "$($u.FirstName) $($u.LastName)" # Display Name
                    SamAccountName        = $username                        # Login ID
                    UserPrincipalName     = "$username@$DomainName"          # Email/UPN Login
                    Path                  = $targetOU                        # Target OU Folder
                    AccountPassword       = $securePassword
                    Enabled               = $true                            # Active agad ang account
                    ChangePasswordAtLogon = $true                            # kailangang magpalit sa 1st login
                    Title                 = $u.JobTitle
                    Department            = $u.Department
                }

                # AUTOMATIC HOME PATH & PROFILE PATH COMPUTATION
                if ($FileServerPath) {
                    $cleanFileServer = $FileServerPath.TrimEnd('\')
                    $params["ProfilePath"]   = "$cleanFileServer\Profiles\$username"
                    $params["HomeDirectory"] = "$cleanFileServer\Home\$username"
                    $params["HomeDrive"]     = $HomeDriveLetter
                }

                # Executing New-ADUser gamit ang splatted parameters (@params)
                New-ADUser @params
                Write-Host "[OK] Created: $username" -ForegroundColor Green

                # STEP 5: GROUP MAPPING - Access Level Grouping
                $accessLevel = if ($u.AccessLevel) { $u.AccessLevel } else { "FullControl" }
                $groupName = "FS_$($u.Department)_$accessLevel"
                
                # I-check muna kung ang group ay umiiral sa Active Directory bago mag-add
                if ($groupName -and (Get-ADGroup -Filter "Name -eq '$groupName'")) {
                    Add-ADGroupMember -Identity $groupName -Members $username
                    Write-Host "     -> Added to Group: $groupName" -ForegroundColor Cyan
                }

                # Record successful creation sa log array
                $log += "$(Get-Date -Format 'HH:mm:ss') | SUCCESS | $username | $($u.Department)"
            } 
            catch {
                # STEP 6: ERROR HANDLING - Kapag may mali (ex: duplicate user)
                Write-Host "[FAIL] $username : $($_.Exception.Message)" -ForegroundColor Red
                $log += "$(Get-Date -Format 'HH:mm:ss') | ERROR | $username | $($_.Exception.Message)"
            }
        }

        # STEP 7: I-save ang lahat ng nangyari sa log file
        $log | Out-File $LogPath -Encoding UTF8
    }
}


# ============================================================
# MODULAR CONTROL PANEL (Shadow OU Root Config & Execution)
# ============================================================

# 1. DOMAIN AT ROOT CONFIGURATION
$domain     = "DC=ACEBUCHE,DC=local"
$shadowRoot = "OU=Shadow,$domain"

# 2. OU MAPPING TABLE
$MyOUs = @{
    "IT"         = "OU=Users,OU=IT,$shadowRoot"
    "HR"         = "OU=Users,OU=HR,$shadowRoot"
    "Finance"    = "OU=Users,OU=Finance,$shadowRoot"
    "Management" = "OU=Users,OU=Management,$shadowRoot"
}

# 3. TAWAGIN ANG FUNCTION
New-BulkADUser -CSVPath ".\acebuche-users.csv" `
               -DomainName "ACEBUCHE.local" `
               -OUMapping $MyOUs `
               -FileServerPath "\\FS01" `
               -HomeDriveLetter "H:"