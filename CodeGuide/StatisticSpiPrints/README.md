# Stampa Statistiche SPI — come funziona e come è stata pensata

*(English version below / versione in inglese più sotto)*

---

## Parte 1 — Italiano

### Scopo

`app/services/statistic_spi_prints/` genera la **Stampa Statistiche SPI**: la controparte stampabile della pagina Statistiche SPI descritta in `CodeGuide/StatisticSpi/README.md`, ed è il gemello SPI di `CodeGuide/StatisticPrints/README.md` — vale la pena leggere entrambi prima di questo documento, perché qui ci si concentra su **cosa cambia** rispetto alla versione Attivi, non lo si ripete da zero.

### La struttura del fascicolo: quasi identica alla versione Attivi

`StatisticSpiPrints::ReportPdf` ricalca `StatisticPrints::ReportPdf` riga per riga nella struttura: copertina full-bleed → legenda opzionale → per l'azzonamento scelto, pagina divisoria + set di pagine di contenuto, ripetuto per comprensorio se regionale → controcopertina con padding per la stampa fronte/retro. Le differenze concrete:

- **Nessun `comparison_service:` iniettabile.** `StatisticPrints::ReportPdf` accetta un `comparison_service:` (default `Statistics::TotalMembersComparison`) per testabilità; `StatisticSpiPrints::ReportPdf` non ha questo parametro — ogni pagina di contenuto chiama direttamente `StatisticSpi::*` con il proprio default. Divergenza deliberata, non una svista.
- **`draw_legend` controlla `@form.legend_spi`**, non `@form.legend` — un modello separato (`LegendSpi`), non un campo condiviso.
- **`CONTENT_PAGES` è una lista di classi completamente diversa**: `TotalsPage, MultipleDelegationsPage, TipologieDelegaPage, CessazioniPage, ProvvisoriePage, AgeClassesPage` — una per ciascun servizio `StatisticSpi::*Breakdown` documentato in `CodeGuide/StatisticSpi/`.

### Il pattern più comune: riuso di asset, non di codice

Diverse pagine "di cornice" (copertina, controcopertina, pagina divisoria) riusano gli **stessi file** in `app/assets/images/statistic_prints/`, distinti solo da un suffisso `_spi` nel nome (`cover_background_spi.png`, `backcover_background_spi.png`, `logo-cgil-spi.png`) — non esiste un albero di asset parallelo. `ZoningDividerPage` è quasi byte-identica alla sua gemella Attivi, a parte la costante del logo e una stringa nel footer ("Sindacato Pensionati Italiani" invece della dicitura confederale). `CoverPage` ha invece una differenza strutturale reale, non solo di asset: tre box di testo frazionari separati (`ZONING_BOX`, `MONTH_BOX`, `YEAR_BOX`) contro l'unico `PERIOD_BOX` della versione Attivi, perché la grafica di sfondo SPI riserva tre spazi bianchi, incluso quello per il nome dell'azzonamento. `LegendPage` differisce per una sola riga: chiama `StatisticPrints::LegendContent.blocks(@form.legend_spi.description)` — riusa direttamente il parser Attivi, non lo duplica, lo stesso pattern di accoppiamento cross-cartella già visto per `BANDS`/`AGE_EXPR` in `StatisticSpi::AgeBreakdown`.

### La differenza di fondo: iscritti vs deleghe, di nuovo

Come per la pagina a schermo (`CodeGuide/StatisticSpi/README.md`), ogni pagina di contenuto deve sapere se sta disegnando **deleghe** (record additivi, nessuna riconciliazione — `TipologieDelegaPage`, `CessazioniPage`, `ProvvisoriePage`) o **iscritti/persone** (richiede la riconciliazione `DISTINCT ON` — `AgeClassesPage`, e la metà "iscritti" di `TotalsPage`). Questa distinzione, già completamente spiegata lato servizio, si riflette qui solo nella forma dei dati che arrivano alla pagina — nessuna pagina PDF fa riconciliazione propria, la ereditano dal `Result` del servizio SPI corrispondente.

### Tre grafici a barre, nessuna gerarchia tra loro

A differenza della cartella Attivi (`BarChart`/`SingleSeriesBarChart`, due forme), qui esistono **tre** grafici a barre indipendenti, ciascuno con un solo chiamante:

