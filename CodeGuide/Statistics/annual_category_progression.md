# `Statistics::AnnualCategoryProgression`

**File:** `app/services/statistics/annual_category_progression.rb`

## Codice completo

```ruby
module Statistics
  # Come AnnualProgression (stessi mesi, controlli e crescita %), ma con una
  # riga per categoria sindacale dell'azzonamento scelto invece che per
  # comprensorio. Le integrazioni si sommano solo alle righe FILLEA e FLC, come
  # in Statistiche Con Integrazioni.
  class AnnualCategoryProgression < AnnualProgression
    CATEGORY_CORRECTIONS = {
      "FILLEA" => StatisticWithIntegrations::FilleaCorrection, "FLC" => StatisticWithIntegrations::FlcCorrection
    }.freeze

    Row = Struct.new(:categoria, :counts, :crescita) { def label = categoria }
    Gap = Struct.new(:categoria, :crescita_precedente, :crescita_anno, :differenza) { def label = categoria }

    private

    def rows(anno)
      (@rows ||= {})[anno] ||= categorie.map do |categoria|
        counts = mesi.map { |mese| counts_by(anno).fetch([ categoria, mese ], 0) + integrazione(categoria, anno, mese) }
        Row.new(categoria:, counts:, crescita: crescita(counts.first, counts.last))
      end
    end

    def gaps
      precedente = rows(@anno_precedente).index_by(&:categoria)
      rows(@anno).map do |row|
        prev = precedente[row.categoria].crescita
        differenza = row.crescita - prev if row.crescita && prev
        Gap.new(categoria: row.categoria, crescita_precedente: prev, crescita_anno: row.crescita, differenza:)
      end
    end

    def categorie
      @categorie ||= [ @anno, @anno_precedente ].flat_map { |anno| counts_by(anno).keys.map(&:first) }.uniq.sort
    end

    # { [categoria, mese] => conteggio } con una sola query per anno. Lo stesso
    # anno può avere mesi importati con "Categoria" e altri con "Categoria
    # Sindacale" (mai entrambe sulla stessa riga): COALESCE le unisce.
    def counts_by(anno)
      (@counts_by ||= {})[anno] ||= scope(@zoning, anno, mesi).where.not(Arel.sql("#{categoria_sql} IS NULL"))
        .group(Arel.sql(categoria_sql), :mese_di_riferimento).count
    end

    def categoria_sql
      Import.column_names.include?("categoria_sindacale") ? "COALESCE(categoria_sindacale, categoria)" : "categoria"
    end

    def integrazione(categoria, anno, mese)
      correction = CATEGORY_CORRECTIONS[categoria]
      return 0 unless correction

      result = correction.call(zoning: @zoning, anno:, mese:)
      result.success? ? result.total_diff : 0
    end
  end
end
```

## Sezioni commentate

### Sottoclasse di `AnnualProgression`

```ruby
class AnnualCategoryProgression < AnnualProgression
  Row = Struct.new(:categoria, :counts, :crescita) { def label = categoria }
  Gap = Struct.new(:categoria, :crescita_precedente, :crescita_anno, :differenza) { def label = categoria }
```

