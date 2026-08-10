# `IntegrationFlcs::AnagrafeCsvParser`

**File:** `app/services/integration_flcs/anagrafe_csv_parser.rb`

## Codice completo

```ruby
require "csv"

module IntegrationFlcs
  # Parses an Anagrafe FLC extract into the set of codici fiscali it contains.
  # The exact export format (delimiter, exact header wording) isn't fixed by
  # any known sample, so both are detected rather than assumed.
  class AnagrafeCsvParser
    class InvalidFile < StandardError; end

    def self.call(...)
      new(...).call
    end

    def initialize(file)
      @file = file
    end

    def call
      table = CSV.parse(content, headers: true, col_sep: delimiter, liberal_parsing: true)
      column = codice_fiscale_header(table.headers)

      table.filter_map { |row| row[column]&.strip&.upcase.presence }.to_set
    end

    private

    def content
      @content ||= @file.read.force_encoding("UTF-8").delete_prefix("﻿")
    end

    def delimiter
      first_line = content.each_line.first.to_s
      first_line.count(";") > first_line.count(",") ? ";" : ","
    end

    def codice_fiscale_header(headers)
      headers.find { |header| Imports::HeaderNormalizer.call(header) == "codice_fiscale" } ||
        raise(InvalidFile, "Il file CSV non contiene una colonna Codice Fiscale")
    end
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Parses an Anagrafe FLC extract into the set of codici fiscali it contains.
# The exact export format (delimiter, exact header wording) isn't fixed by
# any known sample, so both are detected rather than assumed.
class AnagrafeCsvParser
```

