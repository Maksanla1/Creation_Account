<#
.SYNOPSIS
    Loeb CSV faili ja võimaldab kasutajaid arvutisse lisada või kustutada.
.DESCRIPTION
    Skript täidab järgmised ülesanded:
    1. Kontrollib administraatori õigusi.
    2. Pakub valikut: Lisa kasutajad või Kustuta üks kasutaja.
    3. Lisamisel kontrollib nime pikkust, duplikaate ja kirjelduse pikkust.
    4. Loob kasutaja nõudega vahetada parool esimesel sisselogimisel.
    5. Kustutamisel eemaldab nii kasutajakonto kui ka kodukausta.
#>

# Määrame konsooli kodeeringu UTF-8, et vältida probleeme sümbolitega
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- 1. KONTROLL: KAS ON ADMINISTRAATOR? ---
# Skript vajab kasutajate loomiseks ja kustutamiseks kõrgendatud õigusi
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if (-not $IsAdmin) {
    Write-Warning "VIGA: Seda skripti peab kaivitama ADMINISTRAATORI oigustes!"
    exit
}

# --- 2. SEADISTUS JA FAILIDE LUGEMINE ---
$CsvFail = "new_users_accounts.csv"

# Kontrollime, kas andmefail on olemas
if (-not (Test-Path $CsvFail)) {
    Write-Error "CSV faili '$CsvFail' ei leitud! Kaivita enne esimene skript."
    exit
}

# Laeme andmed muutujasse
$CsvAndmed = Import-Csv -Path $CsvFail -Delimiter ";" -Encoding UTF8

# --- 3. PEAMENÜÜ ---
Clear-Host
Write-Host "--- KASUTAJATE HALDUS ---" -ForegroundColor Cyan
Write-Host "Vali tegevus:"
Write-Host "[L] Lisa koik kasutajad failist susteemi"
Write-Host "[K] Kustuta uks kasutaja susteemist"
$Valik = Read-Host "Sinu valik"

