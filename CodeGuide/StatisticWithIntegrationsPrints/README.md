# Stampa Statistiche Con Integrazioni — come funziona e come è stata pensata

*(English version below / versione in inglese più sotto)*

---

## Parte 1 — Italiano

### Scopo

`StatisticWithIntegrationsPrintsController` genera la controparte stampabile della dashboard **Statistiche Con Integrazioni** (`CodeGuide/StatisticWithIntegrations/README.md`) — lo stesso PDF A4 orizzontale di `CodeGuide/StatisticPrints/README.md`, ma con i conteggi ricalibrati da Cassa Edile/Anagrafe FLC invece dei dati SinCGIL grezzi.

### Non esiste un generatore PDF dedicato

A differenza di ogni altra area del progetto documentata finora, questa "feature" non ha una propria cartella in `app/services/`. Il controller chiama lo stesso identico `StatisticPrints::ReportPdf` usato da `StatisticPrintsController`, cambiando **un solo argomento**: `comparison_service: StatisticWithIntegrations::TotalMembersComparison` invece del default `Statistics::TotalMembersComparison`. È la dimostrazione pratica di perché quel parametro esiste come punto di dependency injection — vedi `CodeGuide/StatisticWithIntegrationsPrints/statistic_with_integrations_prints_controller.md` per il confronto riga per riga con il controller gemello senza integrazioni.

### Decisioni che *non* sono ovvie dal codice

- **Nessuna classe `StatisticPrintsWithIntegrations::*` esiste, né dovrebbe mai esisterne una** per questa sola differenza di parametro — crearne una sarebbe una duplicazione, non un'astrazione.
- **Nessun equivalente SPI**: le integrazioni FILLEA/FLC riguardano solo gli Attivi, quindi non esiste (deliberatamente) una `StatisticSpiWithIntegrationsPrintsController`.

---

## Part 2 — English

### Purpose

`StatisticWithIntegrationsPrintsController` generates the printable counterpart of the **Statistiche Con Integrazioni** dashboard (`CodeGuide/StatisticWithIntegrations/README.md`) — the same landscape A4 PDF as `CodeGuide/StatisticPrints/README.md`, but with counts recalibrated by Cassa Edile/Anagrafe FLC instead of raw SinCGIL data.

### There is no dedicated PDF generator

Unlike every other area of the project documented so far, this "feature" has no folder of its own under `app/services/`. The controller calls the exact same `StatisticPrints::ReportPdf` used by `StatisticPrintsController`, changing **a single argument**: `comparison_service: StatisticWithIntegrations::TotalMembersComparison` instead of the default `Statistics::TotalMembersComparison`. It's the practical demonstration of why that parameter exists as a dependency-injection point — see `CodeGuide/StatisticWithIntegrationsPrints/statistic_with_integrations_prints_controller.md` for the line-by-line comparison against the sibling controller with no integrations.

### Decisions that are *not* obvious from the code

- **No `StatisticPrintsWithIntegrations::*` class exists, nor should one ever be created** for this one parameter difference — creating one would be duplication, not abstraction.
- **No SPI equivalent**: the FILLEA/FLC integrations only concern Attivi, so a `StatisticSpiWithIntegrationsPrintsController` deliberately doesn't exist.