- `BarChart` — 4 serie (Iscritti/Deleghe × anno precedente/corrente), raggruppate per comprensorio. Usato solo da `TotalsPage`.
- `CategoryBarChart` — serie singola, 5 colori di categoria fissi. Usato solo da `TipologieDelegaPage`, per la riga "totale" regionale.
- `GroupedCategoryBarChart` — N serie di categoria raggruppate per comprensorio. Usato solo da `TipologieDelegaPage`, per il grafico dei comprensori — importa `COLORS` da `CategoryBarChart` così che i due grafici sulla stessa pagina concordino sui colori di categoria.

Nessuno dei tre chiama `StatisticPrints::BarChart`/`SingleSeriesBarChart`: sono reimplementazioni indipendenti perché `SingleSeriesBarChart#value_label` è conteggio-oppure-percentuale, mai entrambi insieme, mentre `CategoryBarChart` ha bisogno di entrambi contemporaneamente (altezza barra = valore, etichetta = percentuale).

Le tabelle seguono invece un asse diverso: `CategoryTable`/`CategoryPercentageTable` sono genuinamente generiche (guidate da una lista `etichette:` esterna), mentre `MultipleDelegationsTable`/`ProvvisorieTable` sono cablate sui campi nominati dei rispettivi Struct (`doppia`/`tripla`/... o `totale`/`percentuale`) — una vera differenza di forma-dato, non una scelta di stile. `MotivoCessazionePercentageTable` non è una forma-dato specifica di `CessazioniBreakdown` — è `CategoryPercentageTable` **trasposta** per leggibilità: `CessazioniBreakdown::Row` ha esattamente i campi che `CategoryPercentageTable` si aspetta, ma sei etichette come sei colonne strette per una singola riga si leggono male, quindi `CessazioniPage` usa la versione trasposta solo per `result.totale` e torna a `CategoryPercentageTable` (colonne) per `result.comprensori`.

### Riuso cross-modulo confermato

`TotalsPage` chiama `StatisticPrints::ComparisonTable`; `CessazioniPage`/`ProvvisoriePage` chiamano entrambe `StatisticPrints::PieChart` direttamente (una torta a 2-3 fette non ha bisogno di nessuna delle differenze a doppia serie che giustificano i grafici a barre SPI dedicati); `AgeClassesPage` chiama `StatisticPrints::SingleSeriesBarChart`. Tutte le classi grafico/tabella di questa cartella instradano la formattazione numerica attraverso `StatisticPrints::NumberFormatting`, mai una propria.

### Il bug storico di `AgeClassesPage`: 4 pagine bianche

`AgeClassesPage` è la pagina più complessa della cartella, e l'unica il cui codice attuale porta la traccia diretta di un incidente reale già accaduto in produzione. Una prima versione disegnava la sezione regionale (grafico grande) dentro un `bounding_box([left, top], height: top)` — lo stesso pattern usato con successo per colonne affiancate in `TotalsPage`/`TipologieDelegaPage`/`CessazioniPage`/`ProvvisoriePage` — e poi impilava sotto un secondo `bounding_box` analogo per la riga dei comprensori. Il problema: Prawn fa sempre atterrare il cursore condiviso del documento a `top - height` alla chiusura di un `bounding_box`, **indipendentemente da quanto contenuto sia stato davvero disegnato dentro**. Con `height: top` (tutto lo spazio rimasto in pagina), il cursore dopo il primo box atterra vicino a zero; il secondo box, che ne ereditava la posizione, andava quindi in overflow, e l'auto-impaginazione di Prawn generava silenziosamente pagine bianche extra — quattro, in coda a ogni sezione di comprensorio nel PDF reale. I test RSpec esistenti (`expect { ... }.not_to raise_error`) non l'avevano intercettato, perché un `bounding_box` in overflow non solleva eccezioni: produce solo un PDF più lungo del previsto, un difetto invisibile finché qualcuno non ha aperto il PDF e contato le pagine.

