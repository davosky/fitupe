# `StatisticSpi::TotalMembersComparison`

**File:** `app/services/statistic_spi/total_members_comparison.rb`

## Codice completo

```ruby
module StatisticSpi
  # Come Statistics::TotalMembersComparison ma limitato a Regionale/Comprensori
  # e sdoppiato su due metriche: iscritti (codici fiscali distinti, riconciliati
  # per comprensorio) e deleghe (conteggio record, gia' additivo).
  class TotalMembersComparison
    Result = Struct.new(:zoning, :mese, :anno, :anno_precedente, :iscritti_totale, :iscritti_comprensori,
      :deleghe_totale, :deleghe_comprensori, :deleghe_multiple_totale, :deleghe_multiple_comprensori,
      :tipologie_delega_totale, :tipologie_delega_comprensori, :cessazioni_totale, :cessazioni_comprensori,
      :provvisorie_totale, :provvisorie_comprensori, :error,
      keyword_init: true) do
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
      missing_years = [ @anno, @anno_precedente ].reject { |anno| scope_for(anno).exists? }
      return missing_data_result(missing_years) if missing_years.any?

      build_result
    end

    private

    def scope_for(anno)
      ZoningPeriodScope.call(zoning: @zoning, anno: anno, mese: @mese)
    end

    def build_result
      deleghe_multiple = MultipleDelegationsBreakdown.call(zoning: @zoning, anno: @anno, mese: @mese)
      tipologie_delega = TipologieDelegaBreakdown.call(zoning: @zoning, anno: @anno, mese: @mese)
      cessazioni = CessazioniBreakdown.call(zoning: @zoning, anno: @anno, mese: @mese)
      provvisorie = ProvvisorieBreakdown.call(zoning: @zoning, anno: @anno, mese: @mese)

      Result.new(
        zoning: @zoning, mese: @mese, anno: @anno, anno_precedente: @anno_precedente,
        iscritti_totale: totale_row(:iscritti), iscritti_comprensori: comprensori_rows(:iscritti),
        deleghe_totale: totale_row(:deleghe), deleghe_comprensori: comprensori_rows(:deleghe),
        deleghe_multiple_totale: deleghe_multiple.totale, deleghe_multiple_comprensori: deleghe_multiple.comprensori,
        tipologie_delega_totale: tipologie_delega.totale, tipologie_delega_comprensori: tipologie_delega.comprensori,
        cessazioni_totale: cessazioni.totale, cessazioni_comprensori: cessazioni.comprensori,
        provvisorie_totale: provvisorie.totale, provvisorie_comprensori: provvisorie.comprensori
      )
    end

    def totale_row(metric)
      build_row(@zoning, count_totale(@anno, metric), count_totale(@anno_precedente, metric))
    end

    def comprensori_rows(metric)
      return [] unless @zoning.regionale?

      counts_anno = count_by_comprensorio(@anno, metric)
      counts_precedente = count_by_comprensorio(@anno_precedente, metric)

      Zoning.comprensori_di(@zoning).map do |zoning|
        build_row(zoning, counts_anno[zoning.codice_azzonamento].to_i, counts_precedente[zoning.codice_azzonamento].to_i)
      end
    end

    def count_totale(anno, metric)
      scope = scope_for(anno)
      metric == :iscritti ? scope.distinct.count(:codice_fiscale) : scope.count(:codice_fiscale)
    end

    def count_by_comprensorio(anno, metric)
      scope = scope_for(anno)
      return ReconciledIscrittiByComprensorio.call(scope) if metric == :iscritti

      scope.group("SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2)").count
    end

    def build_row(zoning, count_anno, count_precedente)
      diff = count_anno - count_precedente
      diff_percent = count_precedente.zero? ? nil : (diff.to_f / count_precedente * 100)

      Row.new(zoning:, count_anno:, count_precedente:, diff:, diff_percent:)
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

> **IT:** L'orchestratore della pagina Statistiche SPI, l'equivalente di `Statistics::TotalMembersComparison` (vedi `CodeGuide/Statistics/total_members_comparison.md`) ma con due differenze strutturali importanti: (1) niente sezione "Categorie", "Nazionalità", "Sesso" ecc. — solo Regionale/Comprensori più le quattro sezioni SPI-specifiche (`MultipleDelegationsBreakdown`, `TipologieDelegaBreakdown`, `CessazioniBreakdown`, `ProvvisorieBreakdown`); (2) la sezione principale stessa è sdoppiata in **due metriche indipendenti**, iscritti e deleghe, invece della singola metrica "conteggio" degli Attivi. Questa seconda differenza è la più importante da capire prima di leggere il resto della classe.
>
> *EN: The orchestrator of the SPI Statistics page, the equivalent of `Statistics::TotalMembersComparison` (see `CodeGuide/Statistics/total_members_comparison.md`) but with two important structural differences: (1) no "Categorie", "Nazionalità", "Sesso", etc. sections — just Regionale/Comprensori plus the four SPI-specific sections (`MultipleDelegationsBreakdown`, `TipologieDelegaBreakdown`, `CessazioniBreakdown`, `ProvvisorieBreakdown`); (2) the main section itself is split into **two independent metrics**, iscritti and deleghe, instead of the single "count" metric used for Attivi. This second difference is the most important one to understand before reading the rest of the class.*

### `Result` (Struct)

```ruby
Result = Struct.new(:zoning, :mese, :anno, :anno_precedente, :iscritti_totale, :iscritti_comprensori,
  :deleghe_totale, :deleghe_comprensori, :deleghe_multiple_totale, :deleghe_multiple_comprensori,
  :tipologie_delega_totale, :tipologie_delega_comprensori, :cessazioni_totale, :cessazioni_comprensori,
  :provvisorie_totale, :provvisorie_comprensori, :error,
  keyword_init: true) do
  def success?
    error.blank?
  end
