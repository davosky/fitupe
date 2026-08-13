# `Legend`

**File:** `app/models/legend.rb`

## Codice completo

```ruby
class Legend < ApplicationRecord
  belongs_to :zoning
  has_rich_text :description

  validates :year, presence: true, format: { with: /\A\d{4}\z/, message: "deve essere un anno a 4 cifre" }
  validates :month, presence: true, inclusion: { in: ImportForm::MESI }
  validates :description, presence: true
  validates :year, uniqueness: { scope: %i[zoning_id month], message: "esiste già una legenda per questo azzonamento, anno e mese" }
end
```

## Sezioni commentate

### La classe intera — il testo libero di un report PDF, modellato come record ActiveRecord

> **IT:** `Legend` esiste per dare a un operatore un editor di testo ricco (`has_rich_text :description`, cioè ActionText/Trix) collegato a un preciso azzonamento/anno/mese, il cui contenuto viene poi iniettato in "Stampa Statistiche" come pagina di legenda. `belongs_to :zoning` è l'unica relazione dichiarata qui; non c'è alcun riferimento diretto a `Import` o a un periodo statistico — il collegamento con "quale report mostra questa legenda" è puramente per **coincidenza di chiavi** (`zoning_id` + `year` + `month`), risolto a runtime da `TotalMembersForm#legend` (`Legend.find_by(zoning_id:, year: anno, month: mese)`), non da una foreign key. `StatisticPrints::ReportPdf` disegna la pagina di legenda solo se `@form.legend.present?` — una legenda non è obbligatoria per generare un report, e la sua assenza non è un errore.
>
> *EN: `Legend` exists to give an operator a rich-text editor (`has_rich_text :description`, i.e. ActionText/Trix) tied to a specific zoning/year/month, whose content is later injected into "Stampa Statistiche" as a legend page. `belongs_to :zoning` is the only relationship declared here; there's no direct reference to `Import` or a statistical period — the link to "which report shows this legend" is purely by **key coincidence** (`zoning_id` + `year` + `month`), resolved at runtime by `TotalMembersForm#legend` (`Legend.find_by(zoning_id:, year: anno, month: mese)`), not by a foreign key. `StatisticPrints::ReportPdf` only draws the legend page if `@form.legend.present?` — a legend isn't mandatory to generate a report, and its absence isn't an error.*

### `validates :month, inclusion: { in: ImportForm::MESI }` — un accoppiamento deliberato a un'altra area del progetto

```ruby
validates :month, presence: true, inclusion: { in: ImportForm::MESI }
```

> **IT:** `Legend` non ha, e non vuole avere, una propria lista di mesi: riusa la costante `ImportForm::MESI` (l'elenco dei dodici mesi in italiano, vedi `CodeGuide/Imports/README.md`), esattamente come fa `TotalMembersForm#mese`. È un accoppiamento a un modulo apparentemente non correlato (`Legend` non ha nulla a che fare con l'import di CSV), ma è deliberato: garantisce che l'insieme di valori validi per "mese" sia **uno solo** in tutta l'applicazione, non una copia duplicata che potrebbe divergere. Il costo è che chi legge `legend.rb` in isolamento deve sapere di andare a cercare `ImportForm` per capire quali valori sono ammessi — non è auto-documentato nel file stesso.
>
> *EN: `Legend` has, and deliberately doesn't want, its own list of months: it reuses the `ImportForm::MESI` constant (the twelve Italian month names, see `CodeGuide/Imports/README.md`), exactly like `TotalMembersForm#mese` does. It's a coupling to a seemingly unrelated module (`Legend` has nothing to do with CSV import), but it's deliberate: it guarantees the set of valid "month" values is **one single source** across the whole application, not a duplicate copy that could drift apart. The cost is that anyone reading `legend.rb` in isolation has to know to go look at `ImportForm` to see which values are allowed — it isn't self-documented in the file itself.*

### `validates :year, uniqueness: { scope: %i[zoning_id month] }` — la chiave composta che rende sicuro ogni `find_by`

```ruby
validates :year, uniqueness: { scope: %i[zoning_id month], message: "esiste già una legenda per questo azzonamento, anno e mese" }
```

> **IT:** L'attributo controllato per unicità è `year`, ma lo `scope` include sia `zoning_id` che `month` — il risultato pratico è identico a validare l'unicità della tripla `(zoning_id, year, month)`, indipendentemente da quale dei tre attributi venga dichiarato come "quello controllato": Rails valuta comunque la combinazione intera. Questo è il vincolo che rende sicuro `TotalMembersForm#legend` (`Legend.find_by(zoning_id:, year: anno, month: mese)`): al massimo una legenda per ogni combinazione azzonamento/anno/mese, mai un'ambiguità su quale restituire. È lo stesso schema già visto in `IntegrationFillea` (vedi `CodeGuide/IntegrationFilleas/integration_fillea.md`), esteso di un attributo — `Legend` è granulare **per mese**, non solo per anno, perché un report PDF viene generato per un preciso mese, non per un intero anno.
>
> *EN: The attribute checked for uniqueness is `year`, but the `scope` includes both `zoning_id` and `month` — the practical result is identical to validating uniqueness of the `(zoning_id, year, month)` triple, regardless of which of the three attributes is declared as "the one checked": Rails evaluates the whole combination either way. This is the constraint that makes `TotalMembersForm#legend` safe (`Legend.find_by(zoning_id:, year: anno, month: mese)`): at most one legend per zoning/year/month combination, never ambiguity over which to return. It's the same pattern already seen on `IntegrationFillea` (see `CodeGuide/IntegrationFilleas/integration_fillea.md`), extended by one attribute — `Legend` is granular **per month**, not just per year, because a PDF report is generated for one specific month, not a whole year.*

### `has_rich_text :description` — perché ActionText e non una colonna `text`

> **IT:** `description` non è una colonna diretta sulla tabella `legends`: `has_rich_text` la sostituisce con una relazione polimorfica verso `ActionText::RichText`, che memorizza HTML generato dall'editor Trix montato nel form (vedi `app/views/legends/_form.html.erb`, controller Stimulus `trix`). La scelta di ActionText invece di un semplice `text_field`/`text_area` è ciò che permette il grassetto, il corsivo, le liste e i link nella legenda — formattazione che poi `StatisticPrints::LegendContent` parsifica da HTML a un array di blocchi Ruby per il rendering in PDF con Prawn (vedi `CodeGuide/StatisticPrints/legend_content.md`, `CodeGuide/StatisticPrints/legend_page.md`). `validates :description, presence: true` funziona anche su un attributo ActionText: Rails valida la presenza del corpo HTML associato, non di una colonna della tabella.
>
> *EN: `description` isn't a direct column on the `legends` table: `has_rich_text` replaces it with a polymorphic relationship to `ActionText::RichText`, which stores HTML generated by the Trix editor mounted in the form (see `app/views/legends/_form.html.erb`, the `trix` Stimulus controller). Choosing ActionText over a plain `text_field`/`text_area` is what allows bold, italics, lists, and links in the legend — formatting that `StatisticPrints::LegendContent` then parses from HTML into an array of Ruby blocks for Prawn PDF rendering (see `CodeGuide/StatisticPrints/legend_content.md`, `CodeGuide/StatisticPrints/legend_page.md`). `validates :description, presence: true` works on an ActionText attribute too: Rails validates the presence of the associated HTML body, not of a table column.*