La correzione, visibile nel codice attuale: **niente `bounding_box`** per le due sezioni impilate verticalmente. `top` viene calcolato a mano, sottraendo altezze note in anticipo (`title_block_height`, altezza grafico, gap), e ogni elemento è posizionato con coordinate assolute (`draw_text at:`, grafico `at:`). Vedi `CodeGuide/StatisticSpiPrints/age_classes_page.md` per il dettaglio riga per riga — è la storia più ricca di tutta questa cartella su "perché" il codice è scritto così.

### Tre strategie diverse per il layout a colonne/sezioni

- `TotalsPage`/`TipologieDelegaPage`/`CessazioniPage`/`ProvvisoriePage`: colonne affiancate, `bounding_box` per colonna — sicuro, perché nessuna sezione successiva dipende dal cursore condiviso dopo la chiusura.
- `MultipleDelegationsPage`: nessun `bounding_box` — impilamento verticale semplice, niente confronto anno su anno, niente grafico da allineare.
- `AgeClassesPage`: coordinate assolute tracciate a mano — l'unico caso con sezioni impilate verticalmente che avevano davvero bisogno di un'altezza dinamica, da cui il bug storico sopra.

Un'ultima nota di processo, non tecnica: il grafico a torta di `CessazioniPage` non era nel mockup originale, è stato aggiunto in un secondo momento su richiesta esplicita — un'istanza documentata delle aggiunte iterative che caratterizzano questo progetto (vedi anche `feedback_fitupe_iterative_visual_tweaks` in memoria).

### Decisioni che *non* sono ovvie dal codice

- **Nessun `comparison_service:` iniettabile in `ReportPdf`**: divergenza deliberata dalla versione Attivi, non un'omissione.
- **Le pagine di cornice (copertina/controcopertina/divisoria) riusano gli asset Attivi con un suffisso `_spi`**: non esiste un albero immagini separato per SPI.
- **`LegendPage` SPI riusa il parser `StatisticPrints::LegendContent` invece di duplicarlo**: un solo punto di manutenzione per il parsing Trix, condiviso tra le due cartelle.
- **I tre grafici a barre SPI (`BarChart`/`CategoryBarChart`/`GroupedCategoryBarChart`) sono reimplementazioni indipendenti**, non varianti l'una dell'altra — la causa tecnica è che nessuna combinazione dei parametri di `StatisticPrints::SingleSeriesBarChart` copre "valore come altezza barra e percentuale come etichetta contemporaneamente".
- **`MotivoCessazionePercentageTable` è `CategoryPercentageTable` trasposta**, non una classe con logica propria — l'esistenza di una classe dedicata è giustificata solo dalla leggibilità di sei colonne strette per una singola riga, non da una differenza nei dati.
- **Il bug storico di `AgeClassesPage`** (vedi sopra) è la ragione diretta per cui questa pagina, sola tra tutte, non usa `bounding_box`.

### Dove continuare

Una nuova pagina di contenuto per una sezione SPI già esistente segue lo schema Attivi (servizio → intestazione → tabella → grafico), ma con due controlli aggiuntivi da fare ogni volta: (1) la sezione conta deleghe (nessuna riconciliazione) o persone (serve la CTE `DISTINCT ON`, ereditata dal `Result` del servizio, non da ricostruire nella pagina)? (2) se la pagina impila più sezioni **verticalmente** (non affiancate), va usato il pattern a coordinate assolute di `AgeClassesPage`, mai un `bounding_box` con `height:` grande.

---

## Part 2 — English

### Purpose

`app/services/statistic_spi_prints/` generates **Stampa Statistiche SPI**: the printable counterpart of the SPI Statistics page described in `CodeGuide/StatisticSpi/README.md`, and the SPI twin of `CodeGuide/StatisticPrints/README.md` — worth reading both before this document, since here the focus is on **what differs** from the Attivi version, not repeating it from scratch.

### The booklet structure: nearly identical to the Attivi version

`StatisticSpiPrints::ReportPdf` mirrors `StatisticPrints::ReportPdf` line for line in structure: full-bleed cover → optional legend → for the chosen zoning, a divider page + full set of content pages, repeated per comprensorio when regional → back cover padded for duplex printing. The concrete differences:

