# `Statistics::DelegationTypeBreakdown`

**File:** `app/services/statistics/delegation_type_breakdown.rb`

## Codice completo

```ruby
module Statistics
  # Una riga per ciascuna tipologia di delega (Ordinaria, Ordinaria C.E.,
  # NASPI, DS Agricola, Delega Tesoro, Concomitante), più la riga speciale
  # "Conc. SPI Anno" basata sulla colonna concomitante_spi_anno anziché su
  # tipologia_delega. Riusa lo stesso fallback sull'azzonamento superiore di
  # ZoningPeriodScope.
  class DelegationTypeBreakdown
    TIPOLOGIE = {
      "Ordinaria" => "Ordinaria",
      "Ordinaria C.E." => "Ordinaria Cassa Edile",
      "NASPI" => "NASPI",
      "DS Agricola" => "DS Agricola",
      "Delega Tesoro" => "Delega Tesoro",
      "Concomitante" => "Concomitante"
    }.freeze

    CONC_SPI_ANNO = "Conc. SPI Anno".freeze

    Row = Struct.new(:tipologia, :count_anno, :count_precedente, :diff, :diff_percent, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, anno_precedente:, mese:)
      @zoning = zoning
      @anno = anno
      @anno_precedente = anno_precedente
      @mese = mese
    end

    def call
      righe = TIPOLOGIE.map { |tipologia, valore| build_row(tipologia) { |scope| scope.where(tipologia_delega: valore) } }
      righe + [ build_row(CONC_SPI_ANNO) { |scope| scope.where(concomitante_spi_anno: "SI") } ]
    end

    private

    def build_row(tipologia, &scope_filter)
      count_anno = count_for(@anno, &scope_filter)
      count_precedente = count_for(@anno_precedente, &scope_filter)
      diff = count_anno - count_precedente
      diff_percent = count_precedente.zero? ? nil : (diff.to_f / count_precedente * 100)

      Row.new(tipologia:, count_anno:, count_precedente:, diff:, diff_percent:)
    end

    def count_for(anno, &scope_filter)
      scope = ZoningPeriodScope.call(zoning: @zoning, anno:, mese: @mese)
      scope_filter.call(scope).count
    end
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Una riga per ciascuna tipologia di delega (Ordinaria, Ordinaria C.E.,
# NASPI, DS Agricola, Delega Tesoro, Concomitante), più la riga speciale
# "Conc. SPI Anno" basata sulla colonna concomitante_spi_anno anziché su
# tipologia_delega. Riusa lo stesso fallback sull'azzonamento superiore di
# ZoningPeriodScope.
class DelegationTypeBreakdown
```

> **IT:** L'unico breakdown della cartella dove **una delle righe non usa lo stesso campo delle altre**: sei righe filtrano su `tipologia_delega`, ma la settima ("Conc. SPI Anno") filtra su una colonna completamente diversa, `concomitante_spi_anno`. Il design del metodo `build_row`/`count_for` con un blocco (`&scope_filter`) esiste proprio per accomodare questa eccezione senza duplicare la logica di conteggio anno su anno.
>
> *EN: The only breakdown in this folder where **one of the rows doesn't use the same field as the others**: six rows filter on `tipologia_delega`, but the seventh ("Conc. SPI Anno") filters on a completely different column, `concomitante_spi_anno`. The `build_row`/`count_for` design with a block (`&scope_filter`) exists precisely to accommodate this exception without duplicating the year-over-year counting logic.*

### `TIPOLOGIE` (costante)

```ruby
TIPOLOGIE = {
  "Ordinaria" => "Ordinaria",
  "Ordinaria C.E." => "Ordinaria Cassa Edile",
  "NASPI" => "NASPI",
  "DS Agricola" => "DS Agricola",
  "Delega Tesoro" => "Delega Tesoro",
  "Concomitante" => "Concomitante"
}.freeze
```

