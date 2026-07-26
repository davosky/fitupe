# `Statistics::ZoningPeriodScope`

**File:** `app/services/statistics/zoning_period_scope.rb`

## Codice completo

```ruby
module Statistics
  # Risolve lo scope di Import per un azzonamento/anno/mese. Se l'azzonamento
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
      exact_scope = Import.where(azzonamento_di_riferimento_id: @zoning.id, anno_di_riferimento: @anno,
        mese_di_riferimento: @mese)
      return exact_scope if exact_scope.exists?

      regional_scope
    end

    private

    def regional_scope
      return Import.none if regional_zoning_id.nil?

      Import.where(azzonamento_di_riferimento_id: regional_zoning_id, anno_di_riferimento: @anno,
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
# Risolve lo scope di Import per un azzonamento/anno/mese. Se l'azzonamento
# scelto (es. "GB") non ha importazioni dirette, ricade sui dati importati
# sotto l'azzonamento superiore (es. "G") filtrati per
# codice_azzonamento_completo.
class ZoningPeriodScope
```

> **IT:** Questa è la classe più critica di tutta la feature Statistiche: ogni altro servizio di breakdown delega a questa la selezione delle righe `Import` da considerare. Risolve un problema reale dei dati: un azzonamento regionale (es. "G" = FVG) spesso non ha importazioni dirette, perché i dati arrivano sotto gli azzonamenti provinciali figli (es. "GA", "GB", ...).
>
> *EN: This is the single most critical class in the whole Statistics feature — every other breakdown service delegates the selection of `Import` rows to it. It solves a real data problem: a regional zoning (e.g. "G" = FVG) often has no direct imports, because the data arrives under its provincial child zonings (e.g. "GA", "GB", ...).*

### `def self.call(...)`

```ruby
def self.call(...) = new(...).call
```

> **IT:** Scorciatoia standard usata da tutti i servizi di questa cartella: permette di scrivere `ZoningPeriodScope.call(zoning:, anno:, mese:)` senza dover istanziare esplicitamente l'oggetto. Il `...` (forwarding di argomenti, Ruby 3.x) inoltra tutti gli argomenti così come arrivano a `initialize` e poi a `call`.
>
> *EN: The standard shortcut used by every service in this folder: it lets callers write `ZoningPeriodScope.call(zoning:, anno:, mese:)` without explicitly instantiating the object. The `...` (argument forwarding, Ruby 3.x) passes every argument straight through to `initialize` and then to `call`.*

### `initialize`

```ruby
def initialize(zoning:, anno:, mese:)
  @zoning = zoning
  @anno = anno
  @mese = mese
end
```

> **IT:** Riceve i tre parametri che identificano univocamente "quale fetta di dati" osservare: l'oggetto `Zoning` (non l'id), l'anno come stringa a 4 cifre, il mese come stringa (es. "Aprile"). Nessuna validazione qui: si presume che il chiamante (il form o un altro servizio) li abbia già validati.
>
> *EN: Receives the three parameters that uniquely identify "which slice of data" to look at: the `Zoning` object (not its id), the year as a 4-digit string, the month as a string (e.g. "Aprile"). No validation happens here: the caller (the form, or another service) is assumed to have already validated them.*

### `call`

```ruby
def call
  exact_scope = Import.where(azzonamento_di_riferimento_id: @zoning.id, anno_di_riferimento: @anno,
    mese_di_riferimento: @mese)
  return exact_scope if exact_scope.exists?

  regional_scope
end
```

> **IT:** Il cuore del fallback. Prova prima la corrispondenza esatta: import registrati direttamente sotto l'azzonamento scelto per quell'anno/mese. Se ne esiste almeno uno (`exists?`, non `any?`, per evitare di caricare i record solo per contarli), lo scope esatto viene restituito così com'è — una `ActiveRecord::Relation`, non un array, quindi resta lazy e componibile con ulteriori `.where` da parte dei servizi che lo chiamano. Solo se lo scope esatto è vuoto si tenta il fallback regionale.
>
> *EN: The heart of the fallback. It first tries the exact match: imports registered directly under the chosen zoning for that year/month. If at least one exists (`exists?`, not `any?`, to avoid loading records just to count them), the exact scope is returned as-is — an `ActiveRecord::Relation`, not an array, so it stays lazy and composable with further `.where` calls from the services that consume it. Only when the exact scope is empty does it attempt the regional fallback.*

### `regional_scope` *(privato)*

```ruby
def regional_scope
  return Import.none if regional_zoning_id.nil?

  Import.where(azzonamento_di_riferimento_id: regional_zoning_id, anno_di_riferimento: @anno,
    mese_di_riferimento: @mese).where("codice_azzonamento_completo LIKE ?", "#{@zoning.codice_azzonamento}%")
end
```

> **IT:** Se l'azzonamento scelto non ha un padre regionale identificabile (`regional_zoning_id` nullo), restituisce `Import.none` — uno scope vuoto ma dello stesso tipo `ActiveRecord::Relation`, non `nil` e non un array vuoto, così i chiamanti possono continuare a incatenare `.where`/`.count`/`.group` senza controlli speciali. Altrimenti cerca gli import registrati sotto l'azzonamento regionale padre e li filtra con un `LIKE` sul prefisso del codice azzonamento (es. tutti i codici che iniziano per "GB" dentro i dati importati sotto "G").
>
> *EN: If the chosen zoning has no identifiable regional parent (`regional_zoning_id` is nil), it returns `Import.none` — an empty scope that's still an `ActiveRecord::Relation`, not `nil` and not a plain empty array, so callers can keep chaining `.where`/`.count`/`.group` without special-casing it. Otherwise it looks up imports registered under the parent regional zoning and filters them with a `LIKE` on the zoning-code prefix (e.g. every code starting with "GB" inside the data imported under "G").*

### `regional_zoning_id` *(privato)*

```ruby
def regional_zoning_id
  codice = @zoning.codice_azzonamento
  return nil if codice.blank? || codice.length <= 1

  Zoning.find_by(codice_azzonamento: codice[0])&.id
end
```

> **IT:** Determina l'id dell'azzonamento regionale "padre" a partire dal codice dell'azzonamento scelto. La convenzione di codifica è: un azzonamento regionale ha un codice a **una sola lettera** (es. "G"), un azzonamento provinciale/comprensoriale ha un codice più lungo che inizia con la stessa lettera (es. "GA", "GB"). Se il codice scelto è già di un solo carattere (è già regionale, non ha "padre" più in alto) o è vuoto, restituisce `nil` — da cui il primo `return nil` in `regional_scope`.
>
> *EN: Works out the id of the "parent" regional zoning from the chosen zoning's code. The coding convention is: a regional zoning has a **single-letter** code (e.g. "G"), a provincial/comprensorio zoning has a longer code starting with the same letter (e.g. "GA", "GB"). If the chosen code is already a single character (it's already regional, with no "parent" above it) or blank, it returns `nil` — which is what triggers the early `return nil` in `regional_scope`.*
