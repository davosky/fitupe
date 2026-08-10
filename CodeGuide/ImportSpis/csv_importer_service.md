# `ImportSpis::CsvImporterService`

**File:** `app/services/import_spis/csv_importer_service.rb`

## Codice completo

```ruby
require "csv"

module ImportSpis
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

      ImportSpi.transaction do
        delete_existing_scope if @overwrite
        copy_rows(total)
      end
    end

    private

    # Precomputes, once per file, the (column, kind) each CSV column maps to —
    # normalizing the header and re-checking its kind on every row would
    # dominate the runtime.
    def build_field_specs(raw_headers)
      raw_headers.map do |header|
        next nil if header.nil?

        column = Imports::HeaderNormalizer.call(header)
        next nil if ImportSpi::IGNORED_COLUMNS.include?(column)

        [ column.to_sym, column_kind(column) ]
      end
    end

    def column_kind(column)
      return :date if ImportSpi::DATE_COLUMNS.include?(column)
      return :decimal if ImportSpi::DECIMAL_COLUMNS.include?(column)

      :string
    end

    def delete_existing_scope
      ImportSpi.where(azzonamento_di_riferimento_id: @zoning_id, anno_di_riferimento: @anno,
        mese_di_riferimento: @mese).delete_all
    end

    def copy_rows(total)
      imported = 0
      now = Time.current.iso8601
      connection = ActiveRecord::Base.connection.raw_connection

      connection.copy_data("COPY imports_spi (#{@columns.join(',')}) FROM STDIN WITH (FORMAT csv)") do
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

        _column, kind = spec
        value = value&.strip.presence
        values << format_value(value, kind)
      end

      CSV.generate_line(values, row_sep: "\n")
    end

    def format_value(value, kind)
      case kind
      when :date then parse_date(value)
      when :decimal then parse_decimal(value)
      else value
      end
    end

    def parse_date(value)
      return nil if value.blank?

      Date.iso8601(value)
    rescue ArgumentError
      nil
    end

    # SinCGIL exports decimals with an Italian comma separator (es. "10,17").
    def parse_decimal(value)
      value.blank? ? nil : value.tr(",", ".")
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

### Commento di classe e struttura generale, a confronto con `Imports::CsvImporterService`

> **IT:** Copia quasi identica di `Imports::CsvImporterService` (vedi `CodeGuide/Imports/csv_importer_service.md` per il ragionamento completo su `COPY`, il doppio delimitatore `;`/`,`, la memoizzazione di `now`, il throttling del progresso) — stessa scelta di `COPY` su `insert_all`, stessi `FIXED_COLUMNS`, stessa struttura `call`/`copy_rows`/`copy_line`. Le differenze reali si concentrano in tre punti, tutti legati allo stesso fatto: l'export SPI ha colonne numeriche (importi in euro) che l'export Attivi non ha.
>
> *EN: An almost identical copy of `Imports::CsvImporterService` (see `CodeGuide/Imports/csv_importer_service.md` for the full reasoning on `COPY`, the dual `;`/`,` delimiter, memoizing `now`, and progress throttling) — the same choice of `COPY` over `insert_all`, the same `FIXED_COLUMNS`, the same `call`/`copy_rows`/`copy_line` structure. The real differences concentrate in three spots, all tied to the same fact: the SPI export has numeric columns (euro amounts) that the Attivi export doesn't.*

### `build_field_specs`, `column_kind` *(privati)* — da booleano a simbolo a tre valori

```ruby
def build_field_specs(raw_headers)
  raw_headers.map do |header|
    next nil if header.nil?

    column = Imports::HeaderNormalizer.call(header)
    next nil if ImportSpi::IGNORED_COLUMNS.include?(column)

    [ column.to_sym, column_kind(column) ]
  end
end

def column_kind(column)
  return :date if ImportSpi::DATE_COLUMNS.include?(column)
  return :decimal if ImportSpi::DECIMAL_COLUMNS.include?(column)

  :string
