# Statistiche Con Integrazioni — come funziona e come è stata pensata

*(English version below / versione in inglese più sotto)*

---

## Parte 1 — Italiano

### Scopo

`app/services/statistic_with_integrations/` alimenta una seconda dashboard, **Statistiche Con Integrazioni**, che ricrea l'intera pagina Statistiche Attivi (vedi `CodeGuide/Statistics/README.md`) ma ricalibra il conteggio iscritti usando due archivi esterni: **Cassa Edile** (FILLEA, lavoratori edili) e **Anagrafe FLC** (FLC). Nessuna delle due integrazioni tocca gli iscritti SPI o le sezioni senza equivalente esterno (nazionalità, sesso, età, ecc.).

Vale la pena leggere prima `CodeGuide/Statistics/README.md`: questa cartella non duplica la logica di calcolo, la **riusa** interamente (`Statistics::TotalMembersComparison.call`) e applica una correzione sopra il risultato.

### Due meccanismi di correzione, strutturalmente simili ma concettualmente diversi

- **`FilleaCorrection`** (Cassa Edile): `IntegrationFillea` ha un valore per provincia/**anno** (`subscribers_ce`), costante per tutto l'anno. La correzione è una **differenza**: `cassa_edile - count(SinCGIL con tipologia_delega "Ordinaria Cassa Edile")` — Cassa Edile è considerata autorevole solo per quel sottoinsieme specifico di iscritti, non per l'intero totale FILLEA.
- **`FlcCorrection`** (Anagrafe FLC): `IntegrationFlc` ha un valore per provincia/anno/**mese** (`subscribers_af`). La correzione è **pura addizione** (non un confronto), e ha un **ritardo di un mese** — il dato di Maggio si applica alle statistiche di Giugno, per via del ritardo con cui l'Anagrafe FLC rende disponibili i dati.

Questa differenza non era ovvia in partenza: `FlcCorrection` è stata inizialmente implementata per analogia diretta con `FilleaCorrection` ("come per FILLEA"), e la prima versione (una differenza, non un'addizione) è stata scoperta gravemente sbagliata solo confrontando dati reali su più province — vedi la memoria di progetto `feedback_verify_integration_formula` e il dettaglio in `CodeGuide/StatisticWithIntegrations/flc_correction.md`. Non assumere mai che una nuova integrazione segua per analogia una formula già approvata: va verificata con numeri reali, non solo con i test.

### L'orchestratore: quale diff va dove

`TotalMembersComparison` chiama `Statistics::TotalMembersComparison` per i dati base, poi `FilleaCorrection`/`FlcCorrection` per l'anno corrente (bloccanti: dati mancanti fermano la pagina) e per l'anno precedente (non bloccanti: dati mancanti ricadono silenziosamente su correzione zero). Ricalibra:

- il **totale** e i **comprensori**: somma di entrambe le correzioni
- **Categorie**: solo la riga "FILLEA" riceve il diff FILLEA, solo la riga "FLC" riceve il diff FLC
- **Tipologie Delega**: stesso schema, righe "Ordinaria C.E."/"Delega Tesoro"
- **Tipologie Iscrizione**: solo la riga "Delega" riceve il diff **combinato** (entrambe le integrazioni aggiungono lavoratori per definizione a delega, mai BreviManu)
- **Attivi/Pensionati**: solo la riga "Attivi" riceve il diff combinato; la riga "Pensionati" resta invariata nel conteggio ma la sua percentuale va comunque ricalcolata contro il nuovo totale

Le altre sezioni (nazionalità, sesso, fasce età, status lavorativo, provvisorie/revoche) passano invariate da `Statistics::TotalMembersComparison`, perché non hanno un equivalente esterno né partizionano il totale.

### Il bug del 2026-08-04: perché "nessun equivalente esterno" non basta come criterio

Una versione precedente di `TotalMembersComparison` ricalibrava solo le sezioni con un equivalente diretto nell'integrazione esterna (Categorie, Tipologie Delega), lasciando **Attivi/Pensionati** e **Tipologie Iscrizione** invariate — un bug reale, individuato dall'utente confrontando dati luglio 2026 FVG (un gap di 1429 tra la somma di Categorie e la riga "Attivi", esattamente pari alla correzione combinata di quel periodo). La lezione, ora incorporata nel commento di classe di `TotalMembersComparison`: qualunque sezione le cui righe **partizionano esattamente il totale** (Attivi+Pensionati, Delega+BreviManu) deve ricevere il diff aggregato sulla riga "il resto", non solo le sezioni con un equivalente esterno diretto — altrimenti la somma delle righe smette di corrispondere al totale corretto.

### Decisioni che *non* sono ovvie dal codice

- **Nessuna card di dettaglio correzione in UI**: `Result` porta comunque `fillea_correzione`/`flc_correzione`, ma la vista non li mostra — richiesta esplicita, l'integrazione deve avvenire solo a livello di dato, non di interfaccia.
- **Politica sui dati mancanti a tre livelli**: bloccante per l'anno corrente a livello provinciale, silenziosamente ignorata per l'anno precedente, mai bloccante a livello regionale (le province senza integrazione restano semplicemente escluse, non generano errore).
- **`lookup_month`/`lookup_year` in `FlcCorrection` sfruttano l'indicizzazione negativa degli array Ruby** (`array[-1]` per il rollover Gennaio→Dicembre) per il ritardo di un mese — un dettaglio facile da scambiare per un bug se non segnalato.
- **`riga.class.new(...)` invece di riferimenti diretti alla classe `Row`**: ogni metodo di ricalibrazione costruisce nuove righe usando la classe dell'oggetto originale, non un nome hardcoded — robusto a rinominazioni delle classi `Row` interne di `Statistics::`.

---

## Part 2 — English

### Purpose

`app/services/statistic_with_integrations/` powers a second dashboard, **Statistiche Con Integrazioni**, which recreates the entire Attivi Statistics page (see `CodeGuide/Statistics/README.md`) but recalibrates the member count using two external archives: **Cassa Edile** (FILLEA, construction workers) and **Anagrafe FLC** (FLC). Neither integration touches SPI members or sections with no external equivalent (nationality, gender, age, etc.).

Worth reading `CodeGuide/Statistics/README.md` first: this folder doesn't duplicate the calculation logic, it **reuses** it entirely (`Statistics::TotalMembersComparison.call`) and applies a correction on top of the result.

### Two correction mechanisms, structurally similar but conceptually different

- **`FilleaCorrection`** (Cassa Edile): `IntegrationFillea` has one value per province/**year** (`subscribers_ce`), constant for the whole year. The correction is a **difference**: `cassa_edile - count(SinCGIL with tipologia_delega "Ordinaria Cassa Edile")` — Cassa Edile is treated as authoritative only for that specific subset of members, not the entire FILLEA total.
- **`FlcCorrection`** (Anagrafe FLC): `IntegrationFlc` has one value per province/year/**month** (`subscribers_af`). The correction is **pure addition** (not a comparison), and has a **one-month lag** — May's data applies to June's statistics, due to the delay with which Anagrafe FLC makes its data available.

This difference wasn't obvious upfront: `FlcCorrection` was initially implemented by direct analogy to `FilleaCorrection` ("just like FILLEA"), and the first version (a difference, not an addition) was discovered to be badly wrong only by comparing real data across multiple provinces — see the `feedback_verify_integration_formula` project memory and the detail in `CodeGuide/StatisticWithIntegrations/flc_correction.md`. Never assume a new integration follows an already-approved formula by analogy: it must be verified with real numbers, not just tests.

### The orchestrator: which diff goes where

`TotalMembersComparison` calls `Statistics::TotalMembersComparison` for the base data, then `FilleaCorrection`/`FlcCorrection` for the current year (blocking: missing data stops the page) and for the previous year (non-blocking: missing data silently falls back to a zero correction). It recalibrates:

- the **total** and **comprensori**: the sum of both corrections
- **Categorie**: only the "FILLEA" row gets the FILLEA diff, only the "FLC" row gets the FLC diff
- **Tipologie Delega**: the same scheme, "Ordinaria C.E."/"Delega Tesoro" rows
- **Tipologie Iscrizione**: only the "Delega" row gets the **combined** diff (both integrations add workers who are by definition delega-paid, never BreviManu)
- **Attivi/Pensionati**: only the "Attivi" row gets the combined diff; the "Pensionati" row's count stays unchanged but its percentage still gets recomputed against the new total

Every other section (nationality, gender, age bands, employment status, provisional/revoked) passes through unchanged from `Statistics::TotalMembersComparison`, because it has no external equivalent and doesn't partition the total.

### The 2026-08-04 bug: why "no external equivalent" isn't a sufficient criterion

An earlier version of `TotalMembersComparison` only recalibrated sections with a direct equivalent in the external integration (Categorie, Tipologie Delega), leaving **Attivi/Pensionati** and **Tipologie Iscrizione** unchanged — a real bug, caught by the user comparing July-2026 FVG data (a 1429 gap between Categorie's row sum and the "Attivi" row, exactly matching that period's combined correction). The lesson, now baked into `TotalMembersComparison`'s class comment: any section whose rows **exactly partition the total** (Attivi+Pensionati, Delega+BreviManu) needs the aggregate diff applied to the "the rest" row, not just sections with a direct external equivalent — otherwise the row sum stops matching the corrected total.

### Decisions that are *not* obvious from the code

- **No correction-detail card in the UI**: `Result` still carries `fillea_correzione`/`flc_correzione`, but the view doesn't show them — an explicit request, the integration must happen at the data level only, not the interface.
- **Three-tier missing-data policy**: blocking for the current year at the provincial level, silently ignored for the previous year, never blocking at the regional level (provinces without integration data are simply excluded, no error).
- **`FlcCorrection`'s `lookup_month`/`lookup_year` exploit Ruby array negative indexing** (`array[-1]` for the January→December rollover) for the one-month lag — an easy detail to mistake for a bug if not flagged.
- **`riga.class.new(...)` instead of direct references to a `Row` class**: every recalibration method builds new rows using the original object's class, not a hardcoded name — robust to renames of `Statistics::`'s internal `Row` classes.
