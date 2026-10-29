# Veldigo v0.3.1 Preview 1 — Android + Windows

**Predizdanje za provjeru. Nije produkcijski certificirano ni potpuno RGB-identično referencama.**
Verzija: 0.3.1+14. Autor/izdavač: Brendigo.

## Funkcionalne i vizualne promjene
- Android i Windows generator lozinki imaju pet jednako širokih vizualnih segmenata snage lozinke, prema izvornim konceptima.
- Android generator zadržava kompaktne retke, kako primarna radnja ostaje vidljiva iznad donje navigacije pri tipičnom mobilnom viewportu.
- Poboljšan je završni dio zaslona otključavanja na telefonu.
- Prošireni testovi pokrivaju responzivnost, vidljivost gumba, generiranje lozinki, osnovne UI interakcije i regresije zaključavanja.
- 26 originalnih dizajnerskih PNG-ova uspoređeno je s 26 Flutter testnih snimki; dimenzije su uparene, ali **0/26 je pixel-perfect**. Nije rađeno lažno rastezanje prikaza.

## Sigurnost i privatnost
- Osjetljiva polja (glavne lozinke, lozinke zapisa, TOTP ključ, CVV, šifrirane bilješke, lozinke uvoza/opravka) isključuju personalizirano učenje tipkovnice, automatske zamjene navodnika/crtica te relevantne prijedloge.
- Zadržan lokalni AES-256-GCM/Argon2id format trezora. Nema nove vlastite enkripcije niti promjene formata kompatibilnih sigurnosnih kopija.
- Android: minSdk 24, targetSdk 36, Gradle 9.6.0, Android Gradle Plugin 9.5.0; OS backup trezora i nezaštićeni promet ostaju onemogućeni.
- Preview Android AAB koristi razvojni potpis (Nije za Google Play produkciju). Windows binarni programi nisu Authenticode potpisani.

## Sadržaj izdanja
- Veldigo-Android.apk; Veldigo-Android.aab
- Veldigo-portable.exe; Veldigo-Setup.exe; Veldigo-Windows-portable.zip
- Android-SHA256.txt; Windows-SHA256.txt

## Ograničenja
Flutter testne snimke nisu dokaz izgleda na fizičkim Android/Windows uređajima. Nema garancije potpunog 1:1 vizualnog poklapanja, apsolutne sigurnosti ni dovršenog vanjskog penetracijskog testiranja. Biometrija i Windows Hello iz dizajnerskog koncepta nisu predstavljeni kao funkcionalni dok ne postoji sigurnosno provjerena integracija.
