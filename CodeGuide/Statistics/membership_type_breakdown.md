# `Statistics::MembershipTypeBreakdown`

**File:** `app/services/statistics/membership_type_breakdown.rb`

## Codice completo

```ruby
module Statistics
  # Confronta gli iscritti con tipologia "Delega" (tipologia_iscrizione =
  # "Delega") con quelli "BreviManu" (il resto degli iscritti), anno su anno.
  # Riusa lo stesso fallback sull'azzonamento superiore di ZoningPeriodScope.
  class MembershipTypeBreakdown
    DELEGA = "Delega".freeze

    Row = Struct.new(:tipologia, :count_anno, :count_precedente, :diff, :diff_percent, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, anno_precedente:, mese:)
      @zoning = zoning
      @anno = anno
      @anno_precedente = anno_precedente
      @mese = mese
    end

    def call
      [ build_row("Delega", :delega), build_row("BreviManu", :brevi_manu) ]
    end

    private

    def build_row(tipologia, kind)
      count_anno = count_for(@anno, kind)
      count_precedente = count_for(@anno_precedente, kind)
      diff = count_anno - count_precedente
      diff_percent = count_precedente.zero? ? nil : (diff.to_f / count_precedente * 100)

      Row.new(tipologia:, count_anno:, count_precedente:, diff:, diff_percent:)
    end

    def count_for(anno, kind)
      scope = ZoningPeriodScope.call(zoning: @zoning, anno:, mese: @mese)
      delega = scope.where(tipologia_iscrizione: DELEGA).count
      kind == :delega ? delega : scope.count - delega
    end
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Confronta gli iscritti con tipologia "Delega" (tipologia_iscrizione =
# "Delega") con quelli "BreviManu" (il resto degli iscritti), anno su anno.
# Riusa lo stesso fallback sull'azzonamento superiore di ZoningPeriodScope.
class MembershipTypeBreakdown
```

> **IT:** Struttura gemella di `EmploymentStatusBreakdown`: stesso schema "totale meno uno" (qui: Delega vs "tutto il resto", chiamato BreviManu), applicato però a `tipologia_iscrizione` invece che a `categoria`/`categoria_sindacale`. In vista, questa è l'unica sezione **senza grafico**: fu tolto esplicitamente subito dopo la prima versione.
>
> *EN: A twin structure to `EmploymentStatusBreakdown`: the same "total minus one" shape (here: Delega vs "everything else", called BreviManu), applied to `tipologia_iscrizione` instead of `categoria`/`categoria_sindacale`. In the view, this is the only section **without a chart**: it was explicitly removed right after the first version.*

### `DELEGA` (costante)

```ruby
DELEGA = "Delega".freeze
```

> **IT:** Il valore esatto della colonna `tipologia_iscrizione` che identifica un iscritto per delega (contrapposto a "BreviManu", che non è un valore letterale nei dati ma il nome dato in vista a "tutto ciò che non è Delega").
>
> *EN: The exact `tipologia_iscrizione` column value that identifies a member enrolled via "delega". "BreviManu" is not a literal value in the data — it's just the label given in the UI to "everything that isn't Delega".*

### `Row` (Struct)

```ruby
Row = Struct.new(:tipologia, :count_anno, :count_precedente, :diff, :diff_percent, keyword_init: true)
```

> **IT:** Forma "confronto anno su anno" pura (nessun campo `percentuale`), come `CategoryBreakdown` e `DelegationTypeBreakdown` — a differenza del "cugino" `EmploymentStatusBreakdown` che invece è ibrido.
>
> *EN: A pure "year-over-year comparison" shape (no `percentuale` field), like `CategoryBreakdown` and `DelegationTypeBreakdown` — unlike its "cousin" `EmploymentStatusBreakdown`, which is hybrid instead.*

### `call`

```ruby
def call
  [ build_row("Delega", :delega), build_row("BreviManu", :brevi_manu) ]
end
```

> **IT:** Sempre due righe fisse, in quest'ordine. `:delega`/`:brevi_manu` sono simboli di uso puramente interno (non compaiono mai nei dati o nella vista).
>
> *EN: Always two fixed rows, in this order. `:delega`/`:brevi_manu` are purely internal-use symbols (they never appear in the data or in the view).*

### `build_row` *(privato)*

```ruby
def build_row(tipologia, kind)
  count_anno = count_for(@anno, kind)
  count_precedente = count_for(@anno_precedente, kind)
  diff = count_anno - count_precedente
  diff_percent = count_precedente.zero? ? nil : (diff.to_f / count_precedente * 100)

  Row.new(tipologia:, count_anno:, count_precedente:, diff:, diff_percent:)
end
```

> **IT:** Stessa "guardia sullo zero" già vista in `TotalMembersComparison#build_row` e in tutti gli altri breakdown a confronto anno su anno: `diff_percent` è `nil` (non un errore, non `Infinity`) quando l'anno precedente aveva zero iscritti in quel gruppo.
>
> *EN: The same "zero guard" already seen in `TotalMembersComparison#build_row` and every other year-over-year breakdown: `diff_percent` is `nil` (not an error, not `Infinity`) when the previous year had zero members in that group.*

### `count_for` *(privato)*

```ruby
def count_for(anno, kind)
  scope = ZoningPeriodScope.call(zoning: @zoning, anno:, mese: @mese)
  delega = scope.where(tipologia_iscrizione: DELEGA).count
  kind == :delega ? delega : scope.count - delega
end
```

> **IT:** Come in `EmploymentStatusBreakdown`, "BreviManu" non viene mai interrogato direttamente: è sempre `totale - Delega`, per costruzione, così le due righe sommano esattamente al totale del periodo.
>
> *EN: Just like in `EmploymentStatusBreakdown`, "BreviManu" is never queried directly: it's always `total - Delega`, by construction, so the two rows sum exactly to the period's total.*
