# `Statistics::TotalMembersComparison`

**File:** `app/services/statistics/total_members_comparison.rb`

## Codice completo

```ruby
module Statistics
  class TotalMembersComparison
    Result = Struct.new(:zoning, :mese, :anno, :anno_precedente, :count_anno, :count_precedente, :diff,
      :diff_percent, :comprensori, :categorie, :attivi_pensionati, :tipologie_iscrizione, :tipologie_delega,
      :nazionalita, :sesso, :provvisorie_revoche, :status_lavorativo, :fasce_eta, :error, keyword_init: true) do
      def success?
        error.blank?
      end
    end

    Row = Struct.new(:zoning, :count_anno, :count_precedente, :diff, :diff_percent, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
      @anno_precedente = (anno.to_i - 1).to_s
    end

    def call
      missing_years = [ @anno, @anno_precedente ].reject { |anno| period_exists?(@zoning, anno) }
      return missing_data_result(missing_years) if missing_years.any?

      build_result
    end

    private

    def period_exists?(zoning, anno)
      scope_for(zoning, anno).exists?
    end

    def count_for(zoning, anno)
      scope_for(zoning, anno).count
    end

    def scope_for(zoning, anno)
      ZoningPeriodScope.call(zoning:, anno:, mese: @mese)
    end

    def build_result
      row = build_row(@zoning)

      Result.new(zoning: @zoning, mese: @mese, anno: @anno, anno_precedente: @anno_precedente,
        count_anno: row.count_anno, count_precedente: row.count_precedente, diff: row.diff,
        diff_percent: row.diff_percent, comprensori: comprensori, categorie: categorie,
        attivi_pensionati: attivi_pensionati, tipologie_iscrizione: tipologie_iscrizione,
        tipologie_delega: tipologie_delega, nazionalita: nazionalita, sesso: sesso,
        provvisorie_revoche: provvisorie_revoche, status_lavorativo: status_lavorativo, fasce_eta: fasce_eta)
    end

    def build_row(zoning)
      count_anno = count_for(zoning, @anno)
      count_precedente = count_for(zoning, @anno_precedente)
      diff = count_anno - count_precedente
      diff_percent = count_precedente.zero? ? nil : (diff.to_f / count_precedente * 100)

      Row.new(zoning:, count_anno:, count_precedente:, diff:, diff_percent:)
    end

    # Quando l'azzonamento scelto è regionale (codice a lettera singola, es.
    # "G"), aggiunge una riga per ciascuna provincia (es. "GA", "GB", ...).
    def comprensori
      return [] unless regionale?

      province_zonings.map { |zoning| build_row(zoning) }
    end

    def regionale?
      @zoning.codice_azzonamento.to_s.length == 1
    end

    def province_zonings
      Zoning.where("codice_azzonamento LIKE ? AND codice_azzonamento != ?", "#{@zoning.codice_azzonamento}%",
        @zoning.codice_azzonamento).order(:codice_azzonamento)
    end

    def categorie
      CategoryBreakdown.call(zoning: @zoning, anno: @anno, anno_precedente: @anno_precedente, mese: @mese)
    end

    def attivi_pensionati
      EmploymentStatusBreakdown.call(zoning: @zoning, anno: @anno, anno_precedente: @anno_precedente, mese: @mese)
    end

    def tipologie_iscrizione
      MembershipTypeBreakdown.call(zoning: @zoning, anno: @anno, anno_precedente: @anno_precedente, mese: @mese)
    end

    def tipologie_delega
      DelegationTypeBreakdown.call(zoning: @zoning, anno: @anno, anno_precedente: @anno_precedente, mese: @mese)
    end

    def nazionalita
      NationalityBreakdown.call(zoning: @zoning, anno: @anno, mese: @mese)
    end

    def sesso
      GenderBreakdown.call(zoning: @zoning, anno: @anno, mese: @mese)
    end

    def provvisorie_revoche
      ProvisionalRevocationBreakdown.call(zoning: @zoning, anno: @anno, mese: @mese)
    end

    def status_lavorativo
      WorkStatusBreakdown.call(zoning: @zoning, anno: @anno, mese: @mese)
    end

    def fasce_eta
      AgeBreakdown.call(zoning: @zoning, anno: @anno, mese: @mese)
    end

    def missing_data_result(missing_years)
      Result.new(
        zoning: @zoning, mese: @mese, anno: @anno, anno_precedente: @anno_precedente,
        error: "Non ci sono dati per #{@mese} #{missing_years.join(' e ')} " \
               "nell'azzonamento #{@zoning.descrizione_azzonamento}."
      )
    end
  end
end
```

