# `Imports::SchemaSyncService`

**File:** `app/services/imports/schema_sync_service.rb`

## Codice completo

```ruby
module Imports
  class SchemaSyncService
    def self.call(headers)
      new(headers).call
    end

    def initialize(headers)
      @columns = headers.compact.map { |header| HeaderNormalizer.call(header) } - Import::IGNORED_COLUMNS
    end

    def call
      missing_columns.each { |column| add_column(column) }
      Import.reset_column_information if missing_columns.any?
    end

    private

    def missing_columns
      @missing_columns ||= @columns - Import.column_names
    end

    def add_column(column)
      return if ActiveRecord::Base.connection.column_exists?(:imports, column)

      type = Import::DATE_COLUMNS.include?(column) ? :date : :string
      ActiveRecord::Base.connection.add_column(:imports, column, type)
    end
  end
end
```

## Sezioni commentate

### Commento di classe (assente) e la decisione architetturale che rappresenta

> **IT:** Questa classe non ha un commento di classe esplicito, ma è probabilmente il pezzo più insolito di tutta la codebase: esegue `ActiveRecord::Base.connection.add_column` a **runtime**, durante una richiesta HTTP, non da una migration. `Import` ha uno schema che si allarga dinamicamente in base a qualunque intestazione compaia nel CSV caricato in quel momento — coerente con l'anti-pattern esplicitamente vietato altrove nel progetto ("Logica nei migrations — solo schema, dati nei seeds/tasks", da `CLAUDE.md`), ma qui la scelta è opposta e deliberata: *niente* migration per lo schema di `imports`, perché l'insieme esatto di colonne dipende da un export esterno (SinCGIL) il cui formato non è sotto il controllo del progetto e può cambiare export dopo export. Il compromesso: le colonne "note" (`azzonamento_di_riferimento_id`, `anno_di_riferimento`, `mese_di_riferimento`, i timestamp — vedi `FIXED_COLUMNS` in `CsvImporterService`) restano in una migration normale; tutte le altre nascono la prima volta che compaiono in un file caricato, e restano per sempre (nessun meccanismo di rimozione colonne).
>
> *EN: This class has no explicit class comment, but it's probably the most unusual piece in the entire codebase: it runs `ActiveRecord::Base.connection.add_column` at **runtime**, during an HTTP request, not from a migration. `Import`'s schema dynamically widens based on whatever headers show up in the CSV being uploaded at that moment — in apparent tension with the anti-pattern explicitly forbidden elsewhere in the project ("No logic in migrations — schema only, data in seeds/tasks", from `CLAUDE.md`), but here the choice is the opposite one, and deliberate: *no* migration governs `imports`' schema, because the exact set of columns depends on an external export (SinCGIL) whose format isn't under the project's control and can change from export to export. The trade-off: the "known" columns (`azzonamento_di_riferimento_id`, `anno_di_riferimento`, `mese_di_riferimento`, timestamps — see `FIXED_COLUMNS` in `CsvImporterService`) live in a normal migration; every other column is born the first time it appears in an uploaded file, and stays forever (no column-removal mechanism).*

### `initialize`

```ruby
def initialize(headers)
  @columns = headers.compact.map { |header| HeaderNormalizer.call(header) } - Import::IGNORED_COLUMNS
end
```