> **IT:** La pagina Progressione Annuale Categorie (`/statistics/progression_categories`) è "la stessa cosa" della Progressione Annuale ma per categoria sindacale: stessi mesi (da Gennaio all'ultimo importato), stessi controlli sui dati mancanti, stessa formula di crescita, stessi messaggi. Per questo è una sottoclasse che eredita `call`, `mesi`, `previous_complete?`, `crescita` ed `error_result` da `AnnualProgression` (vedi `annual_progression.md`) e sovrascrive solo `rows` e `gaps`. `Row`/`Gap` hanno qui `categoria` al posto di `zoning`; entrambe le versioni espongono `label`, che è l'unica cosa che il partial condiviso `_progression_year.html.erb` legge, così la stessa vista serve le due pagine.
>
> *EN: The Annual Category Progression page (`/statistics/progression_categories`) is "the same thing" as Annual Progression but per union category: same months (January through the last imported one), same missing-data checks, same growth formula, same messages. So it is a subclass inheriting `call`, `mesi`, `previous_complete?`, `crescita` and `error_result` from `AnnualProgression` (see `annual_progression.md`) and overriding only `rows` and `gaps`. `Row`/`Gap` carry `categoria` instead of `zoning` here; both versions expose `label`, the only thing the shared `_progression_year.html.erb` partial reads, so one view serves both pages.*

### `counts_by` e `categoria_sql`

```ruby
def counts_by(anno)
  (@counts_by ||= {})[anno] ||= scope(@zoning, anno, mesi).where.not(Arel.sql("#{categoria_sql} IS NULL"))
    .group(Arel.sql(categoria_sql), :mese_di_riferimento).count
end

def categoria_sql
  Import.column_names.include?("categoria_sindacale") ? "COALESCE(categoria_sindacale, categoria)" : "categoria"
end
```

> **IT:** La trappola principale. `CategoryBreakdown` sceglie **una** colonna per scope (`categoria_sindacale` se ha dati, altrimenti `categoria`), il che va bene per un singolo mese; qui però lo scope copre più mesi, e nei dati reali i mesi fino a Giugno 2026 sono stati importati con l'intestazione "Categoria" e quelli da Luglio con "Categoria Sindacale". Con la scelta per-scope tutte le categorie risultavano a zero da Gennaio a Giugno. Verificato sui dati che le due colonne non sono mai valorizzate entrambe sulla stessa riga, `COALESCE` per riga è la generalizzazione esatta. Il frammento SQL è costante (nessun input utente), quindi `Arel.sql` è sicuro. Una sola query raggruppata per (categoria, mese) per anno.
>
> *EN: The main trap. `CategoryBreakdown` picks **one** column per scope (`categoria_sindacale` if it has data, else `categoria`), which is fine for a single month; here the scope spans several months, and in real data months up to June 2026 were imported with the "Categoria" header and months from July with "Categoria Sindacale". With per-scope choice every category came out as zero from January to June. Having verified on the data that both columns are never set on the same row, per-row `COALESCE` is the exact generalization. The SQL fragment is constant (no user input), so `Arel.sql` is safe. One grouped query per (category, month) per year.*

### `integrazione`

```ruby
def integrazione(categoria, anno, mese)
  correction = CATEGORY_CORRECTIONS[categoria]
  return 0 unless correction

  result = correction.call(zoning: @zoning, anno:, mese:)
  result.success? ? result.total_diff : 0
end
```

> **IT:** Come in Statistiche Con Integrazioni (`recalibrate_named` in `CodeGuide/StatisticWithIntegrations/`), la correzione FILLEA va solo sulla riga "FILLEA" e quella FLC solo sulla riga "FLC"; tutte le altre categorie restano col conteggio SinCGIL. Le correzioni vengono chiamate direttamente sull'azzonamento scelto: a livello regionale sommano già le province e non bloccano mai, a livello provinciale un dato mancante vale 0 invece di bloccare (stessa scelta di `AnnualProgression`). Controprova sui dati reali: la somma di tutte le categorie di un mese coincide con il totale corretto della pagina Progressione Annuale (es. FVG Agosto 2026 = 85.670).
>
> *EN: As in Statistics With Integrations (`recalibrate_named` in `CodeGuide/StatisticWithIntegrations/`), the FILLEA correction goes only to the "FILLEA" row and the FLC one only to the "FLC" row; every other category keeps its SinCGIL count. Corrections are called directly on the chosen zoning: at regional level they already sum the provinces and never block, at provincial level missing data counts as 0 instead of blocking (same choice as `AnnualProgression`). Cross-check on real data: the sum of all categories for a month equals the corrected total on the Annual Progression page (e.g. FVG August 2026 = 85,670).*

### `gaps` e `categorie`

```ruby
def categorie
  @categorie ||= [ @anno, @anno_precedente ].flat_map { |anno| counts_by(anno).keys.map(&:first) }.uniq.sort
end
```

> **IT:** Le categorie sono l'unione dei due anni in ordine alfabetico (come in `CategoryBreakdown`), così una categoria presente in un solo anno ha comunque una riga in entrambe le tabelle, con zeri dove manca. A differenza della pagina per comprensori, qui `gaps` include **tutte** le righe: non esiste una riga "totale" da escludere dai grafici. Una categoria con Gennaio a zero ha crescita `nil` e cella vuota.
>
> *EN: Categories are the union of both years in alphabetical order (as in `CategoryBreakdown`), so a category present in only one year still gets a row in both tables, with zeros where missing. Unlike the comprensori page, `gaps` here includes **all** rows: there's no "total" row to exclude from the charts. A category with zero January has `nil` growth and a blank cell.*