## Sezioni commentate

### Panoramica della classe

> **IT:** Questo è il servizio "orchestratore" dell'intera pagina Statistiche: è l'unico che il controller chiama direttamente. Non contiene quasi nessuna logica di calcolo propria (tranne il conteggio della sezione "Regionale"/"Comprensori"): il suo compito è invocare tutti gli altri servizi `*Breakdown`, uno per sezione, e assemblare i risultati in un unico oggetto `Result` che la vista può leggere.
>
> *EN: This is the "orchestrator" service of the whole Statistics page: it's the only one the controller calls directly. It contains almost no calculation logic of its own (aside from counting the "Regionale"/"Comprensori" section): its job is to invoke every other `*Breakdown` service, one per section, and assemble the results into a single `Result` object the view can read.*

### `Result` (Struct)

```ruby
Result = Struct.new(:zoning, :mese, :anno, :anno_precedente, :count_anno, :count_precedente, :diff,
  :diff_percent, :comprensori, :categorie, :attivi_pensionati, :tipologie_iscrizione, :tipologie_delega,
  :nazionalita, :sesso, :provvisorie_revoche, :status_lavorativo, :fasce_eta, :error, keyword_init: true) do
  def success?
    error.blank?
  end
end
```

> **IT:** L'unico oggetto che la vista `_total_iscritti.html.erb` conosce. Ogni volta che si aggiunge una nuova sezione alla pagina Statistiche, il primo passo è aggiungere qui un nuovo campo (come `:fasce_eta`, l'ultimo aggiunto). Il metodo `success?` è la guardia usata dalla vista per decidere se mostrare le card con i dati oppure l'alert di errore: si basa solo sulla presenza di `error`, non su un controllo esplicito di tutti i campi.
>
> *EN: The only object the `_total_iscritti.html.erb` view knows about. Every time a new section is added to the Statistics page, the first step is adding a new field here (like `:fasce_eta`, the most recently added one). The `success?` method is the guard the view uses to decide whether to render the data cards or the error alert: it relies solely on whether `error` is present, not on an explicit check of every field.*

### `Row` (Struct)

```ruby
Row = Struct.new(:zoning, :count_anno, :count_precedente, :diff, :diff_percent, keyword_init: true)
```

> **IT:** Struttura interna usata solo per la sezione principale "Regionale" e per "Comprensori" (una riga per provincia). Non va confusa con gli struct `Row` interni a ciascun servizio `*Breakdown`, che hanno campi diversi: questo è locale a `TotalMembersComparison`.
>
> *EN: Internal structure used only for the main "Regionale" section and for "Comprensori" (one row per province). It should not be confused with the `Row` structs internal to each `*Breakdown` service, which have different fields: this one is local to `TotalMembersComparison`.*

### `def self.call(...)` / `initialize`

```ruby
def self.call(...) = new(...).call

def initialize(zoning:, anno:, mese:)
  @zoning = zoning
  @anno = anno
  @mese = mese
  @anno_precedente = (anno.to_i - 1).to_s
end
```

> **IT:** Riceve solo l'anno "corrente" scelto dall'utente nel form; l'anno precedente viene derivato automaticamente sottraendo 1 (come stringa, per restare coerente con `anno_di_riferimento` che in `Import` è una colonna stringa, non un intero). Nessun servizio successivo riceve mai un `anno_precedente` diverso da questo calcolo.
>
> *EN: Only receives the "current" year chosen by the user in the form; the previous year is derived automatically by subtracting 1 (as a string, to stay consistent with `anno_di_riferimento`, which in `Import` is a string column, not an integer). No downstream service ever receives an `anno_precedente` different from this computed value.*

### `call`