end
```

> **IT:** A differenza di `Statistics::TotalMembersComparison::Result`, non ha un solo campo `count_anno`/`comprensori` per la sezione principale, ma **due coppie parallele**: `iscritti_totale`/`iscritti_comprensori` e `deleghe_totale`/`deleghe_comprensori`. Ogni altra sezione (`deleghe_multiple_*`, `tipologie_delega_*`, `cessazioni_*`, `provvisorie_*`) segue invece il pattern `*_totale`/`*_comprensori` dei `Result` interni dei singoli servizi `*Breakdown` (vedi sotto), non lo `Row` di confronto anno su anno usato per iscritti/deleghe. `success?` funziona esattamente come nella versione Attivi.
>
> *EN: Unlike `Statistics::TotalMembersComparison::Result`, it doesn't have a single `count_anno`/`comprensori` field for the main section, but **two parallel pairs**: `iscritti_totale`/`iscritti_comprensori` and `deleghe_totale`/`deleghe_comprensori`. Every other section (`deleghe_multiple_*`, `tipologie_delega_*`, `cessazioni_*`, `provvisorie_*`) instead follows the `*_totale`/`*_comprensori` pattern of the individual `*Breakdown` services' internal `Result` structs (see below), not the year-over-year comparison `Row` used for iscritti/deleghe. `success?` works exactly as in the Attivi version.*

### `Row` (Struct) / `initialize`

```ruby
Row = Struct.new(:zoning, :count_anno, :count_precedente, :diff, :diff_percent, keyword_init: true)
```

> **IT:** Identico a `Statistics::TotalMembersComparison::Row`, riusato però per **due** metriche (iscritti e deleghe) invece di una — da cui il parametro `metric` in `totale_row`/`comprensori_rows`/`count_totale`/`count_by_comprensorio`. `initialize` è identico riga per riga alla versione Attivi.
>
> *EN: Identical to `Statistics::TotalMembersComparison::Row`, but reused for **two** metrics (iscritti and deleghe) instead of one — hence the `metric` parameter threaded through `totale_row`/`comprensori_rows`/`count_totale`/`count_by_comprensorio`. `initialize` is line-for-line identical to the Attivi version.*

### `call`

```ruby
def call
  missing_years = [ @anno, @anno_precedente ].reject { |anno| scope_for(anno).exists? }
  return missing_data_result(missing_years) if missing_years.any?

  build_result
