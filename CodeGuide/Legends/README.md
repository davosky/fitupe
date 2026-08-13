# Legenda (Legend) — il testo libero allegato a un report Attivi

*(English version below / versione in inglese più sotto)*

---

## Parte 1 — Italiano

### Scopo

`LegendsController` + il modello `Legend` gestiscono un CRUD manuale per la **legenda** di un report "Stampa Statistiche": un testo in rich text (ActionText/Trix) legato a un preciso azzonamento/anno/mese, che compare come pagina dedicata nel PDF quando esiste. Come `IntegrationFilleasController` e `ZoningsController`, non esiste una cartella `app/services/` dedicata — la logica sta nel controller REST e nelle validazioni del modello.

### Come si collega al report PDF

Non c'è nessuna foreign key diretta tra `Legend` e un report: il collegamento è per **coincidenza di chiave** (`zoning_id` + `year` + `month`), risolto da `TotalMembersForm#legend` con un `find_by`. `StatisticPrints::ReportPdf` disegna la pagina di legenda solo se la ricerca trova un record — una legenda è opzionale, la sua assenza non impedisce la generazione del report. Il parsing dell'HTML e il rendering Prawn sono documentati in `CodeGuide/StatisticPrints/legend_content.md` e `CodeGuide/StatisticPrints/legend_page.md`: questa cartella copre solo la parte di **inserimento dati**, non il consumo.

### Il gemello per la parte SPI

`LegendSpi`/`LegendSpisController` sono la copia quasi identica di questa coppia per il report SPI (pensionati) — vedi `CodeGuide/LegendSpis/README.md` per le poche differenze reali.

### Decisioni che *non* sono ovvie dal codice

- **Nessuna foreign key verso il report**: il legame è per chiave composta (`zoning_id`, `year`, `month`), non relazionale — mai `nil` grazie all'unicità scoped nel modello.
- **`month` riusa `ImportForm::MESI`**, una costante definita in un modello che non ha nulla a che fare con le legende — scelta deliberata per avere un'unica fonte di verità sui nomi dei mesi.
- **`description` è ActionText, non una colonna `text`**: è ciò che permette formattazione (grassetto, liste, link) che poi viene tradotta in blocchi Prawn dal parser dedicato.
- **`index` ordina cronologicamente**, non per azzonamento, a differenza delle integrazioni — riflette un uso diverso della lista.

---

## Part 2 — English

### Purpose

`LegendsController` + the `Legend` model handle a manual CRUD for the **legend** of a "Stampa Statistiche" report: a rich-text (ActionText/Trix) body tied to a specific zoning/year/month, that shows up as a dedicated page in the PDF when it exists. Like `IntegrationFilleasController` and `ZoningsController`, there's no dedicated `app/services/` folder — the logic lives in the REST controller and the model's validations.

### How it connects to the PDF report

There's no direct foreign key between `Legend` and a report: the link is by **key coincidence** (`zoning_id` + `year` + `month`), resolved by `TotalMembersForm#legend` with a `find_by`. `StatisticPrints::ReportPdf` only draws the legend page if the lookup finds a record — a legend is optional, its absence doesn't block report generation. The HTML parsing and Prawn rendering are documented in `CodeGuide/StatisticPrints/legend_content.md` and `CodeGuide/StatisticPrints/legend_page.md`: this folder only covers the **data-entry** side, not the consumption.

### The SPI twin

`LegendSpi`/`LegendSpisController` are the near-identical copy of this pair for the SPI (pensioners) report — see `CodeGuide/LegendSpis/README.md` for the few real differences.

### Decisions that are *not* obvious from the code

- **No foreign key to the report**: the link is via a composite key (`zoning_id`, `year`, `month`), not relational — never `nil` thanks to the model's scoped uniqueness.
- **`month` reuses `ImportForm::MESI`**, a constant defined on a model that has nothing to do with legends — a deliberate choice to have a single source of truth for month names.
- **`description` is ActionText, not a `text` column**: it's what allows formatting (bold, lists, links) that's later translated into Prawn blocks by a dedicated parser.
- **`index` orders chronologically**, not by zoning, unlike the integrations — it reflects a different way the list gets used.