- **No injectable `comparison_service:`.** `StatisticPrints::ReportPdf` accepts a `comparison_service:` (defaulting to `Statistics::TotalMembersComparison`) for testability; `StatisticSpiPrints::ReportPdf` has no such parameter — every content page calls `StatisticSpi::*` directly with its own default. A deliberate divergence, not an oversight.
- **`draw_legend` checks `@form.legend_spi`**, not `@form.legend` — a separate model (`LegendSpi`), not a shared field.
- **`CONTENT_PAGES` is a completely different class list**: `TotalsPage, MultipleDelegationsPage, TipologieDelegaPage, CessazioniPage, ProvvisoriePage, AgeClassesPage` — one per `StatisticSpi::*Breakdown` service, already documented in `CodeGuide/StatisticSpi/`.

### The most common pattern: asset reuse, not code reuse

Several "frame" pages (cover, back cover, divider) reuse the **same files** under `app/assets/images/statistic_prints/`, distinguished only by an `_spi` filename suffix (`cover_background_spi.png`, `backcover_background_spi.png`, `logo-cgil-spi.png`) — there's no parallel asset tree. `ZoningDividerPage` is nearly byte-identical to its Attivi twin, aside from the logo constant and one footer string ("Sindacato Pensionati Italiani" instead of the confederal wording). `CoverPage`, by contrast, has a real structural difference, not just an asset swap: three separate fractional text boxes (`ZONING_BOX`, `MONTH_BOX`, `YEAR_BOX`) instead of the Attivi version's single `PERIOD_BOX`, because the SPI background art reserves three blank spots, including one for the zoning name. `LegendPage` differs by exactly one line: it calls `StatisticPrints::LegendContent.blocks(@form.legend_spi.description)` — reusing the Attivi parser directly rather than duplicating it, the same cross-folder coupling pattern already seen for `BANDS`/`AGE_EXPR` in `StatisticSpi::AgeBreakdown`.

### The core difference, again: delegations vs members

As on the screen side (`CodeGuide/StatisticSpi/README.md`), every content page needs to know whether it's drawing **delegations** (additive records, no reconciliation — `TipologieDelegaPage`, `CessazioniPage`, `ProvvisoriePage`) or **members/people** (needs the `DISTINCT ON` reconciliation — `AgeClassesPage`, and the "iscritti" half of `TotalsPage`). This distinction, already fully explained on the service side, shows up here only in the shape of the data arriving at the page — no PDF page does its own reconciliation, it inherits it from the matching SPI service's `Result`.

### Three bar charts, no hierarchy between them

Unlike the Attivi folder (`BarChart`/`SingleSeriesBarChart`, two shapes), this folder has **three** independent bar-chart classes, each with exactly one caller:

- `BarChart` — 4 series (Iscritti/Deleghe × previous/current year), grouped by comprensorio. Used only by `TotalsPage`.
- `CategoryBarChart` — single series, 5 fixed category colors. Used only by `TipologieDelegaPage`, for the regional "total" row.
- `GroupedCategoryBarChart` — N category series grouped by comprensorio. Used only by `TipologieDelegaPage`, for the comprensori chart — it imports `COLORS` from `CategoryBarChart` so both charts on the same page agree on category colors.

None of the three calls `StatisticPrints::BarChart`/`SingleSeriesBarChart`: they're independent reimplementations because `SingleSeriesBarChart#value_label` is either count-or-percentage, never both at once, while `CategoryBarChart` needs both simultaneously (bar height = value, label = percentage).

Tables follow a different axis instead: `CategoryTable`/`CategoryPercentageTable` are genuinely generic (driven by an external `etichette:` list), while `MultipleDelegationsTable`/`ProvvisorieTable` are hardcoded to their struct's named fields (`doppia`/`tripla`/... or `totale`/`percentuale`) — a real data-shape difference, not a style choice. `MotivoCessazionePercentageTable` isn't a `CessazioniBreakdown`-specific data shape — it's `CategoryPercentageTable` **transposed** for readability: `CessazioniBreakdown::Row` has exactly the fields `CategoryPercentageTable` expects, but six labels as six narrow columns for a single row reads badly, so `CessazioniPage` uses the transposed version only for `result.totale` and falls back to `CategoryPercentageTable` (columns) for `result.comprensori`.

### Confirmed cross-module reuse