```ruby
def call
  missing_years = [ @anno, @anno_precedente ].reject { |anno| period_exists?(@zoning, anno) }
  return missing_data_result(missing_years) if missing_years.any?

  build_result
end
```

> **IT:** Prima regola di business dell'intera pagina: se manca l'anno scelto **oppure** l'anno precedente (necessario per i confronti anno su anno), non si prova a calcolare nulla — si restituisce subito un `Result` con solo `error` valorizzato. Questo evita di mostrare grafici con zeri fuorvianti quando in realtà i dati semplicemente non sono stati importati.
>
> *EN: The very first business rule of the whole page: if either the chosen year **or** the previous year (needed for year-over-year comparisons) is missing, nothing is computed — a `Result` with only `error` set is returned right away. This avoids showing misleadingly-empty charts when the data simply hasn't been imported yet.*

### `period_exists?`, `count_for`, `scope_for` *(privati)*

```ruby
def period_exists?(zoning, anno)
  scope_for(zoning, anno).exists?
end

def count_for(zoning, anno)
  scope_for(zoning, anno).count
end

def scope_for(zoning, anno)
  ZoningPeriodScope.call(zoning:, anno:, mese: @mese)
end
```

> **IT:** Tre piccoli metodi di supporto, tutti passanti da `ZoningPeriodScope` (mai una query diretta su `Import`). `scope_for` accetta `zoning` e `anno` come parametri (non usa sempre `@zoning`/`@anno`) perché viene riusato sia per l'azzonamento principale sia, tramite `build_row`, per ciascun comprensorio provinciale.
>
> *EN: Three small support methods, all going through `ZoningPeriodScope` (never a direct query on `Import`). `scope_for` takes `zoning` and `anno` as parameters (it doesn't always use `@zoning`/`@anno`) because it's reused both for the main zoning and, via `build_row`, for each provincial comprensorio.*

### `build_result` *(privato)*

```ruby
def build_result
  row = build_row(@zoning)

  Result.new(zoning: @zoning, mese: @mese, anno: @anno, anno_precedente: @anno_precedente,
    count_anno: row.count_anno, count_precedente: row.count_precedente, diff: row.diff,
    diff_percent: row.diff_percent, comprensori: comprensori, categorie: categorie,
    attivi_pensionati: attivi_pensionati, tipologie_iscrizione: tipologie_iscrizione,
    tipologie_delega: tipologie_delega, nazionalita: nazionalita, sesso: sesso,
    provvisorie_revoche: provvisorie_revoche, status_lavorativo: status_lavorativo, fasce_eta: fasce_eta)
end
```

> **IT:** Il punto di assemblaggio finale: chiama uno per uno tutti i metodi privati che a loro volta chiamano i servizi `*Breakdown` (`comprensori`, `categorie`, `attivi_pensionati`, ...) e costruisce il `Result` completo. È qui che, aggiungendo una sezione, va aggiunta la nuova coppia `nome_sezione: nome_sezione`.
>
> *EN: The final assembly point: it calls, one by one, every private method that in turn calls the `*Breakdown` services (`comprensori`, `categorie`, `attivi_pensionati`, ...) and builds the complete `Result`. This is where, when adding a section, the new `nome_sezione: nome_sezione` pair needs to be added.*

### `build_row` *(privato)*

```ruby
def build_row(zoning)
  count_anno = count_for(zoning, @anno)
  count_precedente = count_for(zoning, @anno_precedente)
  diff = count_anno - count_precedente
  diff_percent = count_precedente.zero? ? nil : (diff.to_f / count_precedente * 100)

  Row.new(zoning:, count_anno:, count_precedente:, diff:, diff_percent:)
end
```

> **IT:** Calcola una riga di confronto anno su anno per un singolo `Zoning` (che sia l'azzonamento principale o uno dei comprensori provinciali). `diff_percent` è `nil`, non `0` o `Infinity`, quando l'anno precedente aveva zero iscritti — questo pattern di "guardia sullo zero" si ripete identico in tutti i servizi `*Breakdown` del progetto.
>
> *EN: Computes a single year-over-year comparison row for one `Zoning` (whether the main zoning or one of the provincial comprensori). `diff_percent` is `nil`, not `0` or `Infinity`, when the previous year had zero members — this "zero guard" pattern repeats identically across every `*Breakdown` service in the project.*

### `comprensori`, `regionale?`, `province_zonings` *(privati)*

```ruby
# Quando l'azzonamento scelto è regionale (codice a lettera singola, es.
# "G"), aggiunge una riga per ciascuna provincia (es. "GA", "GB", ...).
def comprensori
  return [] unless regionale?

  province_zonings.map { |zoning| build_row(zoning) }
end

def regionale?
  @zoning.codice_azzonamento.to_s.length == 1
end

def province_zonings
  Zoning.where("codice_azzonamento LIKE ? AND codice_azzonamento != ?", "#{@zoning.codice_azzonamento}%",
    @zoning.codice_azzonamento).order(:codice_azzonamento)
end
```

> **IT:** Questa è l'unica sezione con logica propria non delegata a un servizio `*Breakdown` dedicato — probabilmente perché è stata la prima sezione costruita, prima che il pattern "un file per sezione" venisse consolidato. `regionale?` usa la stessa convenzione di codifica di `ZoningPeriodScope#regional_zoning_id` (codice a un solo carattere = regionale). Se l'azzonamento scelto **non** è regionale, la sezione Comprensori non appare affatto nella pagina (`[]`, e la vista controlla `.present?`).
>
> *EN: This is the only section with its own logic not delegated to a dedicated `*Breakdown` service — likely because it was the first section built, before the "one file per section" pattern was established. `regionale?` uses the same coding convention as `ZoningPeriodScope#regional_zoning_id` (a single-character code = regional). If the chosen zoning is **not** regional, the Comprensori section doesn't appear on the page at all (`[]`, and the view checks `.present?`).*

### `categorie`, `attivi_pensionati`, `tipologie_iscrizione`, `tipologie_delega`, `nazionalita`, `sesso`, `provvisorie_revoche`, `status_lavorativo`, `fasce_eta` *(privati)*

```ruby
def categorie
  CategoryBreakdown.call(zoning: @zoning, anno: @anno, anno_precedente: @anno_precedente, mese: @mese)
end
# ... uno per ogni servizio *Breakdown
```

> **IT:** Sono tutti metodi di una sola riga, deliberatamente identici nella forma: chiamano il servizio `*Breakdown` corrispondente passandogli `zoning`/`anno`/`mese` (e `anno_precedente` solo per le sezioni con confronto anno su anno). È il punto 3 della "recipe" delle sezioni descritta in `CodeGuide/Statistics/README.md`: aggiungere una nuova sezione significa aggiungere uno di questi metodi, richiamato da `build_result`.
>
> *EN: These are all one-line methods, deliberately identical in shape: they call the matching `*Breakdown` service, passing `zoning`/`anno`/`mese` (and `anno_precedente` only for sections with a year-over-year comparison). This is step 3 of the section "recipe" described in `CodeGuide/Statistics/README.md`: adding a new section means adding one of these methods, called from `build_result`.*

### `missing_data_result` *(privato)*

```ruby
def missing_data_result(missing_years)
  Result.new(
    zoning: @zoning, mese: @mese, anno: @anno, anno_precedente: @anno_precedente,
    error: "Non ci sono dati per #{@mese} #{missing_years.join(' e ')} " \
           "nell'azzonamento #{@zoning.descrizione_azzonamento}."
  )
end
```

> **IT:** Costruisce il `Result` "di errore" restituito da `call` quando mancano dati. Tutti i campi delle sezioni (`comprensori`, `categorie`, ecc.) restano `nil` di default — nessuno di essi viene calcolato, quindi nessuna query aggiuntiva viene eseguita quando i dati mancano. Il messaggio elenca dinamicamente quale/quali anni mancano (potrebbe essere solo l'anno scelto, solo il precedente, o entrambi).
>
> *EN: Builds the "error" `Result` returned by `call` when data is missing. Every section field (`comprensori`, `categorie`, etc.) stays `nil` by default — none of them is computed, so no extra query runs when data is missing. The message dynamically lists which year(s) are missing (it could be just the chosen year, just the previous one, or both).*
