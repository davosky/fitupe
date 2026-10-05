# Stampa Statistiche — come funziona e come è stata pensata

*(English version below / versione in inglese più sotto)*

---

## Parte 1 — Italiano

### Scopo

`app/services/statistic_prints/` genera la **Stampa Statistiche**: la controparte stampabile della pagina Statistiche descritta in `CodeGuide/Statistics/README.md`. Non è un cruscotto interattivo — è un PDF A4 orizzontale generato con [Prawn](https://prawnpdf.org/), pensato per la stampa fisica fronte/retro, con la stessa struttura dati (`Statistics::TotalMembersComparison` e i suoi `*Breakdown`) resa come pagine statiche invece che come Chart.js.

Vale la pena leggere prima `CodeGuide/Statistics/README.md`: ogni pagina di questa cartella corrisponde 1:1 a una sezione già documentata lì, e ne riusa il servizio dati senza modificarlo.

### La struttura del fascicolo

`StatisticPrints::ReportPdf` è l'orchestratore, l'unico punto che il controller chiama. Compone il PDF in questo ordine:

1. **Copertina** (`CoverPage`, full-bleed, via `pdf.canvas`) — l'unica pagina con `fill_color` bianco.
2. **Legenda** (`LegendPage`, opzionale — solo se `form.legend` è presente).
3. Per l'azzonamento scelto: una **pagina divisoria** (`ZoningDividerPage`) seguita dal set completo di **pagine di contenuto** (`CONTENT_PAGES`: `RegionalPage, CategoriesPage, EmploymentStatusPage, MembershipTypesPage, ProvisionalRevocationsPage, NationalityGenderPage, WorkStatusAgePage, CategoryGenderNationalityPage`).
4. Se l'azzonamento scelto è regionale, l'intera sezione del punto 3 si **ripete una volta per ciascun comprensorio** (`Zoning.comprensori_di`).
5. **Controcopertina** (`BackCoverPage`, full-bleed), con una pagina bianca inserita prima se il numero di pagine fin lì è dispari — così il fascicolo interno ha sempre un numero di pagine pari, pronto per la stampa fronte/retro.

`ReportPdf` accetta un `comparison_service:` iniettabile (default `Statistics::TotalMembersComparison`), passato a ogni pagina di contenuto — una scelta di testabilità, non solo stile: è l'unico punto di dependency injection in tutta la cartella, e non ha un equivalente nella cartella SPI (vedi `CodeGuide/StatisticSpiPrints/README.md`).

### Il problema di fondo di Prawn: il cursore condiviso, non un DOM

A differenza di Chart.js/CSS sullo schermo, Prawn non ha un DOM: ogni pagina disegna con coordinate e uno **stato globale mutabile condiviso** (`fill_color`, `@pdf.cursor`, `@pdf.bounds`). Praticamente ogni decisione non ovvia in questa cartella nasce da qui:

- **`fill_color` è stato del documento, non del blocco.** `CoverPage` è l'unica pagina che imposta testo bianco (sul suo sfondo full-bleed); ogni pagina successiva deve resettare esplicitamente `pdf.fill_color "000000"` all'inizio di `draw`, altrimenti eredita silenziosamente il bianco — `ZoningDividerPage` è la più difensiva, ripetendo il reset prima di ogni singola `text_box`.
- **`pdf.bounding_box(point, width:)` senza `height:` esplicita è "elastico"**: la sua altezza (e quindi `cursor`/`bounds.bottom`) è calcolata dal vivo in base a dove si trova il cursore in quel momento, non ancorata al fondo pagina. Leggere `@pdf.cursor` dentro un box del genere subito dopo aver disegnato qualcosa può restituire ~0 silenziosamente.
- **Un `bounding_box` con `height:` grande ("resto della pagina")** — necessario per non far traboccare tabelle dal numero di righe variabile — ha però un effetto collaterale opposto se usato per **sezioni impilate verticalmente** invece che per colonne affiancate: alla chiusura, Prawn fa sempre atterrare il cursore condiviso a `top - height`, indipendentemente da quanto contenuto sia stato davvero disegnato. Le pagine a due colonne (`NationalityGenderPage`, `WorkStatusAgePage`) sfruttano questo pattern in sicurezza catturando il cursore **dentro** il blocco (una variabile locale, non `@pdf.cursor` dopo la chiusura) prima di calcolare l'altezza condivisa del grafico sottostante come minimo tra le due colonne.
- **`ZoningDividerPage` evita il problema alla radice**: il suo contenuto va centrato esattamente a metà pagina, quindi usa coordinate assolute calcolate a mano fin dall'inizio, senza mai passare da un `bounding_box`/cursore.

### La "recipe" delle pagine di contenuto

Ogni pagina di contenuto (eccetto `RegionalPage`, la prima e più semplice) segue lo stesso schema: chiama il proprio servizio `Statistics::*Breakdown` (o `TotalMembersComparison` per `RegionalPage`), disegna un'intestazione, poi una tabella (`ComparisonTable`/`PercentageTable`/`SingleYearTable`, a seconda che la sezione sia un confronto anno su anno o una distribuzione a un solo anno) e un grafico (`BarChart`/`SingleSeriesBarChart`/`PieChart`). Le pagine a due sezioni indipendenti sullo stesso foglio (`NationalityGenderPage`, `WorkStatusAgePage`) affiancano due colonne con lo stesso meccanismo del `bounding_box` descritto sopra.

Un caso particolare: `Statistics::EmploymentStatusBreakdown` è l'unica sezione con una forma "ibrida" (righe con sia `diff_percent` di un confronto anno su anno sia `percentuale` di una distribuzione) — `EmploymentStatusPage` è quindi l'unica pagina che disegna sia un grafico di confronto sia una tabella percentuale dagli stessi dati. `ProvisionalRevocationsPage` sembra strutturalmente identica (grafico + tabella percentuale affiancati) ma è concettualmente solo a un anno, e infatti usa `SingleSeriesBarChart`/`SingleYearTable`, non gli equivalenti di confronto.

### I componenti riusabili: chart e tabelle

Tre classi tabella, distinte da un solo asse ciascuna: `ComparisonTable` (storico anno su anno, con diff), `PercentageTable` (istantanea a un anno, senza conteggio ridondante — sempre abbinata a un grafico che il conteggio lo mostra già), `SingleYearTable` (istantanea a un anno, con conteggio). Due famiglie di grafici: `BarChart`/`SingleSeriesBarChart` rispecchiano la distinzione Stimulus `comparison-chart`/`bar-chart` già documentata in `CodeGuide/Statistics/README.md`; `PieChart` copre le distribuzioni a 2-3 categorie.

I colori dei grafici sono valori esadecimali hardcoded (Prawn non ha CSS), copiati dai valori **compilati** delle variabili Bootswatch Lumen (`app/assets/builds/application.css`), non dagli SCSS sorgenti di Bootstrap.

### Riuso cross-modulo con `StatisticSpiPrints`

Diverse classi di questa cartella sono chiamate direttamente dalla cartella SPI gemella (`app/services/statistic_spi_prints/`), non reimplementate: `ComparisonTable`, `PieChart`, `SingleSeriesBarChart`, `NumberFormatting`. Alcuni parametri esistono proprio per rendere possibile questo riuso senza forkare le classi — `metric_label:`, `colors:`, `label_formatter:`, `percentages:`. `BarChart` **non** è riusato: la cartella SPI ha un proprio `BarChart` a 4 serie (Iscritti/Deleghe × anno precedente/corrente), una forma dati diversa dal 2-serie di questa cartella. `SingleYearTable` non ha invece nessun equivalente SPI, perché ogni sezione SPI è o un confronto anno su anno o ha una forma tabellare su misura.

### Decisioni che *non* sono ovvie dal codice

- **`fill_color` è document-wide**: ogni pagina che assume testo nero deve resettarlo esplicitamente all'inizio — non è garantito dal framework, è una convenzione difensiva ripetuta manualmente in ogni file.
- **Il `comparison_service:` iniettabile di `ReportPdf`** è per testabilità, e la sua assenza nella cartella SPI è una divergenza deliberata, non una svista (le pagine SPI chiamano `StatisticSpi::*` direttamente).
- **`LegendContent` è un modulo stateless separato da `LegendPage`**: il primo trasforma l'HTML Trix/ActionText in un array di blocchi (parsing), il secondo sa disegnare con Prawn (rendering) — l'unica classe della cartella che non segue il pattern `self.draw(...) = new(...).draw`. La distinzione `div`/`p` nel parsing riflette l'output DOM reale di Trix, non una scelta arbitraria.
- **I colori dei grafici sono hex copiati dal CSS compilato**, non dalle variabili SCSS sorgenti — un dettaglio che va aggiornato manualmente se il tema Bootswatch cambia.
- **Le tre tabelle (`ComparisonTable`/`PercentageTable`/`SingleYearTable`) e i due bar-chart (`BarChart`/`SingleSeriesBarChart`) esistono in coppie separate**, non come un'unica classe parametrizzata — rispecchia deliberatamente la stessa distinzione "confronto anno su anno vs distribuzione a un anno" del lato schermo, per coerenza concettuale più che per necessità tecnica.

### Dove continuare

Una nuova pagina di contenuto per una sezione Attivi già esistente sullo schermo segue lo schema: servizio esistente → intestazione → `ComparisonTable`/`PercentageTable`/`SingleYearTable` → `BarChart`/`SingleSeriesBarChart`/`PieChart`, aggiunta a `CONTENT_PAGES` in `report_pdf.rb`. Se la pagina ha due sezioni affiancate, usare il pattern `bounding_box(height: top)` con cattura del cursore **dentro** il blocco, mai `@pdf.cursor` dopo la chiusura — vedi `CodeGuide/StatisticSpiPrints/age_classes_page.md` per un esempio documentato di cosa succede quando lo stesso pattern viene applicato per errore a sezioni impilate verticalmente invece che a colonne affiancate.

---

## Part 2 — English

### Purpose

`app/services/statistic_prints/` generates **Stampa Statistiche**: the printable counterpart of the Statistics page described in `CodeGuide/Statistics/README.md`. It's not an interactive dashboard — it's a landscape A4 PDF built with [Prawn](https://prawnpdf.org/), designed for physical duplex printing, rendering the same data structures (`Statistics::TotalMembersComparison` and its `*Breakdown` services) as static pages instead of Chart.js.

Worth reading `CodeGuide/Statistics/README.md` first: every page in this folder maps 1:1 to a section already documented there, reusing its data service unchanged.

### The booklet structure

`StatisticPrints::ReportPdf` is the orchestrator, the only entry point the controller calls. It assembles the PDF in this order:

1. **Cover** (`CoverPage`, full-bleed, via `pdf.canvas`) — the only page with white `fill_color`.
2. **Legend** (`LegendPage`, optional — only when `form.legend` is present).
3. For the chosen zoning: a **divider page** (`ZoningDividerPage`) followed by the full set of **content pages** (`CONTENT_PAGES`: `RegionalPage, CategoriesPage, EmploymentStatusPage, MembershipTypesPage, ProvisionalRevocationsPage, NationalityGenderPage, WorkStatusAgePage, CategoryGenderNationalityPage`).
4. When the chosen zoning is regional, the entire section from step 3 **repeats once per comprensorio** (`Zoning.comprensori_di`).
5. **Back cover** (`BackCoverPage`, full-bleed), with a blank page inserted first if the page count so far is odd — so the inner booklet always has an even page count, ready for duplex printing.

`ReportPdf` accepts an injectable `comparison_service:` (defaulting to `Statistics::TotalMembersComparison`), passed to every content page — a testability choice, not just style: it's the only dependency-injection point in the whole folder, and it has no counterpart in the SPI folder (see `CodeGuide/StatisticSpiPrints/README.md`).

### Prawn's underlying problem: a shared cursor, not a DOM

Unlike Chart.js/CSS on screen, Prawn has no DOM: every page draws using coordinates and **shared, mutable global state** (`fill_color`, `@pdf.cursor`, `@pdf.bounds`). Nearly every non-obvious decision in this folder traces back to that fact:

- **`fill_color` is document-wide state, not block-scoped.** `CoverPage` is the only page that sets white text (over its full-bleed background); every later page must explicitly reset `pdf.fill_color "000000"` at the start of `draw`, or it silently inherits white — `ZoningDividerPage` is the most defensive, repeating the reset before every single `text_box` call.
- **`pdf.bounding_box(point, width:)` with no explicit `height:` is "stretchy"**: its height (and therefore `cursor`/`bounds.bottom`) is computed live from wherever the cursor currently sits, not anchored to the page bottom. Reading `@pdf.cursor` inside such a box right after drawing something can silently return ~0.
- **A `bounding_box` with a large ("rest of the page") `height:`** — needed so tables with a variable row count don't overflow — has the opposite side effect when used for **vertically stacked sections** instead of side-by-side columns: on close, Prawn always lands the shared cursor at `top - height`, regardless of how much content was actually drawn. The two-column pages (`NationalityGenderPage`, `WorkStatusAgePage`) use this pattern safely by capturing the cursor **inside** the block (a local variable, not `@pdf.cursor` after closing) before computing the shared chart height as the minimum of the two columns.
- **`ZoningDividerPage` avoids the problem at the root**: its content needs to sit exactly at the page's vertical midpoint, so it uses hand-computed absolute coordinates from the start, never going through a `bounding_box`/cursor at all.

### The content-page "recipe"

Every content page (except `RegionalPage`, the first and simplest) follows the same shape: call its `Statistics::*Breakdown` service (or `TotalMembersComparison` for `RegionalPage`), draw a heading, then a table (`ComparisonTable`/`PercentageTable`/`SingleYearTable`, depending on whether the section is a year-over-year comparison or a single-year distribution) and a chart (`BarChart`/`SingleSeriesBarChart`/`PieChart`). Pages with two independent sections on the same sheet (`NationalityGenderPage`, `WorkStatusAgePage`) lay out two columns using the same `bounding_box` mechanism described above.

One special case: `Statistics::EmploymentStatusBreakdown` is the only section with a "hybrid" shape (rows carrying both a year-over-year `diff_percent` and a distribution `percentuale`) — `EmploymentStatusPage` is therefore the only page drawing both a comparison chart and a percentage table from the same data. `ProvisionalRevocationsPage` looks structurally identical (chart + percentage table side by side) but is conceptually single-year-only, and correspondingly uses `SingleSeriesBarChart`/`SingleYearTable`, not the comparison equivalents.

### The reusable components: charts and tables

Three table classes, each differing along exactly one axis: `ComparisonTable` (year-over-year history, with diff), `PercentageTable` (single-year snapshot, no redundant count — always paired with a chart that already shows the count), `SingleYearTable` (single-year snapshot, with count). Two chart families: `BarChart`/`SingleSeriesBarChart` mirror the on-screen Stimulus `comparison-chart`/`bar-chart` distinction already documented in `CodeGuide/Statistics/README.md`; `PieChart` covers 2-3 category distributions.

Chart colors are hardcoded hex values (Prawn has no CSS), copied from the **compiled** Bootswatch Lumen variables (`app/assets/builds/application.css`), not from Bootstrap's SCSS source.

### Cross-module reuse with `StatisticSpiPrints`

Several classes in this folder are called directly by the sibling SPI folder (`app/services/statistic_spi_prints/`), not reimplemented: `ComparisonTable`, `PieChart`, `SingleSeriesBarChart`, `NumberFormatting`. Some keyword parameters exist specifically to make that reuse possible without forking the classes — `metric_label:`, `colors:`, `label_formatter:`, `percentages:`. `BarChart` is **not** reused: the SPI folder has its own 4-series `BarChart` (Iscritti/Deleghe × previous/current year), a different data shape from this folder's 2-series one. `SingleYearTable` has no SPI counterpart at all, because every SPI section is either a year-over-year comparison or has a bespoke table shape.

### Decisions that are *not* obvious from the code

- **`fill_color` is document-wide**: every page that assumes black text must explicitly reset it at the start — not guaranteed by the framework, a defensive convention repeated manually in every file.
- **`ReportPdf`'s injectable `comparison_service:`** exists for testability, and its absence in the SPI folder is a deliberate divergence, not an oversight (SPI pages call `StatisticSpi::*` directly).
- **`LegendContent` is a stateless module separate from `LegendPage`**: the former turns Trix/ActionText HTML into a block array (parsing), the latter knows how to draw with Prawn (rendering) — the only class in the folder that doesn't follow the `self.draw(...) = new(...).draw` pattern. The `div`/`p` distinction in parsing reflects Trix's actual DOM output, not an arbitrary choice.
- **Chart colors are hex copied from compiled CSS**, not SCSS source variables — a detail that needs manual updating if the Bootswatch theme ever changes.
- **The three table classes (`ComparisonTable`/`PercentageTable`/`SingleYearTable`) and the two bar charts (`BarChart`/`SingleSeriesBarChart`) exist as separate pairs**, not as one parameterized class — deliberately mirroring the same "year-over-year vs single-year" split from the screen side, for conceptual consistency more than technical necessity.

### Where to continue

A new content page for an existing on-screen Attivi section follows the recipe: existing service → heading → `ComparisonTable`/`PercentageTable`/`SingleYearTable` → `BarChart`/`SingleSeriesBarChart`/`PieChart`, added to `CONTENT_PAGES` in `report_pdf.rb`. If the page has two side-by-side sections, use the `bounding_box(height: top)` pattern capturing the cursor **inside** the block, never `@pdf.cursor` after closing — see `CodeGuide/StatisticSpiPrints/age_classes_page.md` for a documented example of what happens when the same pattern is mistakenly applied to vertically stacked sections instead of side-by-side columns.

- **Refactor 2026-10-05**: intestazione di pagina, messaggi, spaziature e conversione mm → punti stanno in `PageLayout`; stile di celle e intestazione delle tabelle in `TableStyle`. Entrambi i moduli sono inclusi anche dalle classi di `StatisticSpiPrints`. Vedi `page_layout.md` e `table_style.md`. / *Page heading, messages, gaps and mm → points conversion live in `PageLayout`; table cell and header style in `TableStyle`. Both modules are also included by the `StatisticSpiPrints` classes.*
