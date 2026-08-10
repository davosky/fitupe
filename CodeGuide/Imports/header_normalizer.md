# `Imports::HeaderNormalizer`

**File:** `app/services/imports/header_normalizer.rb`

## Codice completo

```ruby
module Imports
  class HeaderNormalizer
    def self.call(header)
      I18n.transliterate(header.to_s).downcase
        .gsub(/[^a-z0-9]+/, "_")
        .gsub(/\A_+|_+\z/, "")
    end
  end
end
```

## Sezioni commentate

### La classe intera

```ruby
def self.call(header)
  I18n.transliterate(header.to_s).downcase
    .gsub(/[^a-z0-9]+/, "_")
    .gsub(/\A_+|_+\z/, "")
end
```

> **IT:** Il pezzo più piccolo, ma più condiviso, dell'intera pipeline di import: trasforma un'intestazione CSV grezza (es. "Codice Fiscale", "Età", "N° Tessera") in uno snake_case sicuro come nome di colonna PostgreSQL (`codice_fiscale`, `eta`, `n_tessera`). `I18n.transliterate` rimuove gli accenti (l'export SinCGIL è in italiano, quindi lettere accentate sono comuni) prima che il resto della pipeline riduca tutto a `[a-z0-9_]`. Le esportazioni SinCGIL non hanno un formato di intestazione fisso tra un file e l'altro (spazi, maiuscole, caratteri speciali come "°" variano), quindi questa normalizzazione è ciò che rende possibile trattare intestazioni sintatticamente diverse come lo stesso nome di colonna — è il singolo punto da cui dipendono sia `SchemaSyncService` (che decide se una colonna esiste già) sia `CsvImporterService` (che costruisce la riga da inserire).
>
> Non è specifica di `Imports`: `IntegrationFlcs::AnagrafeCsvParser` e `ImportSpis::SchemaSyncService`/`ImportSpis::CsvImporterService` la richiamano tutti come `Imports::HeaderNormalizer.call(...)`, mai reimplementata — un dettaglio facile da perdere perché il modulo si chiama `Imports`, non un nome più neutro tipo `Csv`, ma è di fatto condiviso da tre pipeline di import/confronto diverse.
>
> *EN: The smallest but most widely shared piece of the entire import pipeline: it turns a raw CSV header (e.g. "Codice Fiscale", "Età", "N° Tessera") into a safe snake_case PostgreSQL column name (`codice_fiscale`, `eta`, `n_tessera`). `I18n.transliterate` strips accents (the SinCGIL export is in Italian, so accented letters are common) before the rest of the pipeline collapses everything down to `[a-z0-9_]`. SinCGIL exports don't have a fixed header format across files (spacing, casing, special characters like "°" all vary), so this normalization is what makes it possible to treat syntactically different headers as the same column name — it's the single point both `SchemaSyncService` (which decides whether a column already exists) and `CsvImporterService` (which builds the row to insert) depend on.
>
> It isn't specific to `Imports`: `IntegrationFlcs::AnagrafeCsvParser` and `ImportSpis::SchemaSyncService`/`ImportSpis::CsvImporterService` all call it as `Imports::HeaderNormalizer.call(...)`, never reimplemented — an easy detail to miss because the module is named `Imports`, not something more neutral like `Csv`, but it's in fact shared by three different import/comparison pipelines.*

### Perché due `gsub` invece di uno

```ruby
.gsub(/[^a-z0-9]+/, "_")
.gsub(/\A_+|_+\z/, "")
```

> **IT:** Il primo `gsub` collassa qualunque sequenza di caratteri non alfanumerici (spazi, punteggiatura, accenti già rimossi da `transliterate` ma anche simboli come "°", "%", parentesi) in un singolo underscore — mai due underscore consecutivi per due separatori adiacenti. Il secondo `gsub` rimuove gli underscore residui a inizio o fine stringa, che il primo passo lascia quando l'intestazione originale iniziava o finiva con un carattere non alfanumerico (es. "% Iscritti" → `_iscritti` dopo il primo passo, → `iscritti` dopo il secondo). Un singolo `gsub` con un pattern più complesso avrebbe potuto ottenere lo stesso risultato, ma la separazione in due passi espliciti rende ciascuna regex più facile da verificare isolatamente.
>
> *EN: The first `gsub` collapses any run of non-alphanumeric characters (spaces, punctuation, accents already stripped by `transliterate` but also symbols like "°", "%", parentheses) into a single underscore — never two consecutive underscores for two adjacent separators. The second `gsub` removes any leading or trailing underscore left over from the first pass, which happens whenever the original header started or ended with a non-alphanumeric character (e.g. "% Iscritti" → `_iscritti` after the first pass, → `iscritti` after the second). A single `gsub` with a more complex pattern could have achieved the same result, but splitting it into two explicit passes makes each regex easier to verify in isolation.*
