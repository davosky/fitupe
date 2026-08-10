# `IntegrationFlcs::ComparisonService`

**File:** `app/services/integration_flcs/comparison_service.rb`

## Codice completo

```ruby
module IntegrationFlcs
  # Compares an Anagrafe FLC extract against the SinCGIL data already
  # imported (Import) for the same azzonamento/anno/mese, and stores the
  # count of codici fiscali present in Anagrafe FLC but missing from
  # SinCGIL as the corresponding IntegrationFlc record's subscribers_af.
  class ComparisonService
    CATEGORIA_SINDACALE = "FLC"

    Result = Struct.new(:integration_flc, :error, keyword_init: true) do
      def success? = error.nil?
    end

    def self.call(...)
      new(...).call
    end

    def initialize(file:, zoning_id:, year:, month:)
      @file = file
      @zoning_id = zoning_id
      @year = year
      @month = month
    end

    def call
      return Result.new(error: missing_sincgil_message) unless sincgil_import_exists?

      integration_flc = IntegrationFlc.find_or_initialize_by(zoning_id: @zoning_id, year: @year, month: @month)
      integration_flc.subscribers_af = missing_codici_fiscali.size
      integration_flc.save!

      Result.new(integration_flc: integration_flc)
    rescue AnagrafeCsvParser::InvalidFile => e
      Result.new(error: e.message)
    end

    private

    def sincgil_import_exists?
      Import.exists?(azzonamento_di_riferimento_id: candidate_zoning_ids, anno_di_riferimento: @year,
        mese_di_riferimento: @month)
    end

    def missing_sincgil_message
      "Devi prima caricare i dati SinCGIL relativi a questo azzonamento, anno e mese."
    end

    def missing_codici_fiscali
      anagrafe_codici_fiscali - sincgil_codici_fiscali
    end

    def anagrafe_codici_fiscali
      @anagrafe_codici_fiscali ||= AnagrafeCsvParser.call(@file)
    end

    # Scoped by azzonamento_di_riferimento (the batch a human chose when
    # importing, regional or provincial per candidate_zoning_ids) and, within
    # that batch, by the per-record codice_azzonamento_completo actually
    # starting with the selected province/region's own code — a regional
    # batch holds every province's members, so this narrows it back down.
    def sincgil_codici_fiscali
      @sincgil_codici_fiscali ||= period_scope
        .where(categoria_column => CATEGORIA_SINDACALE)
        .where("codice_azzonamento_completo LIKE ?", "#{zoning.codice_azzonamento}%")
        .pluck(:codice_fiscale)
        .filter_map { |codice_fiscale| codice_fiscale&.strip&.upcase.presence }
        .to_set
    end

    def period_scope
      Import.where(azzonamento_di_riferimento_id: candidate_zoning_ids, anno_di_riferimento: @year,
        mese_di_riferimento: @month)
    end

    # The federation sigla has been imported under different column names
    # depending on the exact header text of the SinCGIL export at the time
    # ("Categoria Sindacale" vs "Categoria" — columns get added dynamically
    # per-header by Imports::SchemaSyncService, so both can coexist). Prefer
    # categoria_sindacale when this batch actually has data in it, otherwise
    # fall back to categoria.
    def categoria_column
      @categoria_column ||= if Import.column_names.include?("categoria_sindacale") &&
          period_scope.where.not(categoria_sindacale: nil).exists?
        :categoria_sindacale
      else
        :categoria
      end
    end

    # A SinCGIL export can be extracted at the broader "regionale" level
    # (codice_azzonamento a single letter, e.g. "G") covering every province
    # at once, instead of at the specific "provincia" level (e.g. "GB") the
    # operator selected. Either counts as "the import for this azzonamento".
    def candidate_zoning_ids
      @candidate_zoning_ids ||= [ @zoning_id, regional_zoning_id ].compact.uniq
    end

    def regional_zoning_id
      codice = zoning&.codice_azzonamento
      return nil if codice.blank? || codice.length <= 1

      Zoning.find_by(codice_azzonamento: codice[0])&.id
    end

    def zoning
      @zoning ||= Zoning.find_by(id: @zoning_id)
    end
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Compares an Anagrafe FLC extract against the SinCGIL data already
# imported (Import) for the same azzonamento/anno/mese, and stores the
# count of codici fiscali present in Anagrafe FLC but missing from
# SinCGIL as the corresponding IntegrationFlc record's subscribers_af.
class ComparisonService
```

