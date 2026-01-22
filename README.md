# PowerShelli Juhuslike Kasutajate Generaator 🎲

PowerShelli automatiseerimisskript, mis on loodud õppe- ja testimiseesmärkidel. See genereerib **5 juhuslikku kasutajakontot**, miksides andmeid lähtefailidest. Skript puhastab kasutajanimed erimärkidest ja pakub käivitamisel paindlikku parooli seadistamise võimalust.

## 🚀 Funktsionaalsus

- **Juhuslik genereerimine**: Valib sisendfailidest automaatselt suvalised eesnimed, perenimed ja kirjeldused.
- **Kasutajanime puhastamine**: 
  - Teisendab nimed puhtale kujule `eesnimi.perenimi`.
  - Eemaldab täpitähed (nt `õ, ä, ö, ü` -> `o, a, o, u`).
  - Eemaldab tühikud ja sidekriipsud.
- **Paindlik parooliloogika**: 
  - **Staatiline režiim**: Määra üks kindel parool kõigile 5 kasutajale.
  - **Juhuslik režiim**: Genereeri igale kasutajale unikaalne ja turvaline parool (5-9 märki).
- **CSV Eksport**: Väljastab struktureeritud CSV faili, kasutades semikoolonit (`;`) eraldajana, mis sobib Exceli või Active Directory impordiks.

## 📂 Projekti struktuur

Skript vajab töötamiseks järgmisi faile samas kaustas:

| Faili nimi | Kirjeldus |
| :--- | :--- |
| `Eesnimed.txt` | Eesnimede lähtefail (üks nimi real). |
| `Perenimed.txt` | Perenimede lähtefail (üks nimi real). |
| `Kirjeldused.txt` | Ametikirjelduste/rollide lähtefail. |
| `new_users_accounts.csv` | **Väljundfail**, mille skript loob. |

## 🛠️ Kasutamine

1. **Lae alla** failid või klooni repositoorium.
2. **Veendu**, et sisendfailid (`.txt`) sisaldavad andmeid.
3. **Käivita skript** PowerSheillis mitte hiljema 7 versioni. Pakkumine 7.5.4v.

   ```powershell
   .\generate_users.ps1
