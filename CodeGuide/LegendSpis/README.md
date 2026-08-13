# Legenda SPI (LegendSpi) — il gemello di Legend per il report pensionati

*(English version below / versione in inglese più sotto)*

---

## Parte 1 — Italiano

### Scopo

`LegendSpisController` + il modello `LegendSpi` sono la copia quasi identica di `LegendsController`/`Legend` (vedi `CodeGuide/Legends/README.md`), applicata al report "Stampa Statistiche SPI" invece che al report Attivi. Stessa struttura, stessa dipendenza da `ImportForm::MESI`, stesso vincolo di unicità sulla tripla `(zoning_id, year, month)`.

### Le uniche differenze reali rispetto a `Legend`/`LegendsController`

- Testi dei messaggi flash e di validazione: "Legenda SPI" invece di "Legenda".
- Icone SVG dedicate (`legend/legendaspi-logo.svg`, `legend/legendaspi-logo-show.svg`), ma nella **stessa** cartella `app/assets/images/legend/` delle icone di `Legend`.
- Route e policy separate (`resources :legend_spis`, `LegendSpiPolicy`), identiche riga per riga alle controparti Attivi.
- Risolto lato form da `TotalMembersForm#legend_spi` invece di `TotalMembersForm#legend` — lo stesso oggetto form espone entrambi i lookup.

### Perché non un'unica implementazione condivisa

Come per ogni altra coppia Attivi/SPI del progetto (`Import`/`ImportSpi`, `Statistics`/`StatisticSpi`), niente discriminatore polimorfico: due tabelle, due modelli, due controller completamente indipendenti. Vedi `CodeGuide/LegendSpis/legend_spi.md` per il ragionamento completo.

---

## Part 2 — English

### Purpose

`LegendSpisController` + the `LegendSpi` model are the near-identical copy of `LegendsController`/`Legend` (see `CodeGuide/Legends/README.md`), applied to the "Stampa Statistiche SPI" report instead of the Attivi one. Same structure, same dependency on `ImportForm::MESI`, same uniqueness constraint on the `(zoning_id, year, month)` triple.

### The only real differences from `Legend`/`LegendsController`

- Flash and validation message text: "Legenda SPI" instead of "Legenda".
- Dedicated SVG icons (`legend/legendaspi-logo.svg`, `legend/legendaspi-logo-show.svg`), but in the **same** `app/assets/images/legend/` folder as `Legend`'s icons.
- Separate routes and policy (`resources :legend_spis`, `LegendSpiPolicy`), identical line for line to the Attivi counterparts.
- Resolved on the form side by `TotalMembersForm#legend_spi` instead of `TotalMembersForm#legend` — the same form object exposes both lookups.

### Why not a single shared implementation

Like every other Attivi/SPI pair in the project (`Import`/`ImportSpi`, `Statistics`/`StatisticSpi`), no polymorphic discriminator: two tables, two models, two fully independent controllers. See `CodeGuide/LegendSpis/legend_spi.md` for the full reasoning.
