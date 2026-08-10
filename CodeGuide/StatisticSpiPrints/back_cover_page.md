# `StatisticSpiPrints::BackCoverPage`

**File:** `app/services/statistic_spi_prints/back_cover_page.rb`

## Codice completo

```ruby
module StatisticSpiPrints
  class BackCoverPage
    BACKGROUND_IMAGE = Rails.root.join("app/assets/images/statistic_prints/backcover_background_spi.png")

    def self.draw(pdf)
      pdf.image BACKGROUND_IMAGE.to_s, at: [ 0, pdf.bounds.top ], width: pdf.bounds.width, height: pdf.bounds.height
    end
  end
end
```

## Sezioni commentate

### La classe intera

```ruby
class BackCoverPage
  BACKGROUND_IMAGE = Rails.root.join("app/assets/images/statistic_prints/backcover_background_spi.png")

  def self.draw(pdf)
    pdf.image BACKGROUND_IMAGE.to_s, at: [ 0, pdf.bounds.top ], width: pdf.bounds.width, height: pdf.bounds.height
  end
end
```

> **IT:** La pagina più semplice di tutto il pacchetto SPI, e l'unica differenza reale rispetto a `StatisticPrints::BackCoverPage` è la costante `BACKGROUND_IMAGE`, che punta a `backcover_background_spi.png` invece di `backcover_background.png` — stessa cartella condivisa `app/assets/images/statistic_prints/`, stessa convenzione di suffisso `_spi` vista in `cover_page.md`. Non c'è `self.new`/`initialize`: a differenza di ogni altra classe di questo pacchetto (tutte con pattern `def self.draw(...) = new(...).draw`), qui `self.draw` è un metodo di classe diretto perché non serve nessuno stato di istanza — un solo argomento (`pdf`), nessun `form`, nessuna logica condizionale. Come `CoverPage`, funziona correttamente solo perché il chiamante (`ReportPdf#draw_back_cover`) lo invoca sempre dentro `pdf.canvas { BackCoverPage.draw(pdf) }`, per lo stesso motivo di full-bleed: senza `canvas`, `pdf.bounds` restituirebbe l'area ristretta dal margine e l'immagine non coprirebbe l'intera pagina fisica.
>
> *EN: The simplest page in the whole SPI package, and the one real difference from `StatisticPrints::BackCoverPage` is the `BACKGROUND_IMAGE` constant, pointing to `backcover_background_spi.png` instead of `backcover_background.png` — same shared `app/assets/images/statistic_prints/` folder, same `_spi` suffix convention seen in `cover_page.md`. There's no `self.new`/`initialize`: unlike every other class in this package (all following the `def self.draw(...) = new(...).draw` pattern), `self.draw` here is a direct class method because no instance state is needed — a single argument (`pdf`), no `form`, no conditional logic. Like `CoverPage`, it only works correctly because the caller (`ReportPdf#draw_back_cover`) always invokes it inside `pdf.canvas { BackCoverPage.draw(pdf) }`, for the same full-bleed reason: without `canvas`, `pdf.bounds` would return the margin-restricted area and the image wouldn't cover the whole physical page.*

### Perché non serve resettare `fill_color` qui

> **IT:** A differenza di `CoverPage`, `ZoningDividerPage` e `LegendPage`, questa classe non chiama mai `fill_color` — non disegna testo, solo un'immagine a piena pagina. Non c'è quindi rischio di ereditare o lasciare in eredità uno stato di colore sbagliato: essendo l'ultima pagina disegnata nel documento (`ReportPdf#draw_back_cover` la chiama per ultima), non importa nemmeno quale colore lasci attivo alla chiusura del `Prawn::Document`. Questo la rende, insieme a `CoverPage`, uno dei due soli punti del pacchetto SPI dove il gotcha "`fill_color` è stato documento-wide" (vedi `cover_page.md`) non si applica per costruzione, non per attenzione esplicita.
>
> *EN: Unlike `CoverPage`, `ZoningDividerPage`, and `LegendPage`, this class never calls `fill_color` — it draws no text, only a full-page image. So there's no risk of inheriting or leaving behind a wrong color state: being the last page drawn in the document (`ReportPdf#draw_back_cover` calls it last), it doesn't even matter what color it leaves active when the `Prawn::Document` closes. That makes it, along with `CoverPage`, one of only two spots in the SPI package where the "`fill_color` is document-wide state" gotcha (see `cover_page.md`) doesn't apply by construction, not by deliberate care.*
