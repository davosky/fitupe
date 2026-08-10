# `Imports::CsvImporterService`

**File:** `app/services/imports/csv_importer_service.rb`

## Codice completo

```ruby
require "csv"

module Imports
  # Bulk-loads a large CSV via PostgreSQL COPY (much faster than batched
  # insert_all for tens of thousands of rows), reporting progress as it streams.
  class CsvImporterService
    PROGRESS_EVERY = 1000
    FIXED_COLUMNS = %i[azzonamento_di_riferimento_id anno_di_riferimento mese_di_riferimento created_at updated_at].freeze

    def self.call(...)
      new(...).call
    end

    def initialize(path:, zoning_id:, anno:, mese:, overwrite:, progress: ->(_percent) { })
      @path = path
      @zoning_id = zoning_id
      @anno = anno
      @mese = mese
      @overwrite = overwrite
      @progress = progress
    end

    def call
      raw_headers = CSV.open(@path, col_sep: ";", liberal_parsing: true, &:shift)
      SchemaSyncService.call(raw_headers)
      @field_specs = build_field_specs(raw_headers)
      @columns = FIXED_COLUMNS + @field_specs.compact.map(&:first)
      total = [ count_data_rows, 1 ].max

      Import.transaction do
        delete_existing_scope if @overwrite
        copy_rows(total)
      end
    end

    private

    # Precomputes, once per file, the (column, is_date?) each CSV column maps
    # to — normalizing the header on every row would dominate the runtime.
    def build_field_specs(raw_headers)
      raw_headers.map do |header|
        next nil if header.nil?

        column = HeaderNormalizer.call(header)
        next nil if Import::IGNORED_COLUMNS.include?(column)

        [ column.to_sym, Import::DATE_COLUMNS.include?(column) ]
      end
    end

    def delete_existing_scope
      Import.where(azzonamento_di_riferimento_id: @zoning_id, anno_di_riferimento: @anno,
        mese_di_riferimento: @mese).delete_all
    end

    def copy_rows(total)
      imported = 0
      now = Time.current.iso8601
      connection = ActiveRecord::Base.connection.raw_connection

      connection.copy_data("COPY imports (#{@columns.join(',')}) FROM STDIN WITH (FORMAT csv)") do
        CSV.foreach(@path, headers: true, col_sep: ";", liberal_parsing: true) do |row|
          connection.put_copy_data(copy_line(row.fields, now))
          imported += 1
          @progress.call(percent(imported, total)) if (imported % PROGRESS_EVERY).zero?
        end
      end

      @progress.call(100)
      imported
    end

    def copy_line(fields, now)
      values = [ @zoning_id, @anno, @mese, now, now ]

      fields.each_with_index do |value, index|
        spec = @field_specs[index]
        next if spec.nil?

        _column, is_date = spec
        value = value&.strip.presence
        values << (is_date ? parse_date(value) : value)
      end

      CSV.generate_line(values, row_sep: "\n")
    end

    def parse_date(value)
      return nil if value.blank?

      Date.iso8601(value)
    rescue ArgumentError
      nil
    end

    def percent(imported, total)
      [ (imported * 100.0 / total).round, 99 ].min
    end

    def count_data_rows
      File.foreach(@path).count - 1
    end
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Bulk-loads a large CSV via PostgreSQL COPY (much faster than batched
# insert_all for tens of thousands of rows), reporting progress as it streams.
class CsvImporterService
```

> **IT:** La decisione di fondo di tutta la classe: usare il comando `COPY` di PostgreSQL (via `pdf.raw_connection.copy_data`, non un `insert_all`/`import` di ActiveRecord) per caricare file che possono contenere decine di migliaia di righe. `COPY` è l'unico meccanismo dell'ecosistema Rails/PostgreSQL abbastanza veloce da rendere pratico caricare un intero export SinCGIL in una richiesta HTTP sincrona invece che in un job in background — un compromesso deliberato tra semplicità architetturale (nessun job, nessuna coda, progresso mostrato in tempo reale via callback) e velocità grezza.
>
> *EN: The class's foundational decision: use PostgreSQL's `COPY` command (via `pdf.raw_connection.copy_data`, not an ActiveRecord `insert_all`/`import`) to load files that can contain tens of thousands of rows. `COPY` is the one mechanism in the Rails/PostgreSQL ecosystem fast enough to make loading an entire SinCGIL export practical within a single synchronous HTTP request instead of a background job — a deliberate trade-off between architectural simplicity (no job, no queue, progress shown live via callback) and raw speed.*

