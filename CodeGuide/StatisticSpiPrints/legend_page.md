# `StatisticSpiPrints::LegendPage`

**File:** `app/services/statistic_spi_prints/legend_page.rb`

## Codice completo

```ruby
module StatisticSpiPrints
  # Come StatisticPrints::LegendPage, ma con la legenda SPI del periodo.
  class LegendPage < StatisticPrints::LegendPage
    private

    def description = @form.legend_spi.description
  end
end
```

## Sezioni commentate

### Sottoclasse della versione Attivi

```ruby
module StatisticSpiPrints
  # Come StatisticPrints::LegendPage, ma con la legenda SPI del periodo.
  class LegendPage < StatisticPrints::LegendPage
    private

    def description = @form.legend_spi.description
  end
end
```

> **IT:** Fino al 2026-10-02 questa classe era una copia riga per riga di `StatisticPrints::LegendPage` che cambiava una sola riga dentro `draw_body`: la descrizione veniva da `@form.legend_spi` invece che da `@form.legend`. Ora è una sottoclasse che ridefinisce solo `description`; tutto il resto (intestazione "Legenda", interpretazione dei blocchi ActionText via `StatisticPrints::LegendContent`, rientri, citazioni, linee orizzontali) è ereditato e documentato in `CodeGuide/StatisticPrints/legend_page.md`. Come prima, il chiamante (`StatisticSpiPrints::ReportPdf`) disegna questa pagina solo se esiste una `LegendSpi` per il periodo; `report_pdf_spec.rb` lo copre.
>
> *EN: Until 2026-10-02 this class was a line-for-line copy of `StatisticPrints::LegendPage` differing in a single line inside `draw_body`: the description came from `@form.legend_spi` instead of `@form.legend`. It's now a subclass overriding only `description`; everything else ("Legenda" heading, ActionText block parsing via `StatisticPrints::LegendContent`, indents, quotes, horizontal rules) is inherited and documented in `CodeGuide/StatisticPrints/legend_page.md`. As before, the caller (`StatisticSpiPrints::ReportPdf`) draws this page only when a `LegendSpi` exists for the period; `report_pdf_spec.rb` covers that.*
