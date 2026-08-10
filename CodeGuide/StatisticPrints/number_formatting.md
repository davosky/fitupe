# `StatisticPrints::NumberFormatting`

**File:** `app/services/statistic_prints/number_formatting.rb`

## Codice completo

```ruby
module StatisticPrints
  module NumberFormatting
    extend ActionView::Helpers::NumberHelper

    def self.count(value) = number_with_delimiter(value, locale: :it)

    def self.percent(value)
      return nil if value.nil?

      number_to_percentage(value, precision: 2, locale: :it)
    end
  end
end
```

## Sezioni commentate

### Il modulo, `extend ActionView::Helpers::NumberHelper`

```ruby
module NumberFormatting
  extend ActionView::Helpers::NumberHelper
```

> **IT:** Un `Prawn::Document` non gira dentro una request Rails e non ha accesso agli helper delle view, ma `ActionView::Helpers::NumberHelper` è un modulo Ruby puro (nessuna dipendenza da `view_context`, `request` o instance variable di un controller): può essere `extend`-ato ovunque, anche in un servizio plain-Ruby chiamato da Prawn. Questo evita di reimplementare a mano la formattazione italiana dei numeri (punto come separatore delle migliaia, virgola decimale) già presente in Rails, e mantiene i numeri del PDF coerenti con quelli mostrati a schermo nella pagina Statistiche, che usa lo stesso helper nelle view ERB.
>
> *EN: A `Prawn::Document` doesn't run inside a Rails request and has no access to view helpers, but `ActionView::Helpers::NumberHelper` is a plain Ruby module (no dependency on `view_context`, `request`, or a controller's instance variables): it can be `extend`ed anywhere, even in a plain-Ruby service called from Prawn. This avoids hand-rolling Italian number formatting (dot as thousands separator, comma as decimal point) that Rails already provides, and keeps the PDF's numbers consistent with what's shown on screen in the Statistics page, which uses the same helper in its ERB views.*

### `self.count`, `self.percent`

```ruby
def self.count(value) = number_with_delimiter(value, locale: :it)

def self.percent(value)
  return nil if value.nil?

  number_to_percentage(value, precision: 2, locale: :it)
end
```

> **IT:** `locale: :it` è passato esplicitamente in entrambi i metodi invece di affidarsi a `I18n.locale` — una scelta difensiva: un job Solid Queue che genera il PDF in background potrebbe girare senza un locale di request impostato, e un report con i numeri in formato inglese (virgola per le migliaia) passerebbe inosservato fino a una lamentela dell'utente. `percent` gestisce esplicitamente `nil` restituendo `nil` (non una stringa vuota, non "0,00%"): è il valore che arriva quando una percentuale non è calcolabile (es. denominatore zero, vedi `Statistics::TotalMembersComparison` e gli altri breakdown), e ogni chiamante di questo modulo (`ComparisonTable`, `PercentageTable`, `SingleYearTable`, `BarChart`, `PieChart`) deve essere pronto a ricevere `nil` e a deciderne la resa (una cella vuota in tabella, un'etichetta senza testo nel grafico).
>
> *EN: `locale: :it` is passed explicitly in both methods instead of relying on `I18n.locale` — a defensive choice: a Solid Queue background job generating the PDF might run with no request locale set, and a report with numbers formatted in English (comma for thousands) would go unnoticed until a user complained. `percent` explicitly handles `nil` by returning `nil` (not an empty string, not "0.00%"): that's the value it receives when a percentage can't be computed (e.g. zero denominator, see `Statistics::TotalMembersComparison` and the other breakdowns), and every caller of this module (`ComparisonTable`, `PercentageTable`, `SingleYearTable`, `BarChart`, `PieChart`) must be ready to receive `nil` and decide how to render it (an empty table cell, a label with no text in the chart).*

### Riuso cross-modulo

> **IT:** `StatisticPrints::NumberFormatting` è, insieme a `ComparisonTable`, `PieChart` e `SingleSeriesBarChart`, una delle classi di questa cartella riusate direttamente da `StatisticSpiPrints` (report PDF dei pensionati) senza reimplementazione: quasi ogni tabella e grafico in `app/services/statistic_spi_prints/` (`MultipleDelegationsTable`, `ProvvisorieTable`, `CategoryTable`, `CategoryPercentageTable`, `MotivoCessazionePercentageTable`, `StatisticSpiPrints::BarChart`, `CategoryBarChart`, `GroupedCategoryBarChart`, ecc.) chiama `StatisticPrints::NumberFormatting.count`/`.percent` invece di avere una propria versione. Non esiste un modulo `StatisticSpiPrints::NumberFormatting`: la formattazione numerica non ha nulla di specifico per gli SPI, quindi non è mai stata duplicata.
>
> *EN: `StatisticPrints::NumberFormatting`, along with `ComparisonTable`, `PieChart`, and `SingleSeriesBarChart`, is one of the classes in this folder reused directly by `StatisticSpiPrints` (the pensioners' PDF report) with no reimplementation: nearly every table and chart in `app/services/statistic_spi_prints/` (`MultipleDelegationsTable`, `ProvvisorieTable`, `CategoryTable`, `CategoryPercentageTable`, `MotivoCessazionePercentageTable`, `StatisticSpiPrints::BarChart`, `CategoryBarChart`, `GroupedCategoryBarChart`, etc.) calls `StatisticPrints::NumberFormatting.count`/`.percent` instead of having its own version. There's no `StatisticSpiPrints::NumberFormatting` module: number formatting has nothing SPI-specific about it, so it was never duplicated.*
