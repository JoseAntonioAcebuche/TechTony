# ============================================================
# TOOL NAME: New-BulkADUser (Modular Version)
# PURPOSE: Professional User Onboarding Automation
# created by: jose antonio acebuche
# ============================================================

function New-BulkADUser {
    [CmdletBinding()] # Ginagawa itong official "Advanced Function" para mag-behave na parang tunay na Windows command
    param (
        [Parameter(Mandatory=$true)] # REQUIRED: Hindi gagana ang script kung walang CSV file
        [string]$CSVPath,

        [Parameter(Mandatory=$true)] # REQUIRED: Kailangan ang domain name (e.g., ACEBUCHE.local)
        [string]$DomainName,

        [Parameter(Mandatory=$true)] # REQUIRED: Ang listahan ng OUs base sa Department
        [hashtable]$OUMapping,

        [Parameter(Mandatory=$false)] # OPTIONAL: Pwedeng walang groups, hindi mag-e-error
        [hashtable]$GroupMapping = @{},

        [string]$LogPath = ".\AD_Creation_Log.txt" # Default location ng log file
    )

    process {
        # STEP 1: Siguraduhin na nahanap ang CSV file bago magpatuloy
        if (-not (Test-Path $CSVPath)) { 
            Write-Error "CSV file not found sa path na: $CSVPath"; 
            return 
        }

        # STEP 2: Basahin ang CSV at i-store sa variable na $users
        $users = Import-Csv $CSVPath
        $log = @()

        # STEP 3: Isa-isang i-process ang bawat row sa CSV
        foreach ($u in $users) {
            
            # Format ang username: lowercase, walang space sa dulo, at pagdugtungin ang FN at LN
            #$username = "$($u.FirstName.ToLower().Trim()).$($u.LastName.ToLower().Replace(' ',''))"
            $username =$u.Username.ToLower().Trim()
            # Hanapin kung saang OU dapat ilagay ang user base sa Department sa CSV
            $targetOU = $OUMapping[$u.Department]

            # Kung ang Department sa CSV ay wala sa $MyOUs listahan, i-skip ang user
            if (-not $targetOU) {
                Write-Host "[SKIP] No OU path found for Department: $($u.Department)" -ForegroundColor Yellow
                continue
            }

            try {
                # STEP 4: "SPLAT-ING" - Nililinis ang hitsura ng New-ADUser parameters
                $params = @{
                    Name                  = "$($u.FirstName) $($u.LastName)" # Display Name
                    SamAccountName        = $username                        # Login ID
                    UserPrincipalName     = "$username@$DomainName"          # Email/UPN Login
                    Path                  = $targetOU                        # Target OU Folder
                    AccountPassword       = (ConvertTo-SecureString $u.Password -AsPlainText -Force)
                    Enabled               = $true                            # Active agad ang account
                    ChangePasswordAtLogon = $true                            # Kailangan nilang magpalit ng password sa 1st login
                    Title                 = $u.JobTitle
                    Department            = $u.Department
                }

                # Executing the command gamit ang splatted parameters (@params)
                New-ADUser @params
                Write-Host "[OK] Created: $username" -ForegroundColor Green

                # STEP 5: GROUP MAPPING - I-check kung may group na dapat i-assign
                #$groupName = $GroupMapping[$u.Department] - ginagamit lang ito para sa walan access level 
                # Kung walang AccessLevel sa CSV — default ay FullControl
                $accessLevel = if ($u.AccessLevel) { $u.AccessLevel } else { "FullControl" }
                $groupName = "FS_$($u.Department)_$accessLevel"
                
                # I-check muna kung ang group ay nage-exist sa Active Directory bago mag-add
                if ($groupName -and (Get-ADGroup -Filter "Name -eq '$groupName'")) {
                    Add-ADGroupMember -Identity $groupName -Members $username
                    Write-Host "     -> Added to Group: $groupName" -ForegroundColor Cyan
                }

                # Record successful creation sa log array
                $log += "$(Get-Date -Format 'HH:mm:ss') | SUCCESS | $username | $($u.Department)"
            } 
            catch {
                # STEP 6: ERROR HANDLING - Kapag may mali (ex: duplicate user), dito babagsak
                Write-Host "[FAIL] $username : $($_.Exception.Message)" -ForegroundColor Red
                $log += "$(Get-Date -Format 'HH:mm:ss') | ERROR | $username | $($_.Exception.Message)"
            }
        }

        # STEP 7: I-save ang lahat ng nangyari sa log file (UTF8 para iwas sa weird symbols)
        $log | Out-File $LogPath -Encoding UTF8
    }
}


# ============================================================
# MODULAR CONTROL PANEL (Shadow OU Root Config)
# ============================================================

# Dito natin ise-set ang main domain path
$domain = "DC=ACEBUCHE,DC=local"

# Dito natin ise-set ang Root ng Shadow OU para hindi paulit-ulit
$shadowRoot = "OU=Shadow,$domain"

$MyOUs = @{
    "IT"         = "OU=Users,OU=IT,$shadowRoot"
    "HR"         = "OU=Users,OU=HR,$shadowRoot"
    "Finance"    = "OU=Users,OU=Finance,$shadowRoot"
    "Management" = "OU=Users,OU=Management,$shadowRoot"
}


# CSV mo:
# FirstName, LastName, Department, JobTitle, Password, AccessLevel
# Juan, Dela Cruz, HR, HR Officer, Welcome@2026!, FullControl
# Carlos, Ramos, Management, Dept Head, Welcome@2026!, ReadOnly

# 3. TAWAGIN ANG FUNCTION
# Gagamitin nito yung modular engine na ginawa natin kanina
New-BulkADUser -CSVPath ".\acebuche-users.csv" `
               -DomainName "ACEBUCHE.local" `
               -OUMapping $MyOUs
