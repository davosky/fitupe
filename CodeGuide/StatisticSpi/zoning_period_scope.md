# `StatisticSpi::ZoningPeriodScope`

**File:** `app/services/statistic_spi/zoning_period_scope.rb`

## Codice completo

```ruby
module StatisticSpi
  # Risolve lo scope di ImportSpi per un azzonamento/anno/mese. Se l'azzonamento
  # scelto (es. "GB") non ha importazioni dirette, ricade sui dati importati
  # sotto l'azzonamento superiore (es. "G") filtrati per
  # codice_azzonamento_completo.
  class ZoningPeriodScope
    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
    end

    def call
      exact_scope = ImportSpi.where(azzonamento_di_riferimento_id: @zoning.id, anno_di_riferimento: @anno,
        mese_di_riferimento: @mese)
      return exact_scope if exact_scope.exists?

      regional_scope
    end

    private

    def regional_scope
      return ImportSpi.none if regional_zoning_id.nil?

      ImportSpi.where(azzonamento_di_riferimento_id: regional_zoning_id, anno_di_riferimento: @anno,
        mese_di_riferimento: @mese).where("codice_azzonamento_completo LIKE ?", "#{@zoning.codice_azzonamento}%")
    end

    def regional_zoning_id
      codice = @zoning.codice_azzonamento
      return nil if codice.blank? || codice.length <= 1

      Zoning.find_by(codice_azzonamento: codice[0])&.id
    end
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Risolve lo scope di ImportSpi per un azzonamento/anno/mese. Se l'azzonamento
# scelto (es. "GB") non ha importazioni dirette, ricade sui dati importati
# sotto l'azzonamento superiore (es. "G") filtrati per
# codice_azzonamento_completo.
class ZoningPeriodScope
```

> **IT:** Copia quasi identica, riga per riga, di `Statistics::ZoningPeriodScope` — con `ImportSpi` al posto di `Import`. Non è un caso: quando è iniziata la sezione SPI, il meccanismo di fallback sull'azzonamento regionale (documentato in `CodeGuide/Statistics/zoning_period_scope.md`) era già stato validato sui dati Attivi, quindi è stato riusato senza modifiche invece di essere generalizzato in una classe condivisa. Le due classi restano volutamente separate e indipendenti, una per modello (`Import` vs `ImportSpi`), perché i due flussi di importazione evolvono con tempi propri.
>
> *EN: An almost line-for-line copy of `Statistics::ZoningPeriodScope` — with `ImportSpi` instead of `Import`. That's not an accident: by the time the SPI section started, the regional-zoning fallback mechanism (documented in `CodeGuide/Statistics/zoning_period_scope.md`) had already been validated against the Attivi data, so it was reused unchanged instead of being generalized into a shared class. The two classes are deliberately kept separate and independent, one per model (`Import` vs `ImportSpi`), because the two import pipelines evolve on their own schedules.*

### `def self.call(...)` / `initialize`

```ruby
def self.call(...) = new(...).call

def initialize(zoning:, anno:, mese:)
  @zoning = zoning
  @anno = anno
  @mese = mese
end
```

> **IT:** Stessa firma, stesso contratto di `Statistics::ZoningPeriodScope`: `zoning` è l'oggetto `Zoning` (non l'id), `anno` una stringa a 4 cifre, `mese` una stringa. Ogni servizio `StatisticSpi::*Breakdown` chiama questa classe con gli stessi tre argomenti, mai con parametri aggiuntivi (a differenza, ad esempio, di `MultipleDelegationsBreakdown`, che ha una propria logica di riconciliazione costruita *sopra* lo scope restituito qui, non dentro).
>
> *EN: Same signature, same contract as `Statistics::ZoningPeriodScope`: `zoning` is the `Zoning` object (not its id), `anno` a 4-digit string, `mese` a string. Every `StatisticSpi::*Breakdown` service calls this class with the same three arguments, never extra parameters (unlike, say, `MultipleDelegationsBreakdown`, which has its own reconciliation logic built *on top of* the scope returned here, not inside it).*

### `call`

```ruby
def call
  exact_scope = ImportSpi.where(azzonamento_di_riferimento_id: @zoning.id, anno_di_riferimento: @anno,
    mese_di_riferimento: @mese)
  return exact_scope if exact_scope.exists?

  regional_scope
end
```

