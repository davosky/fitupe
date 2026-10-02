# `StatisticWithIntegrations::FilleaCorrection`

**File:** `app/services/statistic_with_integrations/fillea_correction.rb`

## Codice completo

```ruby
module StatisticWithIntegrations
  # Confronta il totale iscritti Cassa Edile (IntegrationFillea, un valore per
  # provincia/anno) con il conteggio SinCGIL dei lavoratori con
  # tipologia_delega "Ordinaria Cassa Edile" nello stesso periodo. La
  # differenza è ciò che va sommato al totale iscritti reale della provincia.
  # Quando lo zoning scelto è regionale, calcola una riga per ciascuna
  # provincia figlia (stesso pattern di Statistics::TotalMembersComparison).
  class FilleaCorrection
    Row = Struct.new(:zoning, :cassa_edile, :sincgil, :diff, keyword_init: true)
    Result = Struct.new(:rows, :total_diff, :error, keyword_init: true) do
      def success? = error.blank?
    end

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
    end

    def call
      return regional_result if @zoning.regionale?

      return missing_result([ @zoning ]) unless dato_presente?(@zoning)

      rows = [ build_row(@zoning) ]
      Result.new(rows:, total_diff: rows.sum(&:diff))
    end

    private

    # A livello regionale non si blocca mai: si integrano le province per cui
    # esiste il dato Cassa Edile e si lasciano invariate (nessuna riga, quindi
    # nessun diff) quelle prive di integrazione.
    def regional_result
      rows = province_zonings.select { |zoning| dato_presente?(zoning) }.map { |zoning| build_row(zoning) }
      Result.new(rows:, total_diff: rows.sum(&:diff))
    end

    def dato_presente?(zoning) = IntegrationFillea.exists?(zoning:, year: @anno)

    def province_zonings = Zoning.comprensori_di(@zoning)

    def build_row(zoning)
      cassa_edile = IntegrationFillea.find_by(zoning:, year: @anno).subscribers_ce
      sincgil = Statistics::ZoningPeriodScope.call(zoning:, anno: @anno, mese: @mese)
        .where(tipologia_delega: Statistics::DelegationTypeBreakdown::TIPOLOGIE.fetch("Ordinaria C.E.")).count

      Row.new(zoning:, cassa_edile:, sincgil:, diff: cassa_edile - sincgil)
    end

    def missing_result(missing)
      Result.new(error: "Non ci sono dati Cassa Edile per il #{@anno} " \
        "nell'azzonamento #{missing.map(&:descrizione_azzonamento).join(', ')}.")
    end
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Confronta il totale iscritti Cassa Edile (IntegrationFillea, un valore per
# provincia/anno) con il conteggio SinCGIL dei lavoratori con
# tipologia_delega "Ordinaria Cassa Edile" nello stesso periodo. La
# differenza è ciò che va sommato al totale iscritti reale della provincia.
# Quando lo zoning scelto è regionale, calcola una riga per ciascuna
# provincia figlia (stesso pattern di Statistics::TotalMembersComparison).
class FilleaCorrection
```