### `FIXED_COLUMNS` (costante)

```ruby
FIXED_COLUMNS = %i[azzonamento_di_riferimento_id anno_di_riferimento mese_di_riferimento created_at updated_at].freeze
```

> **IT:** Le uniche cinque colonne di `imports` che esistono da una migration normale, non create a runtime da `SchemaSyncService` (vedi `CodeGuide/Imports/schema_sync_service.md`) — i tre parametri scelti dall'utente nel form di caricamento più i due timestamp standard di ActiveRecord, gestiti manualmente qui perché `COPY` bypassa completamente il ciclo di vita di ActiveRecord (nessun callback `created_at`/`updated_at` automatico). Ogni altra colonna in `imports` viene dal CSV stesso.
>
> *EN: The only five `imports` columns that come from a normal migration, not created at runtime by `SchemaSyncService` (see `CodeGuide/Imports/schema_sync_service.md`) — the three parameters the user chose in the upload form, plus the two standard ActiveRecord timestamps, handled manually here because `COPY` completely bypasses ActiveRecord's lifecycle (no automatic `created_at`/`updated_at` callback). Every other column in `imports` comes from the CSV itself.*

### `initialize`

```ruby
def initialize(path:, zoning_id:, anno:, mese:, overwrite:, progress: ->(_percent) { })
  @path = path
  @zoning_id = zoning_id
  @anno = anno
  @mese = mese
  @overwrite = overwrite
  @progress = progress
end
```

> **IT:** `progress:` ha un default esplicito, una lambda no-op — non `nil` con un controllo `@progress&.call(...)` sparso nel resto della classe. Questo permette a `copy_rows` di chiamare `@progress.call(...)` incondizionatamente, senza mai chiedersi se un callback è stato fornito: il chiamante reale (il controller, tramite ActionCable/Turbo Stream per mostrare una barra di progresso) passa una lambda vera, ma qualunque test o chiamata diretta al servizio funziona comunque senza doverla specificare.
>
> *EN: `progress:` has an explicit default, a no-op lambda — not `nil` with a scattered `@progress&.call(...)` check throughout the rest of the class. This lets `copy_rows` call `@progress.call(...)` unconditionally, never having to ask whether a callback was provided: the real caller (the controller, via ActionCable/Turbo Stream to show a progress bar) passes a real lambda, but any test or direct call to the service still works without having to specify one.*

### `call`

```ruby
def call
  raw_headers = CSV.open(@path, col_sep: ";", liberal_parsing: true, &:shift)
  SchemaSyncService.call(raw_headers)
  @field_specs = build_field_specs(raw_headers)
  @columns = FIXED_COLUMNS + @field_specs.compact.map(&:first)
  total = [ count_data_rows, 1 ].max

  Import.transaction do
    delete_existing_scope if @overwrite
    copy_rows(total)
  end
end
```