end
```

> **IT:** Stessa guardia della versione Attivi: se manca l'anno scelto o il precedente, nessun servizio `*Breakdown` viene chiamato, si restituisce subito un `Result` "di errore". Nota che `scope_for` qui usa sempre `@zoning` (l'azzonamento scelto dall'utente), a differenza dei singoli servizi `*Breakdown` SPI che internamente risalgono sempre al padre regionale — questo controllo di esistenza dati è quindi più stretto: verifica i dati per l'azzonamento esatto scelto, non per l'intera regione.
>
> *EN: Same guard as the Attivi version: if the chosen year or the previous one is missing, no `*Breakdown` service gets called, an "error" `Result` is returned immediately. Note that `scope_for` here always uses `@zoning` (the zoning the user chose), unlike the individual SPI `*Breakdown` services which internally always walk up to the regional parent — this existence check is therefore stricter: it verifies data for the exact chosen zoning, not for the whole region.*

### `build_result` *(privato)*

```ruby
def build_result
  deleghe_multiple = MultipleDelegationsBreakdown.call(zoning: @zoning, anno: @anno, mese: @mese)
  tipologie_delega = TipologieDelegaBreakdown.call(zoning: @zoning, anno: @anno, mese: @mese)
  cessazioni = CessazioniBreakdown.call(zoning: @zoning, anno: @anno, mese: @mese)
  provvisorie = ProvvisorieBreakdown.call(zoning: @zoning, anno: @anno, mese: @mese)

  Result.new(
    zoning: @zoning, mese: @mese, anno: @anno, anno_precedente: @anno_precedente,
    iscritti_totale: totale_row(:iscritti), iscritti_comprensori: comprensori_rows(:iscritti),
    deleghe_totale: totale_row(:deleghe), deleghe_comprensori: comprensori_rows(:deleghe),
    deleghe_multiple_totale: deleghe_multiple.totale, deleghe_multiple_comprensori: deleghe_multiple.comprensori,
    tipologie_delega_totale: tipologie_delega.totale, tipologie_delega_comprensori: tipologie_delega.comprensori,
    cessazioni_totale: cessazioni.totale, cessazioni_comprensori: cessazioni.comprensori,
    provvisorie_totale: provvisorie.totale, provvisorie_comprensori: provvisorie.comprensori
  )
end
```

> **IT:** A differenza della versione Attivi, dove ogni servizio `*Breakdown` viene invocato da un metodo privato di una riga (`categorie`, `sesso`, ecc.), qui i quattro servizi SPI-specifici vengono chiamati direttamente dentro `build_result` e il loro `Result` (`.totale`/`.comprensori`) viene spacchettato inline in due campi ciascuno. È una scelta di stile diversa a parità di pattern — nessuna delle due è "più corretta", ma se si aggiunge una nuova sezione SPI conviene seguire questa forma (chiamata diretta dentro `build_result`), non introdurre metodi privati intermedi come negli Attivi, per restare coerenti con le sezioni già presenti in questo file.
>
> *EN: Unlike the Attivi version, where each `*Breakdown` service is invoked through a one-line private method (`categorie`, `sesso`, etc.), here the four SPI-specific services are called directly inside `build_result` and their `Result` (`.totale`/`.comprensori`) is unpacked inline into two fields each. This is a different style choice for the same pattern — neither is "more correct", but when adding a new SPI section it's best to follow this shape (direct call inside `build_result`), not introduce intermediate private methods like in the Attivi version, to stay consistent with the sections already present in this file.*

### `totale_row`, `comprensori_rows` *(privati)*

```ruby
def totale_row(metric)
  build_row(@zoning, count_totale(@anno, metric), count_totale(@anno_precedente, metric))
end

def comprensori_rows(metric)
  return [] unless @zoning.regionale?

  counts_anno = count_by_comprensorio(@anno, metric)
  counts_precedente = count_by_comprensorio(@anno_precedente, metric)

  Zoning.comprensori_di(@zoning).map do |zoning|
    build_row(zoning, counts_anno[zoning.codice_azzonamento].to_i, counts_precedente[zoning.codice_azzonamento].to_i)
  end
end
```

> **IT:** `comprensori_rows` usa `Zoning.comprensori_di(@zoning)` (uno scope del modello `Zoning`, vedi `app/models/zoning.rb`), non una query inline come `Statistics::TotalMembersComparison#province_zonings` — piccola differenza di stile, stesso identico filtro (`codice_azzonamento LIKE "<prefisso>%" AND != "<prefisso>"`). La guardia `return [] unless @zoning.regionale?` usa il metodo `Zoning#regionale?`, non una condizione inline come nella versione Attivi — anche qui, stessa logica (codice a un solo carattere), forma diversa. Entrambi i metodi accettano `metric` (`:iscritti` o `:deleghe`) e lo inoltrano a `count_totale`/`count_by_comprensorio`, dove sta la vera differenza di comportamento tra le due metriche.
>
> *EN: `comprensori_rows` uses `Zoning.comprensori_di(@zoning)` (a scope on the `Zoning` model, see `app/models/zoning.rb`), not an inline query like `Statistics::TotalMembersComparison#province_zonings` — a small style difference, the exact same filter (`codice_azzonamento LIKE "<prefix>%" AND != "<prefix>"`). The guard `return [] unless @zoning.regionale?` uses the `Zoning#regionale?` method, not an inline condition like in the Attivi version — again, same logic (single-character code), different shape. Both methods accept `metric` (`:iscritti` or `:deleghe`) and forward it to `count_totale`/`count_by_comprensorio`, which is where the real behavioral difference between the two metrics lives.*

### `count_totale`, `count_by_comprensorio` *(privati)*

