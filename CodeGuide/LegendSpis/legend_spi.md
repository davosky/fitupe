# `LegendSpi`

**File:** `app/models/legend_spi.rb`

## Codice completo

```ruby
class LegendSpi < ApplicationRecord
  belongs_to :zoning
  has_rich_text :description

  validates :year, presence: true, format: { with: /\A\d{4}\z/, message: "deve essere un anno a 4 cifre" }
  validates :month, presence: true, inclusion: { in: ImportForm::MESI }
  validates :description, presence: true
  validates :year, uniqueness: { scope: %i[zoning_id month], message: "esiste già una legenda SPI per questo azzonamento, anno e mese" }
end
```

## Sezioni commentate

### La classe intera — clone riga per riga di `Legend`, per il report SPI

> **IT:** `LegendSpi` è identico a `Legend` (vedi `CodeGuide/Legends/legend.md`) in ogni dettaglio tranne il nome della classe e il testo del messaggio di unicità ("legenda SPI" invece di "legenda"): stessa `belongs_to :zoning`, stesso `has_rich_text :description`, stesse quattro validazioni, stessa dipendenza da `ImportForm::MESI`, stesso vincolo di unicità sulla tripla `(zoning_id, year, month)`. È lo stesso pattern di duplicazione deliberata già visto tra `Import`/`ImportSpi` e tra `Statistics::*`/`StatisticSpi::*`: Fitupe tratta sistematicamente i dati Attivi e i dati SPI (pensionati) come due domini paralleli con le proprie tabelle, i propri modelli e i propri controller, invece di introdurre un discriminatore polimorfico (`type`) su un'unica tabella `legends`. Il collegamento con il report a cui appartiene è, come per `Legend`, per coincidenza di chiave — qui risolto da `TotalMembersForm#legend_spi` (`LegendSpi.find_by(zoning_id:, year: anno, month: mese)`), non da `TotalMembersForm#legend`: lo stesso form serve entrambi i lookup, uno per ciascun dominio.
>
> *EN: `LegendSpi` is identical to `Legend` (see `CodeGuide/Legends/legend.md`) in every detail except the class name and the uniqueness message text ("legenda SPI" instead of "legenda"): same `belongs_to :zoning`, same `has_rich_text :description`, same four validations, same dependency on `ImportForm::MESI`, same uniqueness constraint on the `(zoning_id, year, month)` triple. It's the same deliberate-duplication pattern already seen between `Import`/`ImportSpi` and between `Statistics::*`/`StatisticSpi::*`: Fitupe systematically treats Attivi data and SPI (pensioners) data as two parallel domains with their own tables, models, and controllers, instead of introducing a polymorphic discriminator (`type`) on a single `legends` table. The link to the report it belongs to is, like `Legend`, by key coincidence — here resolved by `TotalMembersForm#legend_spi` (`LegendSpi.find_by(zoning_id:, year: anno, month: mese)`), not `TotalMembersForm#legend`: the same form object serves both lookups, one per domain.*

### Perché non un'unica tabella `legends` con un `type` polimorfico

> **IT:** L'alternativa "ovvia" — una singola tabella `legends` con una colonna `kind`/`type` per distinguere Attivi da SPI — avrebbe risparmiato la duplicazione di modello, controller, view e route vista qui. Il progetto non l'ha scelta, coerentemente con ogni altra area gemella (`Import`/`ImportSpi`, `Statistics`/`StatisticSpi`, `StatisticPrints`/`StatisticSpiPrints`): i due domini Attivi/SPI non condividono altro che la forma dei dati, non la logica di business, e ogni futura evoluzione specifica di un dominio (un campo in più solo per SPI, una regola di validazione diversa) è più facile da introdurre senza toccare l'altro se restano tabelle e classi separate fin dall'inizio.
>
> *EN: The "obvious" alternative — a single `legends` table with a `kind`/`type` column to distinguish Attivi from SPI — would have saved the model/controller/view/route duplication seen here. The project didn't choose it, consistent with every other twin area (`Import`/`ImportSpi`, `Statistics`/`StatisticSpi`, `StatisticPrints`/`StatisticSpiPrints`): the two Attivi/SPI domains share nothing but the shape of the data, not the business logic, and any future domain-specific evolution (an extra field only for SPI, a different validation rule) is easier to introduce without touching the other one if the tables and classes stay separate from the start.*