> **IT:** A differenza di `Imports::CsvImporterService`/`ImportSpis::CsvImporterService`, che possono permettersi di assumere `col_sep: ";"` perché SinCGIL è un export interno con formato noto e stabile, questa classe parsifica un file prodotto da un **sistema esterno diverso** (Anagrafe FLC, non SinCGIL) di cui il progetto non ha mai avuto un campione di riferimento definitivo — il commento di classe lo dice esplicitamente. Ogni scelta di questa classe (rilevare il delimitatore, cercare l'intestazione per contenuto normalizzato invece che per posizione fissa, gestire un BOM UTF-8) è una difesa contro un formato che potrebbe variare in modi che nessun test attuale copre per certo.
>
> *EN: Unlike `Imports::CsvImporterService`/`ImportSpis::CsvImporterService`, which can afford to assume `col_sep: ";"` because SinCGIL is an internal export with a known, stable format, this class parses a file produced by a **different external system** (Anagrafe FLC, not SinCGIL) for which the project has never had a definitive reference sample — the class comment says so explicitly. Every choice in this class (detecting the delimiter, looking up the header by normalized content instead of a fixed position, handling a UTF-8 BOM) is a defense against a format that might vary in ways no current test can be certain it covers.*

### `InvalidFile` (eccezione)

```ruby
class InvalidFile < StandardError; end
```

> **IT:** Un'eccezione custom, non un `Result` con `error:` come in `IntegrationFlcs::ComparisonService` o negli altri servizi del progetto — scelta deliberata perché questa classe è un componente di parsing di basso livello, non un servizio applicativo con un proprio flusso di successo/fallimento. Chi la chiama (`ComparisonService#call`, vedi `CodeGuide/IntegrationFlcs/comparison_service.md`) la cattura esplicitamente con `rescue AnagrafeCsvParser::InvalidFile` e la traduce nel proprio `Result.new(error: ...)` — il confine tra "eccezione Ruby" e "oggetto risultato" è tracciato esattamente al bordo tra questa classe e il suo unico chiamante.
>
> *EN: A custom exception, not a `Result` with `error:` like `IntegrationFlcs::ComparisonService` or the project's other services — a deliberate choice because this class is a low-level parsing component, not an application service with its own success/failure flow. Its caller (`ComparisonService#call`, see `CodeGuide/IntegrationFlcs/comparison_service.md`) explicitly catches it with `rescue AnagrafeCsvParser::InvalidFile` and translates it into its own `Result.new(error: ...)` — the boundary between "Ruby exception" and "result object" is drawn exactly at the edge between this class and its one caller.*

### `call`

```ruby
def call
  table = CSV.parse(content, headers: true, col_sep: delimiter, liberal_parsing: true)
  column = codice_fiscale_header(table.headers)

  table.filter_map { |row| row[column]&.strip&.upcase.presence }.to_set
end
```

> **IT:** Il valore di ritorno è un `Set`, non un `Array` — la classe restituisce **l'insieme** dei codici fiscali presenti nell'estratto Anagrafe FLC, non un elenco ordinato con eventuali duplicati. Questo è coerente con il suo unico uso in `ComparisonService#missing_codici_fiscali`, che fa una differenza insiemistica (`anagrafe_codici_fiscali - sincgil_codici_fiscali`) — un `Set` rende quell'operazione sia più leggibile sia (per grandi volumi) più efficiente di una differenza tra array. `filter_map` scarta in un solo passaggio sia i valori `nil`/vuoti (`.presence` restituisce `nil` per una stringa vuota) sia — implicitamente — normalizza maiuscole e spazi (`&.strip&.upcase`), così un codice fiscale scritto in minuscolo o con spazi accidentali nell'estratto esterno viene confrontato correttamente con l'equivalente maiuscolo/pulito importato da SinCGIL.
>
> *EN: The return value is a `Set`, not an `Array` — the class returns **the set** of codici fiscali present in the Anagrafe FLC extract, not an ordered list with possible duplicates. This is consistent with its one use in `ComparisonService#missing_codici_fiscali`, which does a set difference (`anagrafe_codici_fiscali - sincgil_codici_fiscali`) — a `Set` makes that operation both more readable and (for large volumes) more efficient than an array difference. `filter_map` discards, in a single pass, both `nil`/blank values (`.presence` returns `nil` for an empty string) and — implicitly — normalizes case and whitespace (`&.strip&.upcase`), so a codice fiscale written in lowercase or with stray spaces in the external extract still compares correctly against the uppercase/clean equivalent imported from SinCGIL.*

### `content` *(privato)* — il BOM UTF-8

```ruby
def content
  @content ||= @file.read.force_encoding("UTF-8").delete_prefix("﻿")
end
```

> **IT:** `delete_prefix("﻿")` rimuove il [BOM (Byte Order Mark)](https://it.wikipedia.org/wiki/Byte_order_mark) UTF-8 che alcuni programmi Windows (Excel in particolare, e probabilmente lo strumento con cui l'Anagrafe FLC produce i propri export) anteppongono ai file di testo — un carattere invisibile che, se non rimosso, si concatenerebbe alla prima intestazione del CSV (es. `"﻿Codice Fiscale"` invece di `"Codice Fiscale"`), facendo fallire silenziosamente `codice_fiscale_header` (la ricerca per uguaglianza esatta dopo normalizzazione non troverebbe corrispondenza, perché `Imports::HeaderNormalizer` non rimuove caratteri di controllo Unicode invisibili come il BOM). Nessuna delle due pipeline SinCGIL (`Imports`/`ImportSpis`) ha bisogno di questa difesa, perché i loro export non hanno mai mostrato un BOM — un'altra conseguenza diretta del fatto che questa classe parsifica un formato esterno non standardizzato.
>
> *EN: `delete_prefix("﻿")` removes the UTF-8 [BOM (Byte Order Mark)](https://en.wikipedia.org/wiki/Byte_order_mark) that some Windows programs (Excel in particular, and likely whatever tool Anagrafe FLC uses to produce its exports) prepend to text files — an invisible character that, if not removed, would concatenate onto the CSV's first header (e.g. `"﻿Codice Fiscale"` instead of `"Codice Fiscale"`), silently breaking `codice_fiscale_header` (the exact-match lookup after normalization would find no match, because `Imports::HeaderNormalizer` doesn't strip invisible Unicode control characters like the BOM). Neither SinCGIL pipeline (`Imports`/`ImportSpis`) needs this defense, because their exports have never shown a BOM — another direct consequence of this class parsing an unstandardized external format.*

### `delimiter` *(privato)*

```ruby
def delimiter
  first_line = content.each_line.first.to_s
  first_line.count(";") > first_line.count(",") ? ";" : ","
end
```

> **IT:** Rileva il delimitatore contando le occorrenze di `;` e `,` nella sola prima riga (l'intestazione), invece di assumerlo fisso come fanno `Imports::CsvImporterService`/`ImportSpis::CsvImporterService` con `;` — perché, a differenza di SinCGIL, non esiste un formato di riferimento noto per l'Anagrafe FLC. L'euristica è semplice e non infallibile (un'intestazione con più virgole di punti e virgola per puro caso testuale — improbabile ma non impossibile — produrrebbe un rilevamento sbagliato), ma è sufficiente per i due formati plausibili (CSV standard con virgola, CSV "italiano" con punto e virgola) senza richiedere configurazione manuale da parte dell'utente che carica il file. In caso di parità (nessuna occorrenza di entrambi), il default è `,` (lo standard RFC 4180).
>
> *EN: Detects the delimiter by counting `;` and `,` occurrences in just the first line (the header), instead of assuming it's fixed like `Imports::CsvImporterService`/`ImportSpis::CsvImporterService` do with `;` — because, unlike SinCGIL, there's no known reference format for Anagrafe FLC. The heuristic is simple and not foolproof (a header with more commas than semicolons by pure textual coincidence — unlikely but not impossible — would produce a wrong detection), but it's enough for the two plausible formats (standard comma CSV, "Italian" semicolon CSV) without requiring manual configuration from the user uploading the file. In a tie (no occurrences of either), the default is `,` (the RFC 4180 standard).*

### `codice_fiscale_header` *(privato)*

```ruby
def codice_fiscale_header(headers)
  headers.find { |header| Imports::HeaderNormalizer.call(header) == "codice_fiscale" } ||
    raise(InvalidFile, "Il file CSV non contiene una colonna Codice Fiscale")
end
```

> **IT:** Cerca la colonna per **contenuto normalizzato**, non per nome esatto né per posizione fissa — riusando `Imports::HeaderNormalizer` (lo stesso normalizzatore condiviso da `Imports`/`ImportSpis`, vedi `CodeGuide/Imports/README.md`) per tollerare varianti come "Codice Fiscale", "CODICE_FISCALE", "codice fiscale " con spazi finali, tutte normalizzate a `"codice_fiscale"`. Se nessuna intestazione corrisponde, solleva `InvalidFile` con un messaggio in italiano già pronto per essere mostrato all'utente — non un errore tecnico generico, ma un messaggio che spiega esattamente cosa manca nel file caricato, propagato fino alla UI tramite `ComparisonService`.
>
> *EN: Looks up the column by **normalized content**, not by exact name or fixed position — reusing `Imports::HeaderNormalizer` (the same normalizer shared by `Imports`/`ImportSpis`, see `CodeGuide/Imports/README.md`) to tolerate variants like "Codice Fiscale", "CODICE_FISCALE", "codice fiscale " with trailing spaces, all normalized to `"codice_fiscale"`. If no header matches, it raises `InvalidFile` with an Italian message already suitable for showing to the user — not a generic technical error, but a message explaining exactly what's missing from the uploaded file, propagated all the way to the UI through `ComparisonService`.*
