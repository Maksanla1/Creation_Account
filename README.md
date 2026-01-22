# Windowsi Kasutajakontode Automatiseerimine (PowerShell) 🚀

See projekt koosneb kahest PowerShelli skriptist, mis on loodud Windowsi kasutajakontode massiliseks haldamiseks. Esimene skript genereerib andmed ja teine skript loob nende põhjal reaalsed süsteemikasutajad, seadistades paroolipoliitika ja grupiõigused.

## 📂 Failide Kirjeldus

### 1. `generate_users.ps1` (Andmete genereerija)
See skript valmistab ette andmed kasutajate loomiseks.
- **Sisend:** Loeb nimed ja ametikirjeldused failidest `Eesnimed.txt`, `Perenimed.txt` ja `Kirjeldused.txt`.
- **Töötlus:** 
  - Genereerib suvalised kasutajad.
  - Puhastab nimed täpitähtedest (nt `Jüri` -> `juri`).
  - Loob unikaalsed paroolid (või kasutab ühist parooli).
- **Väljund:** Salvestab tulemuse faili `new_users_accounts.csv`.

### 2. `manage_users.ps1` (Süsteemi haldur)
See skript teeb tegelikud muudatused arvutis (Admin õigustega).
- **Interaktiivne menüü:** Võimaldab valida lisamise ja kustutamise vahel.
- **Lisamine:** 
  - Loeb CSV faili ja loob kasutajad Windowsi süsteemi.
  - Lisab kasutajad `Users` gruppi.
  - **Nõuab parooli vahetust:** Esmakordsel sisselogimisel peab kasutaja parooli muutma.
  - Kontrollib nime pikkust (max 20) ja duplikaate.
- **Kustutamine:**
  - Eemaldab kasutajakonto.
  - Kustutab kasutaja kodukausta (`C:\Users\Nimi`).

---

## ⚙️ Nõuded (Prerequisites)

- **OS:** Windows 10 või Windows 11.
- **PowerShell:** Versioon 5.1 või uuem (soovitatav käivitada administraatorina).
- **Failid:** Skriptid peavad asuma samas kaustas tekstifailidega (`.txt`).

---

## 🚀 Kuidas käivitada (Step-by-Step)

### Samm 1: Lae failid alla
Klooni see repositoorium või lae failid alla oma arvutisse.
```bash
git clone https://github.com/SinuKasutaja/Account_creation.git
cd Account_creation


### Samm 2: Luba skriptide käivitamine (TÄHTIS!) ⚠️
Vaikimisi keelab Windows võõraste skriptide töö (annab vea running scripts is disabled). Selle parandamiseks tee nii:

Ava PowerShell.

Käivita see käsk (lubab sinu kasutajal skripte käivitada):

powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
(Kui küsitakse kinnitust, vajuta Y või A ja Enter)