end
```

> **IT:** La differenza strutturale principale rispetto alla versione Attivi: `build_field_specs` associa a ogni colonna un booleano `is_date` in `Imports::CsvImporterService` (perché lì esistono solo due casi), un simbolo `kind` (`:date`/`:decimal`/`:string`) qui — lo stesso spostamento da "controllo binario" a "controllo a tre vie" già visto in `ImportSpis::SchemaSyncService#column_type` (vedi `CodeGuide/ImportSpis/schema_sync_service.md`), applicato qui allo stesso identico problema ma a livello di riga anziché di schema. `column_kind` è quindi il gemello di `column_type`: stessa logica, stesso ordine di controllo, ma un metodo separato perché questa classe non condivide codice con `SchemaSyncService` — ogni classe della pipeline ricalcola la propria classificazione delle colonne in base alle stesse costanti del modello (`ImportSpi::DATE_COLUMNS`/`DECIMAL_COLUMNS`), che restano l'unica fonte di verità condivisa.
>
> *EN: The main structural difference from the Attivi version: `build_field_specs` attaches a boolean `is_date` to each column in `Imports::CsvImporterService` (because only two cases exist there), a symbol `kind` (`:date`/`:decimal`/`:string`) here — the same shift from "binary check" to "three-way check" already seen in `ImportSpis::SchemaSyncService#column_type` (see `CodeGuide/ImportSpis/schema_sync_service.md`), applied here to the exact same problem but at the row level instead of the schema level. `column_kind` is therefore `column_type`'s twin: same logic, same check order, but a separate method because this class shares no code with `SchemaSyncService` — every class in the pipeline recomputes its own column classification from the same model constants (`ImportSpi::DATE_COLUMNS`/`DECIMAL_COLUMNS`), which remain the one shared source of truth.*

### `format_value`, `parse_decimal` *(privati)* — la virgola decimale italiana

```ruby
def format_value(value, kind)
  case kind
  when :date then parse_date(value)
  when :decimal then parse_decimal(value)
  else value
  end
end

# SinCGIL exports decimals with an Italian comma separator (es. "10,17").
def parse_decimal(value)
  value.blank? ? nil : value.tr(",", ".")
end
```

> **IT:** `format_value` sostituisce il ternario inline `is_date ? parse_date(value) : value` della versione Attivi con un `case` a tre rami — la stessa forma di `column_kind`, applicata al valore invece che al nome colonna. `parse_decimal` è la logica realmente nuova: SinCGIL esporta i numeri decimali con la virgola come separatore italiano (es. `"10,17"`), non compatibile con il formato numerico che PostgreSQL si aspetta per una colonna `:decimal` durante un `COPY` (che richiede il punto, come quasi ogni formato dati anglosassone). `value.tr(",", ".")` è una sostituzione carattere-per-carattere (non una `gsub` con regex, inutile qui perché si sostituisce sempre lo stesso singolo carattere) — nessun controllo su eventuali separatori delle migliaia (es. `"1.234,56"`): se l'export SinCGIL li includesse, questa conversione produrrebbe un valore malformato che PostgreSQL rifiuterebbe con un errore a livello di `COPY`, non un `NULL` silenzioso come per `parse_date`. Questa asimmetria — le date malformate diventano `NULL` silenziosamente, i decimali malformati fanno fallire l'intero `COPY` — non è documentata altrove ed è il tipo di comportamento che vale la pena verificare se un giorno l'export SinCGIL cambiasse formato numerico.
>
> *EN: `format_value` replaces the Attivi version's inline ternary (`is_date ? parse_date(value) : value`) with a three-branch `case` — the same shape as `column_kind`, applied to the value instead of the column name. `parse_decimal` is the genuinely new logic: SinCGIL exports decimal numbers with an Italian comma separator (e.g. `"10,17"`), incompatible with the numeric format PostgreSQL expects for a `:decimal` column during a `COPY` (which requires a period, like nearly every Anglophone data format). `value.tr(",", ".")` is a character-by-character substitution (not a regex `gsub`, unnecessary here since it's always the same single character being replaced) — no handling of thousands separators (e.g. `"1.234,56"`): if the SinCGIL export ever included them, this conversion would produce a malformed value that PostgreSQL would reject with a `COPY`-level error, not a silent `NULL` like `parse_date`. This asymmetry — malformed dates silently become `NULL`, malformed decimals fail the entire `COPY` — isn't documented anywhere else and is the kind of behavior worth double-checking if the SinCGIL export's numeric format ever changed.*

### Tutto il resto (identico riga per riga alla versione Attivi)

> **IT:** `initialize`, `call`, `delete_existing_scope`, `copy_rows`, `copy_line`, `parse_date`, `percent`, `count_data_rows` non hanno nessuna differenza sostanziale rispetto a `Imports::CsvImporterService` oltre al nome del modello (`ImportSpi` invece di `Import`) e della tabella (`imports_spi` invece di `imports`) — vedi `CodeGuide/Imports/csv_importer_service.md` per il dettaglio completo di ciascuno.
>
> *EN: `initialize`, `call`, `delete_existing_scope`, `copy_rows`, `copy_line`, `parse_date`, `percent`, `count_data_rows` have no substantial difference from `Imports::CsvImporterService` beyond the model name (`ImportSpi` instead of `Import`) and table name (`imports_spi` instead of `imports`) — see `CodeGuide/Imports/csv_importer_service.md` for the full detail on each.*