> **IT:** Identico nel comportamento alla versione Attivi: prova prima la corrispondenza esatta su `ImportSpi`, e solo se non trova nulla (`exists?`) ricade sul padre regionale. Il tipo di ritorno è sempre una `ActiveRecord::Relation` su `ImportSpi`, mai un array — ogni chiamante successivo (`StatisticSpi::TotalMembersComparison`, i vari `*Breakdown`) continua a incatenarci `.where`, `.group`, `.to_sql` (per costruire le CTE SQL viste in `AgeBreakdown`, `CessazioniBreakdown`, ecc.).
>
> *EN: Identical in behavior to the Attivi version: it tries the exact match on `ImportSpi` first, and only when nothing is found (`exists?`) falls back to the regional parent. The return type is always an `ActiveRecord::Relation` over `ImportSpi`, never an array — every downstream caller (`StatisticSpi::TotalMembersComparison`, the various `*Breakdown` services) keeps chaining `.where`, `.group`, `.to_sql` on it (to build the SQL CTEs seen in `AgeBreakdown`, `CessazioniBreakdown`, etc.).*

### `regional_scope`, `regional_zoning_id` *(privati)*

```ruby
def regional_scope
  return ImportSpi.none if regional_zoning_id.nil?

  ImportSpi.where(azzonamento_di_riferimento_id: regional_zoning_id, anno_di_riferimento: @anno,
    mese_di_riferimento: @mese).where("codice_azzonamento_completo LIKE ?", "#{@zoning.codice_azzonamento}%")
end

def regional_zoning_id
  codice = @zoning.codice_azzonamento
  return nil if codice.blank? || codice.length <= 1

  Zoning.find_by(codice_azzonamento: codice[0])&.id
end
```

> **IT:** Stessa convenzione di codifica di `Statistics::ZoningPeriodScope#regional_zoning_id`: un azzonamento regionale ha un codice a una sola lettera (es. "G"), da cui deriva anche `Zoning#regionale?` (`codice_azzonamento.length == 1`), riusato più volte nei servizi `StatisticSpi::*Breakdown` per decidere se calcolare o meno la sezione "Comprensori". `ImportSpi.none` (non `nil`, non `[]`) mantiene il tipo `ActiveRecord::Relation` anche nel caso limite in cui l'azzonamento scelto non abbia un padre regionale identificabile.
>
> *EN: Same coding convention as `Statistics::ZoningPeriodScope#regional_zoning_id`: a regional zoning has a single-letter code (e.g. "G"), which is also what `Zoning#regionale?` derives from (`codice_azzonamento.length == 1`), reused throughout the `StatisticSpi::*Breakdown` services to decide whether to compute the "Comprensori" section at all. `ImportSpi.none` (not `nil`, not `[]`) keeps the `ActiveRecord::Relation` type even in the edge case where the chosen zoning has no identifiable regional parent.*

### Perché tutti i `*Breakdown` SPI ricalcolano `regional_scope` invece di usare direttamente questa classe

> **IT:** Un dettaglio che si nota solo leggendo più file insieme: ogni servizio `StatisticSpi::*Breakdown` (eccetto questo) ha un proprio metodo privato `regional_scope`/`regional_zoning` che risolve *sempre* l'azzonamento regionale padre (anche quando l'azzonamento scelto è già regionale) e passa quello a `ZoningPeriodScope`, non l'azzonamento originale. È una scelta deliberata: a differenza della pagina Statistiche Attivi (dove ogni sezione mostra solo l'azzonamento scelto), la pagina SPI mostra **sempre** sia il totale regionale sia la ripartizione per comprensorio nella stessa vista, quindi ogni breakdown ha bisogno dell'intero scope regionale in un colpo solo, da cui poi ricava sia il totale (aggregando) sia le righe per comprensorio (raggruppando su `SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2)`). Vedi `CodeGuide/StatisticSpi/README.md` per il dettaglio del pattern "regionale + comprensori" ripetuto in ogni breakdown.
>
> *EN: A detail only visible when reading several files together: every `StatisticSpi::*Breakdown` service (except this one) has its own private `regional_scope`/`regional_zoning` method that *always* resolves the parent regional zoning (even when the chosen zoning is already regional) and passes that to `ZoningPeriodScope`, not the original zoning. This is deliberate: unlike the Attivi Statistics page (where each section shows only the chosen zoning), the SPI page **always** shows both the regional total and the per-comprensorio breakdown on the same view, so every breakdown needs the entire regional scope in one shot, from which it then derives both the total (by aggregating) and the per-comprensorio rows (by grouping on `SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2)`). See `CodeGuide/StatisticSpi/README.md` for the full detail of the "regional + comprensori" pattern repeated in every breakdown.*