> **IT:** Il meccanismo: i lavoratori edili sono tracciati esternamente dalla Cassa Edile, un archivio autorevole per quel sottoinsieme specifico di iscritti (`tipologia_delega: "Ordinaria Cassa Edile"`). Poiché i lavoratori edili si spostano tra cantieri/province durante l'anno, il conteggio SinCGIL per provincia può sotto- o sovra-stimare quel sottoinsieme in un dato momento — Cassa Edile è considerata la correzione autorevole **solo per quel sottoinsieme specifico**, non per l'intero totale iscritti FILLEA. `IntegrationFillea` ha granularità annuale (un valore per provincia/anno, inserito una volta a inizio anno e tenuto costante), non mensile come `IntegrationFlc` — la prima delle due differenze reali rispetto a `FlcCorrection` (vedi `CodeGuide/StatisticWithIntegrations/flc_correction.md` per l'intera storia di come questa differenza è stata scoperta solo dopo aver assunto per errore che le due integrazioni fossero identiche).
>
> *EN: The mechanism: construction workers are tracked externally by Cassa Edile, an authoritative archive for that specific subset of members (`tipologia_delega: "Ordinaria Cassa Edile"`). Because construction workers move between job sites/provinces during the year, the SinCGIL count per province can under- or over-estimate that subset at any given moment — Cassa Edile is treated as the authoritative correction **only for that specific subset**, not for the entire FILLEA member total. `IntegrationFillea` has yearly granularity (one value per province/year, entered once at the start of the year and held constant), not monthly like `IntegrationFlc` — the first of two real differences from `FlcCorrection` (see `CodeGuide/StatisticWithIntegrations/flc_correction.md` for the full story of how this difference was only discovered after wrongly assuming the two integrations were identical).*

### `Row`, `Result` (Struct)

```ruby
Row = Struct.new(:zoning, :cassa_edile, :sincgil, :diff, keyword_init: true)
Result = Struct.new(:rows, :total_diff, :error, keyword_init: true) do
  def success? = error.blank?
end
```

> **IT:** `Result` non ha campo `comprensori`/`totale` separati come i `Result` di `Statistics::`/`StatisticSpi::` — ha un `rows` (un array, mai una singola riga più un array separato) e un `total_diff` già sommato, perché questa classe non produce direttamente una sezione della dashboard: produce un input intermedio che `TotalMembersComparison` (l'orchestratore di questa cartella, vedi `CodeGuide/StatisticWithIntegrations/total_members_comparison.md`) userà per ricalibrare **altre** sezioni. `total_diff` è la somma di tutti i `diff` di `rows` — quando `@zoning` è provinciale, `rows` ha una sola riga e `total_diff` coincide con quel singolo `diff`; quando è regionale, `total_diff` è la somma delle correzioni di tutte le province con dato disponibile.
>
> *EN: `Result` has no separate `comprensori`/`totale` fields like the `Statistics::`/`StatisticSpi::` `Result`s — it has a `rows` (an array, never a single row plus a separate array) and an already-summed `total_diff`, because this class doesn't directly produce a dashboard section: it produces an intermediate input that `TotalMembersComparison` (this folder's orchestrator, see `CodeGuide/StatisticWithIntegrations/total_members_comparison.md`) will use to recalibrate **other** sections. `total_diff` is the sum of every `diff` in `rows` — when `@zoning` is provincial, `rows` has one row and `total_diff` equals that single `diff`; when it's regional, `total_diff` is the sum of every province's correction where data is available.*

### `call`, `regional_result` — due politiche diverse per i dati mancanti

```ruby
def call
  return regional_result if @zoning.regionale?

  return missing_result([ @zoning ]) unless dato_presente?(@zoning)

  rows = [ build_row(@zoning) ]
  Result.new(rows:, total_diff: rows.sum(&:diff))
end

private

# A livello regionale non si blocca mai: si integrano le province per cui
# esiste il dato Cassa Edile e si lasciano invariate (nessuna riga, quindi
# nessun diff) quelle prive di integrazione.
def regional_result
  rows = province_zonings.select { |zoning| dato_presente?(zoning) }.map { |zoning| build_row(zoning) }
  Result.new(rows:, total_diff: rows.sum(&:diff))
end
```

> **IT:** Una decisione di business esplicitamente diversa a seconda del livello di azzonamento, confermata con l'utente (vedi memoria di progetto): a livello **provinciale**, l'assenza del dato Cassa Edile blocca l'intera pagina con un errore (`missing_result`) — lo stesso principio "fallisci in modo visibile" di `Statistics::TotalMembersComparison` per i dati SinCGIL mancanti. A livello **regionale**, invece, non si blocca mai: le province senza dato Cassa Edile vengono semplicemente **escluse** da `rows` (`select { |zoning| dato_presente?(zoning) }`), non generano un errore né una riga con diff zero — restano "invariate", cioè non ricalibrate affatto, mentre le altre province della stessa regione vengono comunque corrette. Questa asimmetria non è un'incoerenza: riflette il fatto che a livello regionale l'utente vuole vedere l'intero quadro anche se l'integrazione non copre ancora tutte le province, mentre a livello provinciale l'assenza del dato per *quella specifica* provincia richiesta è considerata un errore operativo da segnalare.
>
> *EN: An explicitly different business decision depending on the zoning level, confirmed with the user (see project memory): at the **provincial** level, missing Cassa Edile data blocks the entire page with an error (`missing_result`) — the same "fail visibly" principle as `Statistics::TotalMembersComparison` for missing SinCGIL data. At the **regional** level, it never blocks: provinces with no Cassa Edile data are simply **excluded** from `rows` (`select { |zoning| dato_presente?(zoning) }`), they don't produce an error or a zero-diff row — they stay "unaltered," i.e. not recalibrated at all, while the region's other provinces still get corrected. This asymmetry isn't an inconsistency: it reflects the fact that at the regional level the user wants to see the whole picture even if the integration doesn't yet cover every province, while at the provincial level the absence of data for *that specific* requested province is treated as an operational error worth flagging.*

### `dato_presente?`, `regionale?`, `province_zonings` *(privati)*

```ruby
def dato_presente?(zoning) = IntegrationFillea.exists?(zoning:, year: @anno)

def province_zonings = Zoning.comprensori_di(@zoning)
```

> **IT:** Il test regionale (`@zoning.regionale?`, codice a un solo carattere) e l'elenco dei comprensori (`Zoning.comprensori_di`, `LIKE` sul prefisso escludendo l'azzonamento stesso) vengono dal modello `Zoning`. Fino al 2026-10-02 erano reimplementati identici qui e in `FlcCorrection`; sono stati sostituiti dal codice del modello nell'audit di fine sessione, senza cambiare il comportamento. `dato_presente?` interroga solo per esistenza (`exists?`, non `find_by` seguito da un controllo su `nil`), evitando di caricare il record quando serve solo sapere se c'è.
>
> *EN: The regional test (`@zoning.regionale?`, single-character code) and the comprensori list (`Zoning.comprensori_di`, `LIKE` on the prefix excluding the zoning itself) come from the `Zoning` model. Until 2026-10-02 they were reimplemented identically here and in `FlcCorrection`; the end-of-session audit replaced them with the model's code, with no behavior change. `dato_presente?` only queries for existence (`exists?`, not `find_by` followed by a `nil` check), avoiding loading the record when all that's needed is whether it's there.*

