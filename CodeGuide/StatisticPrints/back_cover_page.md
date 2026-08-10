# `StatisticPrints::BackCoverPage`

**File:** `app/services/statistic_prints/back_cover_page.rb`

## Codice completo

```ruby
module StatisticPrints
  class BackCoverPage
    BACKGROUND_IMAGE = Rails.root.join("app/assets/images/statistic_prints/backcover_background.png")

    def self.draw(pdf)
      pdf.image BACKGROUND_IMAGE.to_s, at: [ 0, pdf.bounds.top ], width: pdf.bounds.width, height: pdf.bounds.height
    end
  end
end
```

## Sezioni commentate

### La classe intera

```ruby
module StatisticPrints
  class BackCoverPage
    BACKGROUND_IMAGE = Rails.root.join("app/assets/images/statistic_prints/backcover_background.png")

    def self.draw(pdf)
      pdf.image BACKGROUND_IMAGE.to_s, at: [ 0, pdf.bounds.top ], width: pdf.bounds.width, height: pdf.bounds.height
    end
  end
end
```

> **IT:** La più semplice di tutta la cartella `StatisticPrints`, ed è semplice per un motivo preciso: non ha nulla da calcolare. Rompe deliberatamente il pattern `self.draw(...) = new(...).draw` + `initialize` seguito da ogni altra pagina della cartella (`CoverPage`, `ZoningDividerPage`, `LegendPage`, e le `CONTENT_PAGES`): qui `self.draw(pdf)` è un metodo di classe diretto, senza istanza, perché non c'è alcuno stato (`@form`, `@zoning`, ecc.) da portarsi dietro tra più metodi — un solo `pdf.image` con dimensioni prese da `pdf.bounds` esaurisce tutto il lavoro. Instanziare un oggetto solo per chiamare un metodo che userebbe un singolo argomento sarebbe cerimonia senza beneficio. Il confronto più diretto è con `CoverPage`: stesso ruolo nel fascicolo (immagine di sfondo a piena pagina), stesso invito da `ReportPdf` dentro `pdf.canvas { ... }` (vedi `report_pdf.md`), ma `CoverPage` ha bisogno di `@form` per disegnare il periodo sopra lo sfondo e quindi giustifica l'istanza — `BackCoverPage` no, perché non disegna alcun testo dinamico, solo l'immagine.
>
> *EN: The simplest file in the whole `StatisticPrints` folder, and it's simple for a precise reason: it has nothing to compute. It deliberately breaks the `self.draw(...) = new(...).draw` + `initialize` pattern followed by every other page in the folder (`CoverPage`, `ZoningDividerPage`, `LegendPage`, and the `CONTENT_PAGES`): here `self.draw(pdf)` is a direct class method, no instance, because there's no state (`@form`, `@zoning`, etc.) to carry across multiple methods — a single `pdf.image` call with dimensions taken from `pdf.bounds` does the entire job. Instantiating an object just to call a method that would use a single argument would be ceremony without benefit. The closest comparison is `CoverPage`: same role in the booklet (full-page background image), same invocation from `ReportPdf` inside `pdf.canvas { ... }` (see `report_pdf.md`), but `CoverPage` needs `@form` to draw the period on top of the background and so justifies the instance — `BackCoverPage` doesn't, because it draws no dynamic text at all, only the image.*