> **IT:** Attenzione a non confondere questa classe con `StatisticWithIntegrations::FlcCorrection` (vedi `CodeGuide/StatisticWithIntegrations/flc_correction.md`), che ha un nome molto simile ma un ruolo completamente diverso: `ComparisonService` è il passo di **caricamento dati** — l'utente carica un estratto Anagrafe FLC, questa classe lo confronta con SinCGIL e **scrive** `IntegrationFlc#subscribers_af`; `FlcCorrection` è il passo di **lettura/ricalibrazione** — legge lo stesso `subscribers_af` già salvato e lo applica alle statistiche. Le due classi non si chiamano mai a vicenda, comunicano solo attraverso il record `IntegrationFlc` nel database. Il nome della cartella (`IntegrationFlcs`, con la "s" finale — plurale del modello `IntegrationFlc`) segue la convenzione Rails per i service object legati a una risorsa, distinta da `StatisticWithIntegrations` (plurale concettuale, non di un modello).
>
> *EN: Careful not to confuse this class with `StatisticWithIntegrations::FlcCorrection` (see `CodeGuide/StatisticWithIntegrations/flc_correction.md`), which has a very similar name but a completely different role: `ComparisonService` is the **data-loading** step — the user uploads an Anagrafe FLC extract, this class compares it against SinCGIL and **writes** `IntegrationFlc#subscribers_af`; `FlcCorrection` is the **read/recalibration** step — it reads that same already-saved `subscribers_af` and applies it to the statistics. The two classes never call each other, they communicate only through the `IntegrationFlc` record in the database. The folder name (`IntegrationFlcs`, with a trailing "s" — the plural of the `IntegrationFlc` model) follows the Rails convention for resource-bound service objects, distinct from `StatisticWithIntegrations` (a conceptual plural, not a model's).*

### `CATEGORIA_SINDACALE`, `Result` (costante e Struct)

```ruby
CATEGORIA_SINDACALE = "FLC"

Result = Struct.new(:integration_flc, :error, keyword_init: true) do
  def success? = error.nil?
end
```

> **IT:** `Result#success?` qui controlla `error.nil?`, non `error.blank?` come in quasi tutti gli altri `Result` del progetto (`Statistics::TotalMembersComparison`, `StatisticSpi::TotalMembersComparison`, `StatisticWithIntegrations::*Correction`) — una piccola incoerenza stilistica senza conseguenze pratiche nella maggior parte dei casi (una stringa vuota `""` non capita mai come valore di `error` in questa classe), ma che vale la pena notare per chi copia questo pattern altrove: `blank?` tratterebbe anche `""` come "successo", `nil?` no. `CATEGORIA_SINDACALE = "FLC"` è il valore con cui confrontare la colonna categoria di `Import` — coincide (non a caso) con il nome del modulo `IntegrationFlcs`, perché questa integrazione esiste specificamente per la federazione FLC.
>
> *EN: `Result#success?` here checks `error.nil?`, not `error.blank?` like almost every other `Result` in the project (`Statistics::TotalMembersComparison`, `StatisticSpi::TotalMembersComparison`, `StatisticWithIntegrations::*Correction`) — a small stylistic inconsistency with no practical consequence in most cases (an empty string `""` never actually occurs as an `error` value in this class), but worth noting for anyone copying this pattern elsewhere: `blank?` would also treat `""` as "success", `nil?` wouldn't. `CATEGORIA_SINDACALE = "FLC"` is the value to compare the `Import` category column against — it matches (not by coincidence) the `IntegrationFlcs` module's name, because this integration exists specifically for the FLC federation.*

### `call`

```ruby
def call
  return Result.new(error: missing_sincgil_message) unless sincgil_import_exists?

  integration_flc = IntegrationFlc.find_or_initialize_by(zoning_id: @zoning_id, year: @year, month: @month)
  integration_flc.subscribers_af = missing_codici_fiscali.size
  integration_flc.save!

  Result.new(integration_flc: integration_flc)
rescue AnagrafeCsvParser::InvalidFile => e
  Result.new(error: e.message)
end
```

> **IT:** `find_or_initialize_by` (non `find_or_create_by`) seguito da un'assegnazione e un `save!` esplicito: ricaricare lo stesso estratto Anagrafe FLC per lo stesso azzonamento/anno/mese **aggiorna** il record esistente invece di crearne uno duplicato — il caricamento è idempotente per costruzione, coerente con il comportamento `overwrite:` delle pipeline di import SinCGIL (vedi `CodeGuide/Imports/README.md`), anche se qui non c'è un parametro esplicito: l'aggiornamento è sempre implicito. Il `rescue AnagrafeCsvParser::InvalidFile => e` è l'unico punto dell'intera classe che sa dell'esistenza di quell'eccezione — la traduce nel proprio `Result` senza mai propagarla oltre, così il controller non deve mai gestire direttamente le eccezioni del parser. `save!` (con `!`, non `save`) è deliberato: se il salvataggio fallisse per una validazione del modello `IntegrationFlc`, l'eccezione risultante **non** viene catturata qui (solo `AnagrafeCsvParser::InvalidFile` lo è), quindi si propagherebbe fino al controller — un errore di validazione sui dati di questo record è considerato un bug da far notare rumorosamente, non un caso d'uso normale da gestire con un `Result.new(error:)`.
>
> *EN: `find_or_initialize_by` (not `find_or_create_by`) followed by an explicit assignment and `save!`: re-uploading the same Anagrafe FLC extract for the same zoning/year/month **updates** the existing record instead of creating a duplicate — the upload is idempotent by construction, consistent with the `overwrite:` behavior of the SinCGIL import pipelines (see `CodeGuide/Imports/README.md`), even though there's no explicit parameter here: the update is always implicit. `rescue AnagrafeCsvParser::InvalidFile => e` is the only place in the whole class that knows that exception exists — it translates it into its own `Result` without ever letting it propagate further, so the controller never has to handle the parser's exceptions directly. `save!` (with `!`, not `save`) is deliberate: if saving failed due to an `IntegrationFlc` model validation, the resulting exception is **not** caught here (only `AnagrafeCsvParser::InvalidFile` is), so it would propagate up to the controller — a validation error on this record's data is treated as a bug worth surfacing loudly, not a normal use case to handle with a `Result.new(error:)`.*

### `sincgil_import_exists?`, `missing_sincgil_message`, `missing_codici_fiscali`, `anagrafe_codici_fiscali` *(privati)*

```ruby
def sincgil_import_exists?
  Import.exists?(azzonamento_di_riferimento_id: candidate_zoning_ids, anno_di_riferimento: @year,
    mese_di_riferimento: @month)
end

def missing_sincgil_message
  "Devi prima caricare i dati SinCGIL relativi a questo azzonamento, anno e mese."
end

def missing_codici_fiscali
  anagrafe_codici_fiscali - sincgil_codici_fiscali
end

def anagrafe_codici_fiscali
  @anagrafe_codici_fiscali ||= AnagrafeCsvParser.call(@file)
end
```

> **IT:** Regola di business esplicita, controllata **prima** di qualunque parsing del file caricato: il confronto ha senso solo se SinCGIL ha già dati per lo stesso periodo/azzonamento, altrimenti "codici fiscali mancanti da SinCGIL" sarebbe semplicemente "tutti i codici fiscali dell'estratto" — un risultato tecnicamente calcolabile ma privo di significato. Lo stesso principio ("fallisci in modo visibile invece di mostrare un numero fuorviante") già visto in `Statistics::TotalMembersComparison`/`StatisticSpi::TotalMembersComparison` per i dati mancanti. `missing_codici_fiscali` è la vera logica di dominio della classe, ridotta a una singola differenza insiemistica proprio perché `AnagrafeCsvParser` e `sincgil_codici_fiscali` restituiscono entrambi un `Set` con la stessa normalizzazione (maiuscolo, senza spazi) — senza quella normalizzazione condivisa, questa riga produrrebbe falsi negativi (stesso codice fiscale scritto in modo leggermente diverso nelle due fonti, trattato come due valori distinti).
>
> *EN: An explicit business rule, checked **before** any parsing of the uploaded file: the comparison only makes sense if SinCGIL already has data for the same period/zoning, otherwise "codici fiscali missing from SinCGIL" would simply be "every codice fiscale in the extract" — a technically computable but meaningless result. The same principle ("fail visibly instead of showing a misleading number") already seen in `Statistics::TotalMembersComparison`/`StatisticSpi::TotalMembersComparison` for missing data. `missing_codici_fiscali` is the class's actual domain logic, reduced to a single set difference precisely because `AnagrafeCsvParser` and `sincgil_codici_fiscali` both return a `Set` with the same normalization (uppercase, no whitespace) — without that shared normalization, this line would produce false negatives (the same codice fiscale written slightly differently across the two sources, treated as two distinct values).*

### `sincgil_codici_fiscali`, `period_scope` *(privati)*

```ruby
def sincgil_codici_fiscali
  @sincgil_codici_fiscali ||= period_scope
    .where(categoria_column => CATEGORIA_SINDACALE)
    .where("codice_azzonamento_completo LIKE ?", "#{zoning.codice_azzonamento}%")
    .pluck(:codice_fiscale)
    .filter_map { |codice_fiscale| codice_fiscale&.strip&.upcase.presence }
    .to_set
end

def period_scope
  Import.where(azzonamento_di_riferimento_id: candidate_zoning_ids, anno_di_riferimento: @year,
    mese_di_riferimento: @month)
end
```

> **IT:** Come spiega il commento originale, il filtro `codice_azzonamento_completo LIKE "<codice>%"` è il vero restringimento a "solo questa provincia/regione": `period_scope` da solo può includere più province contemporaneamente (quando l'import SinCGIL è stato caricato a livello regionale — vedi `candidate_zoning_ids` sotto), quindi serve un secondo filtro per riportare l'ambito esattamente all'azzonamento scelto dall'utente in questo confronto. `pluck(:codice_fiscale)` esegue una query mirata a una sola colonna (non instanzia oggetti `Import` completi) — appropriato qui perché il risultato può contenere molte migliaia di codici fiscali e l'unica cosa che serve è il valore, non il record. La normalizzazione `filter_map { |codice_fiscale| codice_fiscale&.strip&.upcase.presence }` è identica, carattere per carattere, a quella usata in `AnagrafeCsvParser#call` — non estratta in un metodo condiviso nonostante la duplicazione, probabilmente perché le due classi non condividono altro codice e la duplicazione di tre righe non giustificava un'astrazione dedicata.
>
> *EN: As the original comment explains, the `codice_azzonamento_completo LIKE "<code>%"` filter is the real narrowing down to "just this province/region": `period_scope` alone can include multiple provinces at once (when the SinCGIL import was loaded at the regional level — see `candidate_zoning_ids` below), so a second filter is needed to bring the scope back exactly to the zoning the user chose for this comparison. `pluck(:codice_fiscale)` runs a query targeting a single column (it doesn't instantiate full `Import` objects) — appropriate here because the result can contain many thousands of codici fiscali and the only thing needed is the value, not the record. The `filter_map { |codice_fiscale| codice_fiscale&.strip&.upcase.presence }` normalization is identical, character for character, to the one used in `AnagrafeCsvParser#call` — not extracted into a shared method despite the duplication, likely because the two classes share no other code and duplicating three lines didn't justify a dedicated abstraction.*

### `categoria_column` *(privato)*

```ruby
def categoria_column
  @categoria_column ||= if Import.column_names.include?("categoria_sindacale") &&
      period_scope.where.not(categoria_sindacale: nil).exists?
    :categoria_sindacale
  else
    :categoria
  end
end
```

> **IT:** Una conseguenza diretta dello schema dinamico di `Import` (vedi `CodeGuide/Imports/README.md`): il nome della colonna che contiene la sigla della federazione sindacale non è fisso, perché è nato da un'intestazione CSV il cui testo esatto è cambiato nel tempo negli export SinCGIL ("Categoria Sindacale" in un periodo, "Categoria" in un altro) — e siccome `SchemaSyncService` aggiunge colonne, non le rinomina né le unifica, entrambe possono coesistere nello stesso database per periodi diversi. Il controllo non si limita a verificare che la colonna `categoria_sindacale` esista (`Import.column_names.include?`): controlla anche che **questo specifico batch** (`period_scope`) abbia effettivamente dati non nulli in quella colonna, perché l'esistenza della colonna a livello di schema non garantisce che il periodo interrogato l'abbia usata — un batch caricato prima che quella colonna esistesse avrebbe la colonna (aggiunta più tardi da un altro import) ma tutti i valori `NULL` per le proprie righe. Solo se entrambe le condizioni sono vere si preferisce `:categoria_sindacale`; altrimenti si ricade su `:categoria`, la colonna più vecchia.
>
> *EN: A direct consequence of `Import`'s dynamic schema (see `CodeGuide/Imports/README.md`): the name of the column holding the union federation code isn't fixed, because it was born from a CSV header whose exact text changed over time across SinCGIL exports ("Categoria Sindacale" in one period, "Categoria" in another) — and since `SchemaSyncService` adds columns rather than renaming or unifying them, both can coexist in the same database across different periods. The check doesn't just verify the `categoria_sindacale` column exists (`Import.column_names.include?`): it also checks that **this specific batch** (`period_scope`) actually has non-null data in that column, because the column existing at the schema level doesn't guarantee the queried period used it — a batch loaded before that column existed would have the column (added later by a different import) but all `NULL` values for its own rows. Only when both conditions hold is `:categoria_sindacale` preferred; otherwise it falls back to `:categoria`, the older column.*

### `candidate_zoning_ids`, `regional_zoning_id`, `zoning` *(privati)*

```ruby
def candidate_zoning_ids
  @candidate_zoning_ids ||= [ @zoning_id, regional_zoning_id ].compact.uniq
end

def regional_zoning_id
  codice = zoning&.codice_azzonamento
  return nil if codice.blank? || codice.length <= 1

  Zoning.find_by(codice_azzonamento: codice[0])&.id
end

def zoning
  @zoning ||= Zoning.find_by(id: @zoning_id)
end
```

> **IT:** Nota bene: il verso di questo fallback è **l'opposto** di `Statistics::ZoningPeriodScope`/`StatisticSpi::ZoningPeriodScope`. Lì, dato un azzonamento provinciale scelto, si risale al padre regionale se il provinciale non ha dati diretti. Qui, dato un azzonamento provinciale scelto (`@zoning_id`), si include **anche** l'eventuale import caricato a livello del padre regionale — non come fallback ("prova A, se vuoto prova B"), ma come unione: `candidate_zoning_ids` contiene entrambi gli id contemporaneamente, e `period_scope` interroga `Import` su **entrambi** in una sola query (`azzonamento_di_riferimento_id: candidate_zoning_ids` con un array produce un `IN (...)` SQL). La ragione, spiegata dal commento originale: un operatore può aver caricato l'export SinCGIL a livello regionale (un unico file per tutta la regione, azzonamento "G") anche quando l'azzonamento scelto per *questo* confronto FLC è provinciale ("GB") — senza includere anche l'id regionale tra i candidati, `sincgil_import_exists?`/`sincgil_codici_fiscali` non troverebbero nulla, pur essendoci dati rilevanti. Il filtro `codice_azzonamento_completo LIKE` in `sincgil_codici_fiscali` (vedi sopra) è ciò che poi restringe di nuovo il risultato alla sola provincia "GB", anche quando la query di base ha incluso l'intero batch regionale.
>
> *EN: Note well: the direction of this fallback is the **opposite** of `Statistics::ZoningPeriodScope`/`StatisticSpi::ZoningPeriodScope`. There, given a chosen provincial zoning, it walks up to the regional parent if the province has no direct data. Here, given a chosen provincial zoning (`@zoning_id`), it **also** includes any import loaded at the regional parent level — not as a fallback ("try A, if empty try B"), but as a union: `candidate_zoning_ids` holds both ids at once, and `period_scope` queries `Import` against **both** in a single query (`azzonamento_di_riferimento_id: candidate_zoning_ids` with an array produces a SQL `IN (...)`). The reason, per the original comment: an operator may have loaded the SinCGIL export at the regional level (a single file for the whole region, zoning "G") even when the zoning chosen for *this* FLC comparison is provincial ("GB") — without also including the regional id among the candidates, `sincgil_import_exists?`/`sincgil_codici_fiscali` would find nothing, even though relevant data exists. The `codice_azzonamento_completo LIKE` filter in `sincgil_codici_fiscali` (see above) is what then narrows the result back down to just province "GB", even when the base query included the whole regional batch.*
