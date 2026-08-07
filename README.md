# Hyvinvointiseuranta

Yksinkertainen, itse hostattava web-sovellus ruokavalion, turvotusoireiden, liikunnan ja energiataseen seurantaan. Toimii puhelimella ja tietokoneella, tallentaa tiedot pilvitietokantaan (Supabase) ja voidaan lisätä laitteen koti-/dock-valikkoon kuin oma sovellus.

Ei vaadi omaa palvelinta, kuukausimaksuja (ilmaistasot riittävät henkilökohtaiseen käyttöön) eikä sovelluskaupan hyväksyntää.

## Ominaisuudet

- **Ruokapäiväkirja** – ateriat, arvioitu energia, ainesosaryhmät (maito, gluteeni, sipuli/valkosipuli, palkokasvit, hiilihapote, alkoholi)
- **Turvotusseuranta** – tapahtumapohjainen kirjaus (vapaa määrä merkintöjä päivässä, ei kiinteitä kellonaikoja), vyötärömitta, oireet, epäilty aiheuttaja
- **Päivän aikajana** – ruoka- ja turvotusmerkinnät samalla aikajanalla, jotta syy-seuraussuhteet näkyvät suoraan
- **Liikuntapäiväkirja** – laji, kesto, koettu teho, fiilis
- **Energiatase** – perusaineenvaihdunta (Mifflin-St Jeor -kaava) + liikunnan arvioitu kulutus (MET-pohjainen) verrattuna syötyyn energiaan
- **Viikkoyhteenveto** – keskiarvot ja 14 päivän trendikäyrät
- **CSV-vienti** – koko ruokapäiväkirja ladattavaksi Excel/Numbers-yhteensopivana tiedostona, päiväkohtaisilla summariveillä
- **Kirjautuminen sähköpostilla** (magic link, ei salasanaa), data näkyy vain omalle tilille

## Arkkitehtuuri

```
Selain (puhelin/tietokone)
   │  staattinen index.html + JS
   ▼
GitHub Pages (hostaus, ilmainen)
   │  REST-kutsut
   ▼
Supabase (Postgres-tietokanta + autentikointi, ilmainen taso)
```

Ei build-vaihetta, ei backend-palvelinta, ei kehyksiä (frameworkeja) – yksi HTML-tiedosto, joka sisältää HTML:n, CSS:n ja JavaScriptin, ja puhuu suoraan Supabasen REST-rajapinnan kanssa selaimesta käsin.

## Ennakkovaatimukset