> **IT:** `col_sep: ";"` riflette il formato reale dell'export SinCGIL (CSV con punto e virgola, non virgola — comune nei formati italiani/europei dove la virgola è già il separatore decimale). `liberal_parsing: true` tollera CSV mal formati (virgolette non bilanciate, ecc.) che altrimenti farebbero sollevare un'eccezione alla libreria standard `CSV` — necessario perché il progetto non ha controllo sulla qualità dell'export esterno. `CSV.open(..., &:shift)` legge **solo la prima riga** (le intestazioni) senza caricare l'intero file in memoria, chiudendo il file subito dopo — `copy_rows` riaprirà lo stesso file una seconda volta con `CSV.foreach` per il vero streaming riga per riga. L'ordine delle operazioni è significativo: `SchemaSyncService.call` (che può eseguire `ALTER TABLE`) va eseguito **prima** di costruire `@columns`, altrimenti la lista di colonne passata a `COPY` potrebbe includere una colonna non ancora esistente nel database. `total = [count_data_rows, 1].max` evita una divisione per zero in `percent` se il file caricato è vuoto (nessuna riga dati oltre l'intestazione). L'intera operazione — sia l'eventuale cancellazione dei dati esistenti sia il caricamento — è avvolta in un'unica `Import.transaction`: se `copy_rows` fallisce a metà streaming (es. un valore che rompe il formato COPY), i dati eventualmente già cancellati con `overwrite: true` non restano orfani.
>
> *EN: `col_sep: ";"` reflects the SinCGIL export's actual format (semicolon-delimited CSV, not comma — common in Italian/European formats where the comma is already the decimal separator). `liberal_parsing: true` tolerates malformed CSV (unbalanced quotes, etc.) that would otherwise make the standard `CSV` library raise — necessary because the project has no control over the external export's quality. `CSV.open(..., &:shift)` reads **only the first row** (the headers) without loading the whole file into memory, closing the file right after — `copy_rows` will reopen the same file a second time with `CSV.foreach` for the actual row-by-row streaming. The order of operations matters: `SchemaSyncService.call` (which can run `ALTER TABLE`) must run **before** `@columns` is built, otherwise the column list passed to `COPY` could include a column that doesn't exist in the database yet. `total = [count_data_rows, 1].max` avoids a division by zero in `percent` if the uploaded file is empty (no data rows beyond the header). The whole operation — both the optional deletion of existing data and the load itself — is wrapped in a single `Import.transaction`: if `copy_rows` fails partway through streaming (e.g. a value that breaks the COPY format), data already deleted under `overwrite: true` isn't left orphaned.*

### `build_field_specs` *(privato)*

```ruby
def build_field_specs(raw_headers)
  raw_headers.map do |header|
    next nil if header.nil?

    column = HeaderNormalizer.call(header)
    next nil if Import::IGNORED_COLUMNS.include?(column)

    [ column.to_sym, Import::DATE_COLUMNS.include?(column) ]
  end
end
```