```ruby
def count_totale(anno, metric)
  scope = scope_for(anno)
  metric == :iscritti ? scope.distinct.count(:codice_fiscale) : scope.count(:codice_fiscale)
end

def count_by_comprensorio(anno, metric)
  scope = scope_for(anno)
  return ReconciledIscrittiByComprensorio.call(scope) if metric == :iscritti

  scope.group("SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2)").count
end
```

> **IT:** Il cuore della distinzione iscritti/deleghe, e la parte più facile da rompere per errore in futuro:
>
> - **Deleghe**: `scope.count(:codice_fiscale)` conta le **righe** (ogni riga `ImportSpi` è già una delega, additiva per costruzione — vedi anche il commento di classe di `TipologieDelegaBreakdown`). Per il totale per comprensorio, un semplice `.group(...).count` su `ImportSpi` basta, perché non serve nessuna riconciliazione: sommare i comprensori dà sempre il totale regionale.
> - **Iscritti**: `scope.distinct.count(:codice_fiscale)` conta i **codici fiscali distinti** sull'intera regione — questo è corretto in sé, ma **non è additivo per comprensorio**: se lo stesso approccio (`.distinct.count` raggruppato per comprensorio) venisse applicato comprensorio per comprensorio, una persona con deleghe in due comprensori diversi verrebbe contata due volte nella somma dei comprensori, pur essendo una sola volta nel totale regionale. Per questo `count_by_comprensorio` per `:iscritti` **non** usa `.group(...).distinct.count`, ma delega interamente a `ReconciledIscrittiByComprensorio` (vedi `CodeGuide/StatisticSpi/reconciled_iscritti_by_comprensorio.md`), che garantisce che ogni persona venga assegnata a un solo comprensorio "primario".
>
> Questa asimmetria — `.distinct.count` va bene per il totale ma non per la ripartizione — è il tipo di decisione che, se non documentata, verrebbe "semplificata" per errore da chi in futuro leggesse solo `count_totale` e ne deducesse (a torto) lo stesso pattern per `count_by_comprensorio`.
>
> *EN: The heart of the iscritti/deleghe distinction, and the part most easily broken by mistake in the future:
>
> - **Deleghe**: `scope.count(:codice_fiscale)` counts **rows** (every `ImportSpi` row is already a delegation, additive by construction — see also `TipologieDelegaBreakdown`'s class comment). For the per-comprensorio total, a plain `.group(...).count` on `ImportSpi` is enough, because no reconciliation is needed: summing the comprensori always gives the regional total.
> - **Iscritti**: `scope.distinct.count(:codice_fiscale)` counts **distinct tax codes** across the whole region — correct in itself, but **not additive per comprensorio**: if the same approach (`.distinct.count` grouped by comprensorio) were applied comprensorio by comprensorio, a person with delegations in two different comprensori would be counted twice across the sum, despite counting once in the regional total. That's why `count_by_comprensorio` for `:iscritti` does **not** use `.group(...).distinct.count`, and instead delegates entirely to `ReconciledIscrittiByComprensorio` (see `CodeGuide/StatisticSpi/reconciled_iscritti_by_comprensorio.md`), which guarantees each person is assigned to exactly one "primary" comprensorio.
>
> This asymmetry — `.distinct.count` is fine for the total but not for the breakdown — is the kind of decision that, if left undocumented, would likely get "simplified" by mistake by a future reader who looked only at `count_totale` and (wrongly) assumed the same pattern applies to `count_by_comprensorio`.*

### `build_row`, `missing_data_result` *(privati)*

```ruby
def build_row(zoning, count_anno, count_precedente)
  diff = count_anno - count_precedente
  diff_percent = count_precedente.zero? ? nil : (diff.to_f / count_precedente * 100)

  Row.new(zoning:, count_anno:, count_precedente:, diff:, diff_percent:)
end

def missing_data_result(missing_years)
  Result.new(
    zoning: @zoning, mese: @mese, anno: @anno, anno_precedente: @anno_precedente,
    error: "Non ci sono dati per #{@mese} #{missing_years.join(' e ')} " \
           "nell'azzonamento #{@zoning.descrizione_azzonamento}."
  )
end
```

> **IT:** Entrambi identici, riga per riga, ai metodi omonimi di `Statistics::TotalMembersComparison`: stessa guardia sullo zero in `build_row` (`diff_percent` è `nil`, non `0`/`Infinity`, quando l'anno precedente era zero), stesso messaggio d'errore dinamico in `missing_data_result`. Nessuna variante SPI-specifica qui.
>
> *EN: Both identical, line for line, to the same-named methods in `Statistics::TotalMembersComparison`: same zero guard in `build_row` (`diff_percent` is `nil`, not `0`/`Infinity`, when the previous year was zero), same dynamic error message in `missing_data_result`. No SPI-specific variant here.*
