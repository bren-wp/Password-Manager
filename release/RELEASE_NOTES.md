# Veldigo v0.2.6 Preview 1 — sigurnost i stabilnost

Veldigo je lokalni šifrirani trezor lozinki za Android i Windows.

## Poboljšanja
- Dodatna zaštita prethodnih šifriranih kopija nakon promjene glavne lozinke. Stariji checkpointi ostaju sačuvani za autentificirani oporavak umjesto da blokiraju novo spremanje.
- Kada se trezor zaključa, aplikacija zatvara otvorene dijaloge koji bi inače mogli ostati iznad zaslona za prijavu.
- Mobilno pretraživanje trezora prilagođeno je otvorenoj tipkovnici i manjim visinama zaslona.
- Stroži vizualni audit prepoznaje i promjenu jednog RGB kanala te zasebno izvještava o dimenzijama, granicama pogrešaka i udjelu različitih piksela.
- Dodani regresijski testovi rotacije glavne lozinke, zaključavanja otvorenih dijaloga i usporedbe slika.
- Provjera SHA-256 kontrolnih zbrojeva za svih pet distribucijskih binarnih paketa prije objave.

## Važna ograničenja
Ovo je **predizdanje**. Usporedba svih 26 zaslona s izvornim referentnim arhivama nije završena, pa nije potvrđena pixel-perfect 1:1 podudarnost. Nisu provedeni neovisni penetracijski test ni fizički Android/Windows testovi. APK/AAB i Windows binarni paketi nisu predstavljeni kao produkcijski potpisana izdanja; prije javne distribucije potrebno je odgovarajuće izdavačko potpisivanje.

Šifrirani format trezora, AES-256-GCM i Argon2id nisu promijenjeni.