# --- TEGEVUS 1: KASUTAJATE LISAMINE ---
if ($Valik -match "^(l|L)$") {
    Write-Host "`nAlustan kasutajate lisamist..." -ForegroundColor Yellow
    
    foreach ($Rida in $CsvAndmed) {
        $User = $Rida.Kasutajanimi
        $Pass = $Rida.Parool
        $FullName = "$($Rida.Eesnimi) $($Rida.Perenimi)"
        $Desc = $Rida.Kirjeldus
        
        # --- KONTROLLID (NÕUDED) ---
        
        # 1. Kasutajanimi on liiga pikk (üle 20 tähemärgi)
        if ($User.Length -gt 20) {
            Write-Warning "EI SAA LISADA '$User': Kasutajanimi on liiga pikk (>20 marki)."
            continue
        }

        # 2. Kirjeldus on liiga pikk (üle 48 tähemärgi)
        # Kui on liiga pikk, siis lühendame ja anname hoiatuse
        if ($Desc.Length -gt 48) {
            Write-Warning "HOIATUS '$User': Kirjeldus liiga pikk. Karbitud 48 margini."
            $Desc = $Desc.Substring(0, 48)
        }

        # 3. Kasutaja on juba olemas (Duplikaat)
        if (Get-LocalUser -Name $User -ErrorAction SilentlyContinue) {
            Write-Warning "EI SAA LISADA '$User': Kasutaja on juba susteemis olemas (Duplikaat)."
            # Ülesande järgi ei saa lisada, seega liigume järgmise juurde
            continue 
        }

        # --- KASUTAJA LOOMINE ---
        try {
            # Teisendame parooli turvalisele kujule
            $SecurePass = ConvertTo-SecureString $Pass -AsPlainText -Force
            
            # Loome uue kasutaja
            # -PasswordChangeRequiredOnLogin $true täidab nõude: "esmakordsel sisselogimisel peab kasutaja parooli muutma"
            New-LocalUser -Name $User `
                          -Password $SecurePass `
                          -FullName $FullName `
                          -Description $Desc `
                          -PasswordChangeRequiredOnLogin $true `
                              -ErrorAction Stop | Out-Null
            
            # Lisame kasutaja gruppi "Users"
            Add-LocalGroupMember -Group "Users" -Member $User
            
            Write-Host "OK: Loodi kasutaja '$User'. Nouab parooli vahetust." -ForegroundColor Green
        }
        catch {
            Write-Error "VIGA '$User' loomisel: $($_.Exception.Message)"
        }
    }

    # --- LÕPP-RAPORT (NÕUE: Näita lisatud kasutajaid) ---
    Write-Host "`n--- HETKEL ARVUTIS OLEVAD TAVAKASUTAJAD ---" -ForegroundColor Cyan
    # Filtreerime välja süsteemsed kontod, et näidata ainult loodud kasutajaid
    Get-LocalUser | Where-Object { 
        $_.Enabled -eq $true -and 
        $_.Name -ne "Administrator" -and 
        $_.Name -ne "Guest" -and 
        $_.Name -notmatch "WDAGUtilityAccount" -and 
        $_.Name -notmatch "DefaultAccount"
    } | Select-Object Name, FullName, Description | Format-Table -AutoSize

}
# --- TEGEVUS 2: KASUTAJA KUSTUTAMINE ---
elseif ($Valik -match "^(k|K)$") {
    
    # Leiame kõik tavakasutajad (välistame admini ja guesti)
    $SusteemiKasutajad = Get-LocalUser | Where-Object { $_.Name -ne "Administrator" -and $_.Name -ne "Guest" -and $_.Name -notmatch "WDAG" }
    
    if ($SusteemiKasutajad.Count -eq 0) {
        Write-Warning "Arvutis ei leitud uhtegi kustutatavat tavakasutajat."
        exit
    }

    Write-Host "`n--- VALI KASUTAJA KUSTUTAMISEKS ---" -ForegroundColor Cyan
    # Kuvame nimekirja numbritega
    for ($i=0; $i -lt $SusteemiKasutajad.Count; $i++) {
        Write-Host "[$($i+1)] $($SusteemiKasutajad[$i].Name)"
    }

    $KustutaValik = Read-Host "`nSisesta number, keda kustutada"

    # Kontrollime, kas sisestati korrektne number
    if ($KustutaValik -match '^\d+$' -and [int]$KustutaValik -ge 1 -and [int]$KustutaValik -le $SusteemiKasutajad.Count) {
        $ValitudKasutaja = $SusteemiKasutajad[[int]$KustutaValik - 1]
        $Nimi = $ValitudKasutaja.Name
        
        Write-Host "Kustutan kasutajat '$Nimi'..." -ForegroundColor Yellow
        
        # 1. Kustutame kasutajakonto
        try {
            Remove-LocalUser -Name $Nimi -ErrorAction Stop
            Write-Host "Kasutaja konto kustutatud." -ForegroundColor Green
        }
        catch {
            Write-Error "Viga kasutaja kustutamisel: $($_.Exception.Message)"
            exit
        }

        # 2. Kustutame kodukausta (NÕUE: Sisseloginud kasutaja kaust kustutada)
        $KoduKaust = "C:\Users\$Nimi"
        if (Test-Path $KoduKaust) {
            Write-Host "Leiti kodukaust: $KoduKaust. Kustutan..."
            try {
                Remove-Item -Path $KoduKaust -Recurse -Force -ErrorAction Stop
                Write-Host "Kodukaust kustutatud." -ForegroundColor Green
            }
            catch {
                Write-Warning "Ei saanud kodukausta kustutada (voib olla lukus voi oiguste probleem)."
            }
        } else {
            Write-Host "Kodukausta ei leitud (kasutaja polnud sisse loginud)." -ForegroundColor Gray
        }

    } else {
        Write-Warning "Vigane valik. Skript lopetas too."
    }

} else {
    Write-Warning "Tundmatu valik. Vali 'L' (Lisa) voi 'K' (Kustuta)."
}

Write-Host "`nSkript lopetas too." -ForegroundColor Gray
