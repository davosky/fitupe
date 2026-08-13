# Pagine statiche (Pages) — home e crediti, l'unico controller senza modello

*(English version below / versione in inglese più sotto)*

---

## Parte 1 — Italiano

### Scopo

`PagesController` ospita le due pagine statiche dell'applicazione previste da `CLAUDE.md`: `index` (montata sulla root, `/`) mostra il logo e una brevissima spiegazione dello scopo di Fitupe; `credits` (`/credits`) spiega il nome dell'app (acronimo Fisher/Tukey/Pearson), il significato del logo, e i crediti di sviluppo. Nessun modello, nessuna cartella `app/services/`, nessuna policy Pundit — è il controller più semplice del progetto, e la sua semplicità è la decisione di design da documentare.

### Perché non ha una policy

A differenza di ogni altra risorsa di Fitupe, `PagesController` protegge le sue azioni solo con Devise (`authenticate_user!`), non con Pundit: non c'è nessun record da autorizzare per ruolo, il contenuto è identico per `admin`, `manager` e `regular`. `ApplicationController` non forza `verify_authorized` globalmente, quindi l'assenza di `authorize` qui non solleva eccezioni — è una scelta esplicita, non un'omissione.

### Decisioni che *non* sono ovvie dal codice

- **Azioni completamente vuote**: corretto, non incompleto — tutto il contenuto vive nella view, non c'è stato da caricare.
- **Nessuna Pundit policy**: deliberato, perché non esiste un ruolo che vede un contenuto diverso su queste due pagine.
- **`index` è la root dell'applicazione** (`root "pages#index"` in `config/routes.rb`), non una risorsa raggiunta da un percorso `/pages`.

---

## Part 2 — English

### Purpose

`PagesController` hosts the application's two static pages, as specified in `CLAUDE.md`: `index` (mounted at the root, `/`) shows the logo and a very short explanation of Fitupe's purpose; `credits` (`/credits`) explains the app's name (the Fisher/Tukey/Pearson acronym), the logo's meaning, and development credits. No model, no `app/services/` folder, no Pundit policy — it's the simplest controller in the project, and that simplicity is the design decision worth documenting.

### Why it has no policy

Unlike every other Fitupe resource, `PagesController` only protects its actions with Devise (`authenticate_user!`), not Pundit: there's no record to authorize by role, the content is identical for `admin`, `manager`, and `regular`. `ApplicationController` doesn't globally force `verify_authorized`, so the lack of `authorize` here doesn't raise — it's an explicit choice, not an omission.

### Decisions that are *not* obvious from the code

- **Completely empty actions**: correct, not incomplete — all the content lives in the view, there's no state to load.
- **No Pundit policy**: deliberate, because no role sees different content on these two pages.
- **`index` is the application root** (`root "pages#index"` in `config/routes.rb`), not a resource reached via a `/pages` path.