> **IT:** `headers.compact` scarta le colonne CSV senza intestazione (un'intestazione vuota/`nil` capita nei file SinCGIL, che a volte hanno colonne di servizio senza nome) prima ancora di normalizzarle — evitando di creare accidentalmente una colonna chiamata `""` o basata su un nome mancante. `Import::IGNORED_COLUMNS` (definita sul modello, non qui) è la lista di intestazioni che il progetto ha deciso di **non** importare mai come colonna — dati presenti nell'export ma irrilevanti per le statistiche. Sottrarla qui, prima del confronto con lo schema esistente, significa che `missing_columns` non le considera mai "mancanti": non generano mai un `add_column`.
>
> *EN: `headers.compact` discards CSV columns with no header (a blank/`nil` header does happen in SinCGIL files, which sometimes carry unnamed service columns) before even normalizing them — avoiding accidentally creating a column named `""` or based on a missing name. `Import::IGNORED_COLUMNS` (defined on the model, not here) is the list of headers the project has decided to **never** import as a column — data present in the export but irrelevant to the statistics. Subtracting it here, before comparing against the existing schema, means `missing_columns` never treats them as "missing": they never trigger an `add_column`.*

### `call`

```ruby
def call
  missing_columns.each { |column| add_column(column) }
  Import.reset_column_information if missing_columns.any?
end
```

> **IT:** `Import.reset_column_information` è la riga che rende visibile a Rails, nello **stesso processo**, le colonne appena aggiunte al database — senza questa chiamata, la cache degli attributi di ActiveRecord (costruita al primo caricamento della classe) resterebbe quella precedente all'`add_column`, e `Import.new(nuova_colonna: "x")` fallirebbe con un `NoMethodError` anche se la colonna esiste già a livello di database. La guardia `if missing_columns.any?` evita il costo di un reset (che invalida tutta la cache degli attributi, non solo le colonne nuove) quando questo CSV non introduce nulla di nuovo — il caso comune, dato che la maggior parte dei file caricati usa intestazioni già viste in import precedenti.
>
> *EN: `Import.reset_column_information` is the line that makes the newly added columns visible to Rails **within the same process** — without this call, ActiveRecord's attribute cache (built the first time the class loads) would still reflect the schema as it was before `add_column`, and `Import.new(new_column: "x")` would fail with a `NoMethodError` even though the column already exists at the database level. The `if missing_columns.any?` guard avoids the cost of a reset (which invalidates the entire attribute cache, not just the new columns) when this CSV introduces nothing new — the common case, since most uploaded files reuse headers already seen in earlier imports.*

### `missing_columns`, `add_column` *(privati)*

```ruby
def missing_columns
  @missing_columns ||= @columns - Import.column_names
end

def add_column(column)
  return if ActiveRecord::Base.connection.column_exists?(:imports, column)

  type = Import::DATE_COLUMNS.include?(column) ? :date : :string
  ActiveRecord::Base.connection.add_column(:imports, column, type)
end
```

> **IT:** `missing_columns` è un semplice diff insiemistico (`Array#-`) tra le colonne del CSV corrente e `Import.column_names` — la stessa cache degli attributi che poi `reset_column_information` invaliderà, quindi questo confronto usa deliberatamente lo stato **prima** di qualunque `add_column` in questa chiamata. Il controllo `column_exists?` dentro `add_column` è una seconda guardia, apparentemente ridondante con `missing_columns` (che già sottrae `Import.column_names`): la ragione è la concorrenza — se due import partono quasi in contemporanea con lo stesso nuovo nome di colonna, entrambi i processi potrebbero calcolare `missing_columns` prima che l'altro abbia eseguito il proprio `add_column`, e senza questo secondo controllo il secondo `add_column` fallirebbe con un errore "column already exists" a livello di database invece di limitarsi a saltare l'operazione. Solo due tipi di colonna esistono: `:date` (per le colonne elencate in `Import::DATE_COLUMNS`) e `:string` per tutto il resto — nessun `:integer`/`:decimal`/`:boolean`, perché l'unico consumatore che ha davvero bisogno di un tipo numerico stretto (SPI, con i suoi importi in euro) vive in `ImportSpis::SchemaSyncService`, non qui.
>
> *EN: `missing_columns` is a plain set difference (`Array#-`) between the current CSV's columns and `Import.column_names` — the same attribute cache that `reset_column_information` will later invalidate, so this comparison deliberately uses the state **before** any `add_column` call in this invocation. The `column_exists?` check inside `add_column` is a second guard, apparently redundant with `missing_columns` (which already subtracts `Import.column_names`): the reason is concurrency — if two imports start nearly simultaneously with the same new column name, both processes could compute `missing_columns` before either has run its own `add_column`, and without this second check the second `add_column` would fail with a database-level "column already exists" error instead of simply skipping the operation. Only two column types exist: `:date` (for columns listed in `Import::DATE_COLUMNS`) and `:string` for everything else — no `:integer`/`:decimal`/`:boolean`, because the one consumer that genuinely needs a strict numeric type (SPI, with its euro amounts) lives in `ImportSpis::SchemaSyncService`, not here.*