### `build_row` *(privato)*

```ruby
def build_row(zoning)
  cassa_edile = IntegrationFillea.find_by(zoning:, year: @anno).subscribers_ce
  sincgil = Statistics::ZoningPeriodScope.call(zoning:, anno: @anno, mese: @mese)
    .where(tipologia_delega: Statistics::DelegationTypeBreakdown::TIPOLOGIE.fetch("Ordinaria C.E.")).count

  Row.new(zoning:, cassa_edile:, sincgil:, diff: cassa_edile - sincgil)
end
```

> **IT:** Il cuore della formula, e il primo punto in cui questa cartella dipende direttamente da `Statistics::` (non da un proprio scope duplicato): `Statistics::ZoningPeriodScope.call` — lo stesso oggetto usato da ogni breakdown Attivi (vedi `CodeGuide/Statistics/zoning_period_scope.md`) — filtrato per `tipologia_delega` uguale al valore grezzo corrispondente all'etichetta "Ordinaria C.E." in `Statistics::DelegationTypeBreakdown::TIPOLOGIE` (una hash etichetta→valore-grezzo, riusata qui invece di hardcodare di nuovo la stringa esatta del database). `diff: cassa_edile - sincgil` può essere sia positivo (SinCGIL sottostima rispetto a Cassa Edile, servono più iscritti) sia negativo (SinCGIL sovrastima) — nessun `.abs`, il segno è significativo e viene sommato algebricamente al totale iscritti in `TotalMembersComparison`. `IntegrationFillea.find_by(...).subscribers_ce` non ha una guardia esplicita su `nil`: è sicuro solo perché `build_row` viene chiamato esclusivamente dopo che `dato_presente?` ha già confermato l'esistenza del record per quella provincia (in `call` direttamente, o nel `select` di `regional_result`) — un invariante implicito tra i due metodi, non imposto dal type system.
>
> *EN: The heart of the formula, and the first place this folder depends directly on `Statistics::` (not a duplicated scope of its own): `Statistics::ZoningPeriodScope.call` — the same object used by every Attivi breakdown (see `CodeGuide/Statistics/zoning_period_scope.md`) — filtered by `tipologia_delega` matching the raw value corresponding to the "Ordinaria C.E." label in `Statistics::DelegationTypeBreakdown::TIPOLOGIE` (a label→raw-value hash, reused here instead of hardcoding the exact database string again). `diff: cassa_edile - sincgil` can be either positive (SinCGIL undercounts relative to Cassa Edile, more members are needed) or negative (SinCGIL overcounts) — no `.abs`, the sign is meaningful and gets added algebraically to the member total in `TotalMembersComparison`. `IntegrationFillea.find_by(...).subscribers_ce` has no explicit `nil` guard: it's only safe because `build_row` is called exclusively after `dato_presente?` has already confirmed the record exists for that province (either directly in `call`, or in `regional_result`'s `select`) — an implicit invariant between the two methods, not enforced by the type system.*

### `missing_result` *(privato)*

```ruby
def missing_result(missing)
  Result.new(error: "Non ci sono dati Cassa Edile per il #{@anno} " \
    "nell'azzonamento #{missing.map(&:descrizione_azzonamento).join(', ')}.")
end
```

> **IT:** Accetta un array (`missing`), anche se questa classe lo chiama sempre con un singolo elemento (`[@zoning]`) — la firma è più generica di quanto serva oggi. La ragione più probabile: rispecchiare la firma equivalente in `FlcCorrection#missing_result` (identica) per coerenza tra le due classi gemelle, anche se nessuna delle due sfrutta davvero la genericità dell'array a livello provinciale (solo `regional_result` avrebbe potuto produrre più azzonamenti mancanti insieme, ma quel ramo non chiama mai `missing_result`, dato che a livello regionale non si blocca mai — vedi sopra).
>
> *EN: Accepts an array (`missing`), even though this class always calls it with a single element (`[@zoning]`) — the signature is more general than currently needed. The most likely reason: mirroring the equivalent signature in `FlcCorrection#missing_result` (identical) for consistency between the two twin classes, even though neither actually exploits the array's generality at the provincial level (only `regional_result` could have produced multiple missing zonings together, but that branch never calls `missing_result`, since it never blocks at the regional level — see above).*