> **IT:** Come spiega il commento originale, questa mappa posizionale (`@field_specs[i]` corrisponde alla colonna CSV all'indice `i`) esiste per evitare di richiamare `HeaderNormalizer.call`/i controlli `IGNORED_COLUMNS`/`DATE_COLUMNS` per **ogni singola riga** del file — su un CSV da 50.000 righe, spostare questo lavoro fuori dal loop di `copy_rows` è la differenza tra un calcolo fatto una volta e uno fatto 50.000 volte. `next nil` (due volte: header assente, colonna ignorata) lascia dei "buchi" nell'array, mantenendo l'allineamento posizionale con `raw_headers` — `copy_line` userà poi lo stesso indice per saltare quei campi durante la costruzione di ogni riga.
>
> *EN: As the original comment explains, this positional map (`@field_specs[i]` corresponds to the CSV column at index `i`) exists to avoid re-running `HeaderNormalizer.call`/the `IGNORED_COLUMNS`/`DATE_COLUMNS` checks for **every single row** of the file — on a 50,000-row CSV, moving this work out of `copy_rows`'s loop is the difference between doing the computation once versus 50,000 times. `next nil` (twice: missing header, ignored column) leaves "holes" in the array, preserving positional alignment with `raw_headers` — `copy_line` later uses that same index to skip those fields when building each row.*

### `delete_existing_scope` *(privato)*

```ruby
def delete_existing_scope
  Import.where(azzonamento_di_riferimento_id: @zoning_id, anno_di_riferimento: @anno,
    mese_di_riferimento: @mese).delete_all
end
```

> **IT:** `delete_all`, non `destroy_all`: un'eliminazione SQL diretta, senza istanziare né eseguire callback su ogni record — coerente con lo spirito "bulk" di tutta la classe, dato che qui si può parlare di decine di migliaia di righe da rimuovere prima di ricaricare lo stesso periodo/azzonamento con `overwrite: true`. `Import` non ha callback `before_destroy` di cui preoccuparsi, quindi `delete_all` non salta nulla di importante.
>
> *EN: `delete_all`, not `destroy_all`: a direct SQL deletion, no instantiation or per-record callbacks — consistent with the "bulk" spirit of the whole class, given this can mean tens of thousands of rows removed before reloading the same period/zoning with `overwrite: true`. `Import` has no `before_destroy` callbacks to worry about, so `delete_all` isn't skipping anything meaningful.*

### `copy_rows` *(privato)*

```ruby
def copy_rows(total)
  imported = 0
  now = Time.current.iso8601
  connection = ActiveRecord::Base.connection.raw_connection

  connection.copy_data("COPY imports (#{@columns.join(',')}) FROM STDIN WITH (FORMAT csv)") do
    CSV.foreach(@path, headers: true, col_sep: ";", liberal_parsing: true) do |row|
      connection.put_copy_data(copy_line(row.fields, now))
      imported += 1
      @progress.call(percent(imported, total)) if (imported % PROGRESS_EVERY).zero?
    end
  end

  @progress.call(100)
  imported
end
```

> **IT:** `ActiveRecord::Base.connection.raw_connection` scende sotto l'astrazione di ActiveRecord fino al driver `pg` grezzo — `copy_data`/`put_copy_data` sono API del driver PostgreSQL, non di Rails. `now = Time.current.iso8601` viene calcolato **una sola volta** fuori dal loop: tutte le righe di uno stesso caricamento CSV condividono lo stesso `created_at`/`updated_at`, non un timestamp per riga — coerente con il fatto che rappresentano "un batch importato in un unico momento", non eventi indipendenti. `(imported % PROGRESS_EVERY).zero?` limita le chiamate al callback di progresso a una ogni 1000 righe (`PROGRESS_EVERY`), non a ogni riga — su decine di migliaia di righe, notificare il progresso ad ogni singola riga avrebbe un costo (I/O verso il client, es. via ActionCable) sproporzionato rispetto al beneficio percepito dall'utente. `@progress.call(100)` finale è incondizionato: garantisce che il completamento venga sempre segnalato, anche quando l'ultimo batch di righe non cade esattamente su un multiplo di `PROGRESS_EVERY`.
>
> *EN: `ActiveRecord::Base.connection.raw_connection` drops below ActiveRecord's abstraction down to the raw `pg` driver — `copy_data`/`put_copy_data` are PostgreSQL driver APIs, not Rails ones. `now = Time.current.iso8601` is computed **once**, outside the loop: every row from the same CSV upload shares the same `created_at`/`updated_at`, not a per-row timestamp — consistent with the fact that they represent "a batch imported at one moment," not independent events. `(imported % PROGRESS_EVERY).zero?` throttles progress-callback calls to once every 1000 rows (`PROGRESS_EVERY`), not every row — across tens of thousands of rows, notifying progress on every single row would have a cost (I/O toward the client, e.g. via ActionCable) disproportionate to the perceived benefit to the user. The final `@progress.call(100)` is unconditional: it guarantees completion is always signaled, even when the last batch of rows doesn't land exactly on a `PROGRESS_EVERY` multiple.*

### `copy_line` *(privato)*

```ruby
def copy_line(fields, now)
  values = [ @zoning_id, @anno, @mese, now, now ]

  fields.each_with_index do |value, index|
    spec = @field_specs[index]
    next if spec.nil?

    _column, is_date = spec
    value = value&.strip.presence
    values << (is_date ? parse_date(value) : value)
  end

  CSV.generate_line(values, row_sep: "\n")
end
```

> **IT:** `values` inizia con i cinque `FIXED_COLUMNS` nell'ordine esatto in cui compaiono nella stringa `COPY imports (#{@columns.join(',')})` costruita in `call` — un accoppiamento posizionale implicito tra `FIXED_COLUMNS`, l'ordine di `values` qui, e `@columns`: cambiare l'ordine in uno dei tre punti senza aggiornare gli altri due produrrebbe dati silenziosamente scritti nelle colonne sbagliate, senza che `COPY` sollevi un errore (i valori sarebbero comunque del tipo giusto — stringhe — solo nel posto sbagliato). `spec.nil?` salta i campi CSV corrispondenti a un'intestazione mancante o ignorata (i "buchi" lasciati da `build_field_specs`), mantenendo `values` coerente con `@columns`. `value&.strip.presence` normalizza spazi e stringhe vuote a `nil` per **ogni** valore, non solo le date — un CSV con celle vuote (`""`) o solo spazi non deve produrre stringhe vuote nel database, deve produrre `NULL`. Infine, `CSV.generate_line(..., row_sep: "\n")` genera una singola riga in formato CSV standard (virgola, non punto e virgola: il formato richiesto da `COPY ... WITH (FORMAT csv)` è sempre lo standard RFC 4180, indipendentemente dal separatore del file sorgente) — il file caricato dall'utente e il flusso inviato a `COPY` hanno quindi due delimitatori diversi, `;` in ingresso e `,` in uscita, un dettaglio facile da confondere leggendo il codice fuori contesto.
>
> *EN: `values` starts with the five `FIXED_COLUMNS` in the exact order they appear in the `COPY imports (#{@columns.join(',')})` string built in `call` — an implicit positional coupling between `FIXED_COLUMNS`, the order of `values` here, and `@columns`: changing the order in one of these three places without updating the other two would silently write data into the wrong columns, without `COPY` ever raising an error (the values would still be the right type — strings — just in the wrong slot). `spec.nil?` skips CSV fields corresponding to a missing or ignored header (the "holes" left by `build_field_specs`), keeping `values` aligned with `@columns`. `value&.strip.presence` normalizes whitespace and empty strings to `nil` for **every** value, not just dates — a CSV with blank cells (`""`) or whitespace-only cells must not produce empty strings in the database, it must produce `NULL`. Finally, `CSV.generate_line(..., row_sep: "\n")` generates a single line in standard CSV format (comma, not semicolon: the format required by `COPY ... WITH (FORMAT csv)` is always standard RFC 4180, regardless of the source file's delimiter) — the file the user uploaded and the stream sent to `COPY` therefore use two different delimiters, `;` on the way in and `,` on the way out, an easy detail to confuse when reading the code out of context.*

### `parse_date`, `percent`, `count_data_rows` *(privati)*

```ruby
def parse_date(value)
  return nil if value.blank?

  Date.iso8601(value)
rescue ArgumentError
  nil
end

def percent(imported, total)
  [ (imported * 100.0 / total).round, 99 ].min
end

def count_data_rows
  File.foreach(@path).count - 1
end
```

> **IT:** `parse_date` è una delle poche istanze del progetto dove un `rescue ArgumentError` esplicito senza rilanciare l'eccezione è intenzionale, non un anti-pattern nascosto: un valore data malformato (formato imprevisto, refuso nell'export) diventa silenziosamente `NULL` invece di interrompere l'intero import di decine di migliaia di righe — una scelta di robustezza specifica per dati esterni non controllati, diversa dal principio generale del progetto di evitare `rescue` ampi. `percent` limita il massimo a **99**, mai 100, durante lo streaming — il 100% viene comunicato solo dalla chiamata esplicita e incondizionata in `copy_rows` dopo che il loop è terminato, cosicché "100%" significhi sempre "operazione davvero conclusa", non "quasi finita per arrotondamento". `count_data_rows` conta le righe del file **due volte** nel corso di un'esecuzione (qui, e implicitamente da `CSV.foreach` in `copy_rows`) — un costo I/O accettato deliberatamente perché serve un totale noto in anticipo per calcolare le percentuali di progresso, e leggere un file riga per riga con `File.foreach` (senza parsing CSV) è comunque molto più economico del parsing completo che segue.
>
> *EN: `parse_date` is one of the few places in the project where an explicit `rescue ArgumentError` with no re-raise is intentional, not a hidden anti-pattern: a malformed date value (unexpected format, a typo in the export) silently becomes `NULL` instead of aborting the entire tens-of-thousands-of-rows import — a robustness choice specific to uncontrolled external data, distinct from the project's general principle of avoiding broad `rescue`s. `percent` caps the maximum at **99**, never 100, during streaming — 100% is only ever communicated by the explicit, unconditional call in `copy_rows` after the loop finishes, so "100%" always means "the operation is truly done," not "almost done due to rounding." `count_data_rows` reads the file's rows **twice** over the course of one run (here, and implicitly via `CSV.foreach` in `copy_rows`) — an I/O cost accepted deliberately because a known-in-advance total is needed to compute progress percentages, and reading a file line by line with `File.foreach` (no CSV parsing) is still much cheaper than the full parsing pass that follows.*
