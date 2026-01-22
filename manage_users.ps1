<#
.SYNOPSIS
    Loeb CSV faili ja võimaldab kasutajaid süsteemi lisada või kustutada.
.DESCRIPTION
    - Kui kasutaja on olemas, muudab tema parooli.
    - Kui kasutajat pole, loob uue.
    - Kustutamisel eemaldab konto ja kodukausta.
#>

# --- 1. KONTROLL: KAS ON ADMIN? ---
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if (-not $IsAdmin) {
    Write-Warning "VIGA: Seda skripti peab käivitama ADMINISTRAATORI õigustes!"
    exit
}

# --- 2. SEADISTUS ---
$CsvFail = "new_users_accounts.csv"

if (-not (Test-Path $CsvFail)) {
    Write-Error "CSV faili '$CsvFail' ei leitud! Käivita enne esimene skript."
    exit
}

$CsvAndmed = Import-Csv -Path $CsvFail -Delimiter ";" -Encoding UTF8

# --- 3. MENÜÜ ---
Clear-Host
Write-Host "--- KASUTAJATE HALDUS ---" -ForegroundColor Cyan
Write-Host "Vali tegevus:"
Write-Host "[L] Lisa/Uuenda kasutajad failist"
Write-Host "[K] Kustuta üks kasutaja süsteemist"
$Valik = Read-Host "Sinu valik"

# --- TEGEVUS: LISAMINE / UUENDAMINE ---
if ($Valik -match "^(l|L)$") {
    Write-Host "`nAlustan kasutajate töötlemist..." -ForegroundColor Yellow
    
    foreach ($Rida in $CsvAndmed) {
        $User = $Rida.Kasutajanimi
        $Pass = $Rida.Parool
        $FullName = "$($Rida.Eesnimi) $($Rida.Perenimi)"
        $Desc = $Rida.Kirjeldus
        
        # --- KONTROLLID ---
        if ($User.Length -gt 20) {
            Write-Warning "VIGA '$User': Nimi liiga pikk (>20). Jätan vahele."
            continue
        }

        if ($Desc.Length -gt 48) {
            Write-Warning "HOIATUS '$User': Kirjeldus liiga pikk. Kärbin 48 märgini."
            $Desc = $Desc.Substring(0, 48)
        }

        $SecurePass = ConvertTo-SecureString $Pass -AsPlainText -Force

        # --- KAS KASUTAJA ON OLEMAS? ---
        if (Get-LocalUser -Name $User -ErrorAction SilentlyContinue) {
            # KASUTAJA ON OLEMAS -> MUUDAME PAROOLI
            try {
                Set-LocalUser -Name $User -Password $SecurePass -Description $Desc -ErrorAction Stop
                
                # Nõuame uuesti parooli vahetust, kuna administraator muutis seda
                # (See käsk võib mõnes Windowsi versioonis erineda, aga proovime standardset)
                # Set-LocalUser ei toeta otse -PasswordChangeRequiredOnLogin, kasutame WMI/CIM või ignoreerime seda uuendamisel.
                # Lihtsuse mõttes uuendamisel me ei sunni parooli vahetust uuesti, või teeme seda nii:
                # $UserObj = [ADSI]"WinNT://./$User,user"
                # $UserObj.PasswordExpired = 1
                # $UserObj.SetInfo()

                Write-Host "INFO: Kasutaja '$User' oli juba olemas. PAROOL MUUDETUD." -ForegroundColor Cyan
            }
            catch {
                Write-Error "VIGA '$User' uuendamisel: $($_.Exception.Message)"
            }
        }
        else {
            # KASUTAJAT POLE -> LOOME UUE
            try {
                New-LocalUser -Name $User `
                              -Password $SecurePass `
                              -FullName $FullName `
                              -Description $Desc `
                              -PasswordChangeRequiredOnLogin $true `
                              -ErrorAction Stop | Out-Null
                
                Add-LocalGroupMember -Group "Users" -Member $User
                
                Write-Host "OK: Loodi uus kasutaja '$User'" -ForegroundColor Green
            }
            catch {
                Write-Error "VIGA '$User' loomisel: $($_.Exception.Message)"
            }
        }
    }

    # --- LÕPP-RAPORT ---
    Write-Host "`n--- HETKEL SÜSTEEMIS OLEVAD TAVAKASUTAJAD ---" -ForegroundColor Cyan
    Get-LocalUser | Where-Object { 
        $_.Enabled -eq $true -and 
        $_.Name -ne "Administrator" -and 
        $_.Name -ne "Guest" -and 
        $_.Name -notmatch "WDAGUtilityAccount" -and 
        $_.Name -notmatch "DefaultAccount"
    } | Select-Object Name, FullName, Description | Format-Table -AutoSize

}
# --- TEGEVUS: KUSTUTAMINE ---
elseif ($Valik -match "^(k|K)$") {
    
    $SüsteemiKasutajad = Get-LocalUser | Where-Object { $_.Name -ne "Administrator" -and $_.Name -ne "Guest" -and $_.Name -notmatch "WDAG" }
    
    if ($SüsteemiKasutajad.Count -eq 0) {
        Write-Warning "Süsteemis ei leitud ühtegi kustutatavat tavakasutajat."
        exit
    }

    Write-Host "`n--- VALI KASUTAJA KUSTUTAMISEKS ---" -ForegroundColor Cyan
    for ($i=0; $i -lt $SüsteemiKasutajad.Count; $i++) {
        Write-Host "[$($i+1)] $($SüsteemiKasutajad[$i].Name)"
    }

    $KustutaValik = Read-Host "`nSisesta number, keda kustutada"

    if ($KustutaValik -match '^\d+$' -and [int]$KustutaValik -ge 1 -and [int]$KustutaValik -le $SüsteemiKasutajad.Count) {
        $ValitudKasutaja = $SüsteemiKasutajad[[int]$KustutaValik - 1]
        $Nimi = $ValitudKasutaja.Name
        
        Write-Host "Kustutan kasutajat '$Nimi'..." -ForegroundColor Yellow
        
        try {
            Remove-LocalUser -Name $Nimi -ErrorAction Stop
            Write-Host "Kasutaja konto kustutatud." -ForegroundColor Green
        }
        catch {
            Write-Error "Viga kasutaja kustutamisel: $($_.Exception.Message)"
            exit
        }

        $KoduKaust = "C:\Users\$Nimi"
        if (Test-Path $KoduKaust) {
            Write-Host "Leiti kodukaust: $KoduKaust. Kustutan..."
            try {
                Remove-Item -Path $KoduKaust -Recurse -Force -ErrorAction Stop
                Write-Host "Kodukaust kustutatud." -ForegroundColor Green
            }
            catch {
                Write-Warning "Ei saanud kodukausta kustutada. Võib-olla on lukus."
            }
        } else {
            Write-Host "Kodukausta ei olnud." -ForegroundColor Gray
        }

    } else {
        Write-Warning "Vigane valik."
    }

} else {
    Write-Warning "Tundmatu valik. Vali 'L' või 'K'."
}

Write-Host "`nSkript lõpetas töö." -ForegroundColor Gray