> **IT:** Mappa "etichetta mostrata in tabella/grafico" → "valore esatto memorizzato in `tipologia_delega`". Le due stringhe non coincidono sempre: "Ordinaria C.E." è l'etichetta breve mostrata, ma il valore reale nella colonna è "Ordinaria Cassa Edile". L'ordine delle chiavi dell'hash determina anche l'ordine delle prime sei righe (i `Hash` in Ruby mantengono l'ordine di inserimento).
>
> *EN: A map from "label shown in the table/chart" to "exact value stored in `tipologia_delega`". The two strings don't always match: "Ordinaria C.E." is the short label shown, but the actual value in the column is "Ordinaria Cassa Edile". The hash's key order also determines the order of the first six rows (Ruby `Hash`es preserve insertion order).*

### `CONC_SPI_ANNO` (costante)

```ruby
CONC_SPI_ANNO = "Conc. SPI Anno".freeze
```

> **IT:** L'etichetta della settima riga "speciale", tenuta separata da `TIPOLOGIE` proprio perché segue una logica di filtro diversa (vedi `call`).
>
> *EN: The label for the seventh "special" row, kept separate from `TIPOLOGIE` precisely because it follows a different filtering logic (see `call`).*

### `Row` (Struct)

```ruby
Row = Struct.new(:tipologia, :count_anno, :count_precedente, :diff, :diff_percent, keyword_init: true)
```

> **IT:** Forma "confronto anno su anno" standard, identica a `CategoryBreakdown` e `MembershipTypeBreakdown`.
>
> *EN: The standard "year-over-year comparison" shape, identical to `CategoryBreakdown` and `MembershipTypeBreakdown`.*

### `call`

```ruby
def call
  righe = TIPOLOGIE.map { |tipologia, valore| build_row(tipologia) { |scope| scope.where(tipologia_delega: valore) } }
  righe + [ build_row(CONC_SPI_ANNO) { |scope| scope.where(concomitante_spi_anno: "SI") } ]
end
```

> **IT:** Costruisce prima le sei righe "regolari" iterando `TIPOLOGIE`, ciascuna con un blocco che filtra lo scope su `tipologia_delega`; poi aggiunge in coda la settima riga con un blocco diverso, che filtra su `concomitante_spi_anno: "SI"`. `build_row` accetta il filtro come blocco (`{ |scope| ... }`), non come valore statico, così può astrarre "come si conta" senza sapere "su quale colonna si filtra".
>
> *EN: First builds the six "regular" rows by iterating `TIPOLOGIE`, each with a block that filters the scope on `tipologia_delega`; then appends the seventh row with a different block, filtering on `concomitante_spi_anno: "SI"`. `build_row` accepts the filter as a block (`{ |scope| ... }`), not a static value, so it can abstract "how to count" without knowing "which column to filter on".*

### `build_row`, `count_for` *(privati)*

```ruby
def build_row(tipologia, &scope_filter)
  count_anno = count_for(@anno, &scope_filter)
  count_precedente = count_for(@anno_precedente, &scope_filter)
  diff = count_anno - count_precedente
  diff_percent = count_precedente.zero? ? nil : (diff.to_f / count_precedente * 100)

  Row.new(tipologia:, count_anno:, count_precedente:, diff:, diff_percent:)
end

def count_for(anno, &scope_filter)
  scope = ZoningPeriodScope.call(zoning: @zoning, anno:, mese: @mese)
  scope_filter.call(scope).count
end
```

> **IT:** `&scope_filter` cattura il blocco passato a `build_row` e lo inoltra a `count_for`, che a sua volta lo applica (`scope_filter.call(scope)`) allo scope risolto per quell'anno. È l'unico servizio della cartella che usa questo pattern "filtro come blocco" invece di un simbolo/valore statico — necessario qui proprio per la riga eccezionale "Conc. SPI Anno".
>
> *EN: `&scope_filter` captures the block passed to `build_row` and forwards it to `count_for`, which then applies it (`scope_filter.call(scope)`) to the scope resolved for that year. It's the only service in this folder using this "filter as a block" pattern instead of a static symbol/value — needed here precisely because of the exceptional "Conc. SPI Anno" row.*