`TotalsPage` calls `StatisticPrints::ComparisonTable`; `CessazioniPage`/`ProvvisoriePage` both call `StatisticPrints::PieChart` directly (a 2-3-slice pie needs none of the dual-series differences that justify the dedicated SPI bar charts); `AgeClassesPage` calls `StatisticPrints::SingleSeriesBarChart`. Every chart/table class in this folder routes number formatting through `StatisticPrints::NumberFormatting`, never its own.

### The `AgeClassesPage` historical bug: 4 blank pages

`AgeClassesPage` is the most complex page in the folder, and the only one whose current code carries a direct trace of a real production incident. An earlier version drew the regional section (the large chart) inside a `bounding_box([left, top], height: top)` — the same pattern used successfully for side-by-side columns in `TotalsPage`/`TipologieDelegaPage`/`CessazioniPage`/`ProvvisoriePage` — and then stacked a second, analogous `bounding_box` below it for the comprensori row. The problem: Prawn always lands the document's shared cursor at `top - height` when a `bounding_box` closes, **regardless of how much content was actually drawn inside it**. With `height: top` (all the remaining page space), the cursor after the first box lands near zero; the second box, which inherited that position, then overflowed, and Prawn's auto-pagination silently generated extra blank pages — four, tacked onto the end of every comprensorio section in the real PDF. The existing RSpec tests (`expect { ... }.not_to raise_error`) hadn't caught it, because an overflowing `bounding_box` doesn't raise — it just produces a longer-than-expected PDF, a defect invisible until someone opened the PDF and counted pages.

The fix, visible in the current code: **no `bounding_box`** for the two vertically stacked sections. `top` is computed by hand, subtracting known-in-advance heights (`title_block_height`, chart height, gap), and every element is positioned with absolute coordinates (`draw_text at:`, chart `at:`). See `CodeGuide/StatisticSpiPrints/age_classes_page.md` for the line-by-line detail — it's the richest "why" story in this entire folder.

### Three different strategies for column/section layout

- `TotalsPage`/`TipologieDelegaPage`/`CessazioniPage`/`ProvvisoriePage`: side-by-side columns, one `bounding_box` per column — safe, because no later section depends on the shared cursor after closing.
- `MultipleDelegationsPage`: no `bounding_box` at all — simple vertical stacking, no year-over-year comparison, no chart to align.
- `AgeClassesPage`: hand-tracked absolute coordinates — the one case with vertically stacked sections that genuinely needed a dynamic height, hence the historical bug above.

One last, non-technical note: `CessazioniPage`'s pie chart wasn't in the original mockup — it was added later at explicit request, a documented instance of the iterative additions that characterize this project (see also `feedback_fitupe_iterative_visual_tweaks` in memory).

### Decisions that are *not* obvious from the code

- **No injectable `comparison_service:` in `ReportPdf`**: a deliberate divergence from the Attivi version, not an omission.
- **Frame pages (cover/back cover/divider) reuse the Attivi assets with an `_spi` suffix**: there's no separate SPI image tree.
- **The SPI `LegendPage` reuses `StatisticPrints::LegendContent` instead of duplicating it**: a single maintenance point for Trix parsing, shared across both folders.
- **The three SPI bar charts (`BarChart`/`CategoryBarChart`/`GroupedCategoryBarChart`) are independent reimplementations**, not variants of one another — the technical cause is that no combination of `StatisticPrints::SingleSeriesBarChart`'s parameters covers "value as bar height and percentage as label at the same time".
- **`MotivoCessazionePercentageTable` is `CategoryPercentageTable` transposed**, not a class with its own logic — the dedicated class exists purely for the readability of six narrow columns on a single row, not because of a data difference.
- **The `AgeClassesPage` historical bug** (see above) is the direct reason this one page, alone among all of them, avoids `bounding_box` entirely.

### Where to continue

A new content page for an existing SPI section follows the Attivi recipe (service → heading → table → chart), but with two extra checks each time: (1) does the section count delegations (no reconciliation) or people (needs the `DISTINCT ON` CTE, inherited from the service's `Result`, never rebuilt in the page)? (2) if the page stacks multiple sections **vertically** (not side by side), use `AgeClassesPage`'s absolute-coordinate pattern, never a `bounding_box` with a large `height:`.
