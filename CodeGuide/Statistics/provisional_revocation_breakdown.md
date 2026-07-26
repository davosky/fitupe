# `Statistics::ProvisionalRevocationBreakdown`

**File:** `app/services/statistics/provisional_revocation_breakdown.rb`

## Codice completo

```ruby
module Statistics
  # Conta le pratiche Provvisorie (provvisoria = "SI") e le Revoche
  # (motivo_cessazione_iscrizione = "Revoca") nell'anno corrente, senza
  # confronto con l'anno precedente. Riusa lo stesso fallback
  # sull'azzonamento superiore di ZoningPeriodScope.
  class ProvisionalRevocationBreakdown
    Row = Struct.new(:tipologia, :count, :percentuale, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
    end

    def call
      [
        build_row("Provvisorie", scope.where(provvisoria: "SI").count),
        build_row("Revoche", scope.where(motivo_cessazione_iscrizione: "Revoca").count)
      ]
    end

    private

    def build_row(tipologia, count)
      percentuale = totale_iscritti.zero? ? nil : (count.to_f / totale_iscritti * 100)

      Row.new(tipologia:, count:, percentuale:)
    end

    def totale_iscritti
      @totale_iscritti ||= scope.count
    end

    def scope
      @scope ||= ZoningPeriodScope.call(zoning: @zoning, anno: @anno, mese: @mese)
    end
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Conta le pratiche Provvisorie (provvisoria = "SI") e le Revoche
# (motivo_cessazione_iscrizione = "Revoca") nell'anno corrente, senza
# confronto con l'anno precedente. Riusa lo stesso fallback
# sull'azzonamento superiore di ZoningPeriodScope.
class ProvisionalRevocationBreakdown
```

> **IT:** A differenza di `EmploymentStatusBreakdown`/`MembershipTypeBreakdown`, le due righe qui **non sono complementari**: Provvisorie e Revoche sono due condizioni indipendenti, basate su due colonne diverse (`provvisoria` e `motivo_cessazione_iscrizione`), che possono anche sovrapporsi o non coprire affatto il totale degli iscritti. Non è quindi garantito che "Provvisorie + Revoche = totale iscritti".
>
> *EN: Unlike `EmploymentStatusBreakdown`/`MembershipTypeBreakdown`, the two rows here are **not complementary**: Provvisorie and Revoche are two independent conditions, based on two different columns (`provvisoria` and `motivo_cessazione_iscrizione`), which may even overlap or not cover the total membership at all. So there's no guarantee that "Provvisorie + Revoche = total members".*

### `Row` (Struct)

```ruby
Row = Struct.new(:tipologia, :count, :percentuale, keyword_init: true)
```

> **IT:** Forma "distribuzione a un solo anno" standard, con denominatore `scope.count` (vedi `totale_iscritti` sotto) — come `WorkStatusBreakdown` e `AgeBreakdown`, non come `GenderBreakdown`/`NationalityBreakdown`.
>
> *EN: The standard "single-year distribution" shape, with a `scope.count` denominator (see `totale_iscritti` below) — like `WorkStatusBreakdown` and `AgeBreakdown`, not like `GenderBreakdown`/`NationalityBreakdown`.*

### `call`

```ruby
def call
  [
    build_row("Provvisorie", scope.where(provvisoria: "SI").count),
    build_row("Revoche", scope.where(motivo_cessazione_iscrizione: "Revoca").count)
  ]
end
```

> **IT:** A differenza degli altri breakdown a due righe fisse (`EmploymentStatusBreakdown`, `MembershipTypeBreakdown`), qui non c'è un metodo `count_for` dedicato: le due query sono scritte inline, direttamente su `scope`, perché ciascuna condizione è indipendente e non richiede un ramo `if/else` condiviso.
>
> *EN: Unlike the other fixed-two-row breakdowns (`EmploymentStatusBreakdown`, `MembershipTypeBreakdown`), there's no dedicated `count_for` method here: the two queries are written inline, directly on `scope`, because each condition is independent and doesn't need a shared `if/else` branch.*

### `build_row` *(privato)*

```ruby
def build_row(tipologia, count)
  percentuale = totale_iscritti.zero? ? nil : (count.to_f / totale_iscritti * 100)

  Row.new(tipologia:, count:, percentuale:)
end
```

> **IT:** `count` arriva già calcolato da `call` (come in `WorkStatusBreakdown`), non c'è un hash `counts` da consultare qui perché le righe sono solo due, con query dirette.
>
> *EN: `count` arrives already computed from `call` (like in `WorkStatusBreakdown`), there's no `counts` hash to look up here since there are only two rows, with direct queries.*

### `totale_iscritti`, `scope` *(privati)*

```ruby
def totale_iscritti
  @totale_iscritti ||= scope.count
end

def scope
  @scope ||= ZoningPeriodScope.call(zoning: @zoning, anno: @anno, mese: @mese)
end
```

> **IT:** Il denominatore è il totale iscritti del periodo, non la somma di Provvisorie + Revoche — coerente con la nota sopra sul fatto che le due categorie non sono complementari. Il nome `totale_iscritti` (invece del più corto `totale` usato in `AgeBreakdown`/`WorkStatusBreakdown`) è l'unica differenza stilistica rispetto agli altri breakdown con lo stesso ruolo.
>
> *EN: The denominator is the period's total membership, not the sum of Provvisorie + Revoche — consistent with the note above that the two categories aren't complementary. The name `totale_iscritti` (instead of the shorter `totale` used in `AgeBreakdown`/`WorkStatusBreakdown`) is the only stylistic difference from other breakdowns with the same role.*
