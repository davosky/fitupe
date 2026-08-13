# Azzonamenti (Zoning) — la radice geografica di tutta l'applicazione

*(English version below / versione in inglese più sotto)*

---

## Parte 1 — Italiano

### Scopo

`ZoningsController` + il modello `Zoning` gestiscono il CRUD degli **azzonamenti**: le unità geografiche (regioni e comprensori) attorno a cui ruota ogni altro dato di Fitupe. Come `IntegrationFilleasController` (vedi `CodeGuide/IntegrationFilleas/README.md`), non esiste una cartella `app/services/` dedicata — tutta la logica sta nel controller REST standard e, soprattutto, nel modello.

### La struttura senza tabella di raccordo

A differenza di quanto ci si aspetterebbe da una gerarchia regione/comprensorio, `Zoning` non ha nessuna relazione `parent`/`children` esplicita né una foreign key ricorsiva. La gerarchia è codificata **per prefisso** dentro la colonna `codice_azzonamento`: un azzonamento regionale ha un codice a un solo carattere (es. `"G"`), un comprensorio che gli appartiene ha un codice più lungo che inizia con lo stesso carattere (es. `"GB"`). `Zoning#regionale?` legge questa convenzione (`length == 1`), lo scope `Zoning.comprensori_di` la sfrutta con una `LIKE`. Vedi `CodeGuide/Zonings/zoning.md` per il dettaglio.

### Perché questa cartella è la più "letta" di tutto il progetto

`regionale?` e `comprensori_di` sono richiamati da praticamente ogni servizio statistico e ogni pagina di stampa PDF documentati altrove in `CodeGuide/` (`Statistics/`, `StatisticSpi/`, `StatisticPrints/`, `StatisticSpiPrints/`, `StatisticWithIntegrations/`): il pattern "regionale? → aggrega e ripeti per ogni comprensorio, altrimenti mostra un solo azzonamento" è il fondamento su cui è costruita ogni statistica dell'applicazione. Chiunque tocchi il formato di `codice_azzonamento` o la logica di `regionale?`/`comprensori_di` deve essere consapevole di questo raggio d'impatto.

### Decisioni che *non* sono ovvie dal codice

- **Nessuna foreign key gerarchica**: la gerarchia regione → comprensorio è testuale (prefisso della stringa), non relazionale — una scelta leggera ma che dipende dalla disciplina di inserimento, nessun vincolo DB la protegge.
- **`dependent: :restrict_with_error` su tutte e cinque le relazioni**, mai `:destroy`/`:nullify`: un azzonamento con dati collegati non può essere eliminato, per non perdere anni di importazioni e report storici.
- **`destroy` nel controller non verifica il fallimento**: coerente con il resto del progetto, ma con impatto pratico maggiore qui perché `Zoning` è quasi sempre referenziato da qualcosa.
- **`Statistics::TotalMembersComparison`, `StatisticWithIntegrations::FilleaCorrection`/`FlcCorrection` reimplementano `regionale?` localmente** invece di delegare a `@zoning.regionale?` — stessa logica, duplicata in più punti.

---

## Part 2 — English

### Purpose

`ZoningsController` + the `Zoning` model handle the CRUD for **zonings**: the geographic units (regions and comprensori) that every other piece of Fitupe data revolves around. Like `IntegrationFilleasController` (see `CodeGuide/IntegrationFilleas/README.md`), there's no dedicated `app/services/` folder — all the logic lives in the standard REST controller and, above all, in the model.

### The structure with no join table

Unlike what you'd expect from a region/comprensorio hierarchy, `Zoning` has no explicit `parent`/`children` relationship or recursive foreign key. The hierarchy is encoded **by prefix** inside the `codice_azzonamento` column: a regional zoning has a single-character code (e.g. `"G"`), a comprensorio belonging to it has a longer code starting with that same character (e.g. `"GB"`). `Zoning#regionale?` reads this convention (`length == 1`), the `Zoning.comprensori_di` scope exploits it with a `LIKE`. See `CodeGuide/Zonings/zoning.md` for the detail.

### Why this folder is the most "read" one in the whole project

`regionale?` and `comprensori_di` are called by virtually every statistics service and every PDF print page documented elsewhere in `CodeGuide/` (`Statistics/`, `StatisticSpi/`, `StatisticPrints/`, `StatisticSpiPrints/`, `StatisticWithIntegrations/`): the "regionale? → aggregate and repeat for each comprensorio, otherwise show a single zoning" pattern is the foundation every statistic in the application is built on. Anyone touching the `codice_azzonamento` format or the `regionale?`/`comprensori_di` logic needs to be aware of this blast radius.

### Decisions that are *not* obvious from the code

- **No hierarchical foreign key**: the region → comprensorio hierarchy is textual (string prefix), not relational — a lightweight choice, but one that depends on entry discipline, with no DB constraint protecting it.
- **`dependent: :restrict_with_error` on all five relationships**, never `:destroy`/`:nullify`: a zoning with attached data can't be deleted, to avoid losing years of imports and historical reports.
- **The controller's `destroy` doesn't check for failure**: consistent with the rest of the project, but with a bigger practical impact here because `Zoning` is almost always referenced by something.
- **`Statistics::TotalMembersComparison` and `StatisticWithIntegrations::FilleaCorrection`/`FlcCorrection` each reimplement `regionale?` locally** instead of delegating to `@zoning.regionale?` — the same logic, duplicated in more than one place.
