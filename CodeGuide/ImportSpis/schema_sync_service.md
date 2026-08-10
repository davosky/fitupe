# `ImportSpis::SchemaSyncService`

**File:** `app/services/import_spis/schema_sync_service.rb`

## Codice completo

```ruby
module ImportSpis
  class SchemaSyncService
    def self.call(headers)
      new(headers).call
    end

    def initialize(headers)
      @columns = headers.compact.map { |header| Imports::HeaderNormalizer.call(header) } - ImportSpi::IGNORED_COLUMNS
    end

    def call
      missing_columns.each { |column| add_column(column) }
      ImportSpi.reset_column_information if missing_columns.any?
    end

    private

    def missing_columns
      @missing_columns ||= @columns - ImportSpi.column_names
    end

    def add_column(column)
      return if ActiveRecord::Base.connection.column_exists?(:imports_spi, column)

      ActiveRecord::Base.connection.add_column(:imports_spi, column, column_type(column))
    end

    def column_type(column)
      return :date if ImportSpi::DATE_COLUMNS.include?(column)
      return :decimal if ImportSpi::DECIMAL_COLUMNS.include?(column)

      :string
    end
  end
end
```

## Sezioni commentate

### La classe intera, a confronto con `Imports::SchemaSyncService`

> **IT:** Stessa identica architettura di `Imports::SchemaSyncService` (vedi `CodeGuide/Imports/schema_sync_service.md` per il ragionamento completo su schema dinamico a runtime, `reset_column_information`, e la doppia guardia `missing_columns`/`column_exists?`): stesso schema dinamico costruito da `ALTER TABLE` a runtime invece che da migration, stessa ragione (il formato dell'export SinCGIL SPI non è sotto controllo del progetto). L'unica vera differenza è `column_type`, che qui distingue **tre** tipi invece di due.
>
> Da notare esplicitamente cosa **non** cambia: `initialize` chiama `Imports::HeaderNormalizer.call`, non una copia locale — il normalizzatore di intestazioni è condiviso tra le due pipeline (vedi `CodeGuide/Imports/README.md`), non duplicato nonostante ImportSpis sia un modulo separato.
>
> *EN: The exact same architecture as `Imports::SchemaSyncService` (see `CodeGuide/Imports/schema_sync_service.md` for the full reasoning on the runtime dynamic schema, `reset_column_information`, and the double `missing_columns`/`column_exists?` guard): the same dynamic schema built by runtime `ALTER TABLE` instead of a migration, for the same reason (the SinCGIL SPI export's format isn't under the project's control). The one real difference is `column_type`, which distinguishes **three** types here instead of two.
>
> Worth noting explicitly what does **not** change: `initialize` calls `Imports::HeaderNormalizer.call`, not a local copy — the header normalizer is shared across both pipelines (see `CodeGuide/Imports/README.md`), not duplicated despite `ImportSpis` being a separate module.*

### `column_type` *(privato)* — la vera differenza rispetto alla versione Attivi

```ruby
def column_type(column)
  return :date if ImportSpi::DATE_COLUMNS.include?(column)
  return :decimal if ImportSpi::DECIMAL_COLUMNS.include?(column)

  :string
end
```

> **IT:** `Imports::SchemaSyncService#add_column` calcola il tipo inline con un ternario a due rami (`:date` o `:string`); qui la stessa decisione è stata estratta in un metodo dedicato con **tre** rami, perché l'export SPI include colonne di importo in euro (es. quota associativa, importo delega) che l'export Attivi non ha — `ImportSpi::DECIMAL_COLUMNS` (definita sul modello, parallela a `DATE_COLUMNS`) elenca quali colonne normalizzate vanno create come `:decimal` invece che `:string`. L'ordine dei due controlli (`:date` prima di `:decimal`) è arbitrario nella pratica — le due liste di colonne non si sovrappongono — ma riflette l'ordine in cui i due tipi sono stati aggiunti al progetto (le date esistevano già nella pipeline Attivi, i decimali sono un'aggiunta specifica di SPI).
>
> *EN: `Imports::SchemaSyncService#add_column` computes the type inline with a two-branch ternary (`:date` or `:string`); here the same decision has been extracted into a dedicated method with **three** branches, because the SPI export includes euro-amount columns (e.g. membership dues, delegation amount) that the Attivi export doesn't have — `ImportSpi::DECIMAL_COLUMNS` (defined on the model, parallel to `DATE_COLUMNS`) lists which normalized columns should be created as `:decimal` instead of `:string`. The order of the two checks (`:date` before `:decimal`) is arbitrary in practice — the two column lists don't overlap — but reflects the order the two types were added to the project in (dates already existed in the Attivi pipeline, decimals are an SPI-specific addition).*
