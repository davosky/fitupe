# `IntegrationFillea`

**File:** `app/models/integration_fillea.rb`

## Codice completo

```ruby
class IntegrationFillea < ApplicationRecord
  belongs_to :zoning

  validates :year, presence: true, format: { with: /\A\d{4}\z/, message: "deve essere un anno a 4 cifre" }
  validates :subscribers_ce, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :year, uniqueness: { scope: :zoning_id, message: "esiste già un'integrazione per questo azzonamento e anno" }
end
```

## Sezioni commentate

### La classe intera — le validazioni sono l'unica logica del modello

> **IT:** Sette righe totali, e portano da sole tutta la logica di dominio di questa risorsa — coerente con la convenzione del progetto ("Callback nei modelli per logica di business" è un anti-pattern esplicitamente vietato in `CLAUDE.md`: qui non c'è nessun callback, solo validazioni dichiarative). `belongs_to :zoning` è l'unica relazione: un `IntegrationFillea` esiste sempre per un azzonamento specifico, mai a livello puramente regionale in astratto — coerente con `StatisticWithIntegrations::FilleaCorrection#dato_presente?`, che interroga sempre `IntegrationFillea.exists?(zoning:, year:)` con uno zoning concreto (mai `nil`), sia per la provincia scelta sia, a livello regionale, per ciascuna provincia figlia (vedi `CodeGuide/StatisticWithIntegrations/fillea_correction.md`).
>
> *EN: Seven lines total, and they alone carry this resource's entire domain logic — consistent with the project's convention ("Callbacks in models for business logic" is an anti-pattern explicitly forbidden in `CLAUDE.md`: there's no callback here, only declarative validations). `belongs_to :zoning` is the only relationship: an `IntegrationFillea` always exists for a specific zoning, never at a purely abstract regional level — consistent with `StatisticWithIntegrations::FilleaCorrection#dato_presente?`, which always queries `IntegrationFillea.exists?(zoning:, year:)` with a concrete zoning (never `nil`), both for the chosen province and, at the regional level, for each child province (see `CodeGuide/StatisticWithIntegrations/fillea_correction.md`).*

### `validates :year` — formato, non tipo di colonna

```ruby
validates :year, presence: true, format: { with: /\A\d{4}\z/, message: "deve essere un anno a 4 cifre" }
```

> **IT:** `year` è validato con una regex di formato (`/\A\d{4}\z/`, esattamente quattro cifre), non con `numericality`/un vincolo di range — segno che la colonna `year` è una **stringa**, non un intero, coerente con `anno_di_riferimento` in `Import`/`ImportSpi` (vedi `CodeGuide/Imports/README.md`) e con `TotalMembersForm#anno` — l'intero progetto tratta l'anno come testo a 4 cifre in ogni punto dove viene confrontato o usato come chiave di ricerca, mai come un `Integer` con vincoli numerici (`greater_than`, ecc.). Questo è coerente con `StatisticWithIntegrations::FilleaCorrection#build_row`, che passa `@anno` (una stringa proveniente dal form) direttamente a `IntegrationFillea.find_by(zoning:, year: @anno)` — se `year` fosse un intero nel database, quel confronto tra stringa e intero fallirebbe silenziosamente su alcuni adapter o richiederebbe una conversione esplicita altrove.
>
> *EN: `year` is validated with a format regex (`/\A\d{4}\z/`, exactly four digits), not `numericality`/a range constraint — a sign that the `year` column is a **string**, not an integer, consistent with `anno_di_riferimento` in `Import`/`ImportSpi` (see `CodeGuide/Imports/README.md`) and with `TotalMembersForm#anno` — the whole project treats the year as 4-digit text at every point it's compared or used as a lookup key, never as an `Integer` with numeric constraints (`greater_than`, etc.). This is consistent with `StatisticWithIntegrations::FilleaCorrection#build_row`, which passes `@anno` (a string coming from the form) directly to `IntegrationFillea.find_by(zoning:, year: @anno)` — if `year` were an integer column, that string-to-integer comparison would either silently fail on some adapters or require an explicit conversion elsewhere.*

### `validates :subscribers_ce`

```ruby
validates :subscribers_ce, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
```

> **IT:** `greater_than_or_equal_to: 0`, non `greater_than: 0`: un valore **zero** è un dato legittimo (una provincia con zero iscritti Cassa Edile in un dato anno non è un errore di inserimento), non solo un placeholder per "nessun dato" — la distinzione tra "zero iscritti" e "nessuna integrazione inserita" è fatta a livello di **esistenza del record**, non di valore del campo: `StatisticWithIntegrations::FilleaCorrection#dato_presente?` controlla `IntegrationFillea.exists?(...)`, non `subscribers_ce > 0`. `only_integer: true` è coerente con il fatto che questo valore viene poi usato in una sottrazione intera (`cassa_edile - sincgil` in `FilleaCorrection#build_row`) contro un conteggio SQL, sempre un intero — nessun valore decimale avrebbe senso qui.
>
> *EN: `greater_than_or_equal_to: 0`, not `greater_than: 0`: a value of **zero** is legitimate data (a province with zero Cassa Edile members in a given year isn't a data-entry error), not merely a placeholder for "no data" — the distinction between "zero members" and "no integration entered" is made at the level of **record existence**, not field value: `StatisticWithIntegrations::FilleaCorrection#dato_presente?` checks `IntegrationFillea.exists?(...)`, not `subscribers_ce > 0`. `only_integer: true` is consistent with this value later being used in an integer subtraction (`cassa_edile - sincgil` in `FilleaCorrection#build_row`) against a SQL count, always an integer — no decimal value would make sense here.*

### `validates :year, uniqueness: { scope: :zoning_id }`

```ruby
validates :year, uniqueness: { scope: :zoning_id, message: "esiste già un'integrazione per questo azzonamento e anno" }
```

> **IT:** Il vincolo che rende sicuro l'uso di `find_by`/`exists?` in tutta `StatisticWithIntegrations::FilleaCorrection`: al massimo **un** record `IntegrationFillea` per coppia azzonamento/anno, mai zero-o-più con ambiguità su quale usare. Senza questa unicità, `IntegrationFillea.find_by(zoning:, year: @anno).subscribers_ce` in `FilleaCorrection#build_row` (vedi `CodeGuide/StatisticWithIntegrations/fillea_correction.md`) resterebbe sintatticamente valido ma sceglierebbe silenziosamente un record arbitrario tra eventuali duplicati — la validazione a livello di modello è ciò che garantisce che quella query restituisca sempre un risultato univoco e corretto, non solo "un" risultato qualsiasi. Coerente con il vincolo equivalente su `IntegrationFlc` (che aggiunge `:month` allo scope, per via della granularità mensile — vedi `CodeGuide/IntegrationFlcs/README.md`).
>
> *EN: The constraint that makes using `find_by`/`exists?` safe throughout `StatisticWithIntegrations::FilleaCorrection`: at most **one** `IntegrationFillea` record per zoning/year pair, never zero-or-more with ambiguity over which to use. Without this uniqueness, `IntegrationFillea.find_by(zoning:, year: @anno).subscribers_ce` in `FilleaCorrection#build_row` (see `CodeGuide/StatisticWithIntegrations/fillea_correction.md`) would remain syntactically valid but would silently pick an arbitrary record among any duplicates — the model-level validation is what guarantees that query always returns a unique, correct result, not just "some" result. Consistent with the equivalent constraint on `IntegrationFlc` (which adds `:month` to the scope, due to its monthly granularity — see `CodeGuide/IntegrationFlcs/README.md`).*
