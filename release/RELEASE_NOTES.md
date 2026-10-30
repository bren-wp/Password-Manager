# Veldigo v0.3.4 Preview 1 — Android & Windows

**Verzija aplikacije:** `0.3.4+17`. **Izdanje:** `v0.3.4-preview.1`.
**Status:** Testno Preview izdanje. Ova verzija nije produkcijski potpisana ni sigurnosno certificirana.

## Android — poboljšanja sučelja

- **Glavni trezor (01):** odvojene kartice zapisa, lokalno crtane oznake poznatih usluga, sigurnosna kartica, preglednije zaglavlje i funkcionalno sortiranje po nedavnom datumu, nazivu ili najstarijim zapisima.
- **Postavljanje i otključavanje (02–03):** prilagođene veličine logotipa, razmaci, sigurnosne informacije i pomoć kod zaboravljene glavne lozinke. Pomoć izričito ne obećava nesiguran reset lozinke.
- **Dodavanje lozinke (04):** redizajn mobilnog obrasca s lokalnim predlošcima usluge, urednijim poljima, procjenom jačine, generiranjem i prikazom lozinke, kategorijom, sigurnom bilješkom i favoritima. Primarni gumb za spremanje ostaje dostupan pri dnu.
- **Detalji lozinke (05):** zasebne kartice, lokalno nacrtana oznaka usluge, maskirana lozinka, kontrole za kopiranje i uređivanje, podaci o zapisu te premještanje u Koš. Radnja dijeljenja nije uključena jer ne postoji verificiran siguran protokol.
- Ispravljen uski Android AppBar (`RenderFlex overflow`) na zaslonu detalja. Dodani testovi izvanredno malih zaslona te testovi koji ciljaju sadržaj detalja, a ne statistiku na početnom zaslonu.

## Windows i zajednički brending

- Prilagođen split-screen prikaz postavljanja i otključavanja, pozadinski gradijent, raspored i informativne sigurnosne stavke.
- Windows generator lozinki prati referentni raspon **8–64** znaka, dok Android i dalje podržava **8–128**.
- Zajednički lokalni vektorski znak Veldigo: zaobljeni osvijetljeni štit s ispunjenim slovom V.
- Windows instalacijski paket sada ima ispravnu oznaku verzije **0.3.4-preview.1**, umjesto zastarjelog metapodatka 0.2.5.

## Sigurnost i testovi

- AES-256-GCM, Argon2id i postojeći `.veldigo` format trezora **nisu mijenjani**; migracija nije potrebna.
- Sva korisnička imena, lozinke i lokalne kopije ostaju u postojećoj privatnoj pohrani. Ne dohvaćaju se ikone servisa putem interneta.
- Proširen skup Flutter widget testova: skrivanje/prikaz tajni, sigurno kopiranje, neuspjelo spremanje, sortiranje i traženje, odgovarajuće veličine Android ekrana te zatvaranje prikaza pri zaključavanju.
- Objava je uvjetovana punom Flutter analizom i testovima, Android APK/AAB i Windows buildovima te SHA-256 provjerama svih binarnih datoteka.

## Datoteke za preuzimanje

- `Veldigo-Android.apk`
- `Veldigo-Android.aab`
- `Veldigo-portable.exe`
- `Veldigo-Setup.exe`
- `Veldigo-Windows-portable.zip`
- `Android-SHA256.txt`, `Windows-SHA256.txt`

## Važna ograničenja

- Android APK/AAB u ovom Preview workflowu koristi **razvojni potpis**. AAB **nije spreman za nadogradnju na Google Playu** bez odgovarajućeg privatnog upload keystorea. Nemojte pokušati zamijeniti postojeće instalacije drugačijim potpisom.
- Windows EXE i Setup nisu Authenticode-potpisani; Windows može pokazati sigurnosno upozorenje.
- Dizajn se razvija zaslon po zaslon. Postoje stvarne Flutter snimke 15 Android i 11 Windows prikaza, ali **pixel-perfect 1:1 podudarnost nije dokazana**. Veličina PNG-a ne dokazuje podudarnost boja, tipografije i elemenata; dio odstupanja odnosi se na OS chrome.
- Izdanje je namijenjeno testiranju, a ne tvrdnji o certificiranoj produkcijskoj sigurnosti.