- Ilmainen [Supabase](https://supabase.com)-tili
- Ilmainen [GitHub](https://github.com)-tili
- Sähköpostiosoite kirjautumista varten

## Käyttöönotto

### 1. Luo Supabase-projekti

1. Mene [supabase.com](https://supabase.com) → luo tili → **New project**
2. Valitse projektille nimi ja lähin alue
3. Odota parisen minuuttia, että projekti valmistuu

### 2. Aja tietokantaskeema

1. Avaa projektissa **SQL Editor**
2. Kopioi tämän repon [`schema.sql`](./schema.sql) -tiedoston koko sisältö
3. Liitä se editoriin ja paina **Run**
4. Pitäisi näkyä "Success" – tämä luo neljä taulua (`food_entries`, `bloat_events`, `exercise_entries`, `user_profile`) valmiiksi suojattuna niin, että jokainen käyttäjä näkee vain omat tietonsa

### 3. Ota käyttöön sähköpostikirjautuminen

1. **Authentication → Providers → Email** – varmista että se on päällä
2. **Authentication → URL Configuration** – täytetään myöhemmin, kun sivun osoite on tiedossa (vaihe 5)

### 4. Hae API-avaimet

**Project Settings → API** -sivulta tarvitset:
- **Project URL** (esim. `https://xxxxxxxx.supabase.co`)
- **anon / publishable key** (pitkä `eyJ...`- tai `sb_publishable_...`-alkuinen merkkijono)

> Tämä avain on tarkoitettu julkiseksi selaimen koodissa – Row Level Security estää muita näkemästä toistensa dataa. **Älä** koskaan käytä `service_role`-avainta frontend-koodissa.

### 5. Aseta avaimet sovellukseen

Avaa [`index.html`](./index.html) ja muokkaa rivit tiedoston alkupuolella olevassa `<script>`-osiossa:

```javascript
const SUPABASE_URL = 'https://xxxxxxxx.supabase.co';
const SUPABASE_KEY = 'sb_publishable_...';
```

### 6. Julkaise GitHub Pagesilla

1. Luo uusi GitHub-repositorio (voi olla julkinen – koodi ei sisällä henkilökohtaista dataa, se on tietokannassa)
2. Lataa `index.html` repon juureen ("Add file → Upload files")
3. **Settings → Pages** → Source: **Deploy from a branch**, Branch: **main**, kansio **/(root)** → Save
4. Odota pari minuuttia, saat osoitteen muotoa `https://<käyttäjätunnus>.github.io/<repo>/`

### 7. Viimeistele Supabasen asetukset

Palaa Supabaseen → **Authentication → URL Configuration**:
- **Site URL** → GitHub Pages -osoitteesi
- **Redirect URLs** → sama osoite

### 8. Lisää koti-/dock-valikkoon

- **iPhone/iPad (Safari):** Jaa-kuvake → "Lisää Koti-valikkoon"
- **Mac (Safari, macOS Sonoma+):** File-valikko → "Add to Dock"

Sovellus toimii sen jälkeen kuin natiivi appi, tallentaen tiedot pilveen.

## Sähköpostin lähetysrajan nosto (valinnainen mutta suositeltu)

Supabasen sisäänrakennettu sähköpostilähetin sallii vain muutaman viestin tunnissa – riittää testaukseen muttei päivittäiseen käyttöön. Kytke oma SMTP:

**Project Settings → Authentication → SMTP Settings** → "Enable Custom SMTP"

Esimerkki Gmailin kautta:

| Kenttä | Arvo |
|---|---|
| Host | smtp.gmail.com |
| Port | 587 |
| Username | oma.osoite@gmail.com |
| Password | Google-tilin [sovelluskohtainen salasana](https://myaccount.google.com/apppasswords) (vaatii 2FA:n) |

Vaihtoehtoisesti [Resend](https://resend.com) tai [Postmark](https://postmarkapp.com) ovat helppoja pelkästään tähän tarkoitukseen rakennettuja palveluita.

## Energiataseen laskentakaavat

- **Perusaineenvaihdunta (BMR):** Mifflin-St Jeor
  - Miehet: `10 × paino(kg) + 6.25 × pituus(cm) − 5 × ikä + 5`
  - Naiset: `10 × paino(kg) + 6.25 × pituus(cm) − 5 × ikä − 161`
- **Arkiaktiivisuus:** BMR × kerroin (1.2 istumatyö / 1.375 kohtalainen / 1.55 aktiivinen)
- **Liikunnan kulutus:** MET-arvo (laji + koettu teho) × paino(kg) × kesto(h)

Nämä ovat vakiintuneita arvioita, eivät henkilökohtaisia mittaustuloksia – todellinen kulutus voi poiketa ±10–20 %.

## Teknologiat

- Puhdas HTML/CSS/JavaScript (ei framework-riippuvuuksia, ei build-vaihetta)
- [Supabase](https://supabase.com) – Postgres-tietokanta, autentikointi, REST-rajapinta
- [GitHub Pages](https://pages.github.com) – staattinen hostaus

## Yksityisyys ja tietoturva

- Kaikki data on suojattu Supabasen Row Level Securitylla – kirjautunut käyttäjä näkee vain omat rivinsä
- Kirjautuminen ilman salasanaa (magic link sähköpostiin)
- Repo voi olla julkinen ilman tietoturvariskiä, koska mitään henkilökohtaista dataa ei säilytetä koodissa – ainoastaan tietokannassa, joka on erikseen suojattu

## Muokattavuus

Sovellus on tarkoituksella yksinkertainen lähtökohta. Helposti laajennettavia kohtia:
- Uudet seurattavat mittarit: lisää sarake vastaavaan tauluun `schema.sql`:ssä + kenttä lomakkeeseen
- Ulkoasu: värit ja fontit on määritelty tiedoston alun CSS-muuttujissa (`:root`)
- Kielitäys: kaikki tekstit ovat suomeksi suoraan HTML:ssä/JS:ssä, käännettävissä suoraan

## Lisenssi

MIT – käytä, muokkaa ja jaa vapaasti.
