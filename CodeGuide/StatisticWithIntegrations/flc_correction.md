# `StatisticWithIntegrations::FlcCorrection`

**File:** `app/services/statistic_with_integrations/flc_correction.rb`

## Codice completo

```ruby
module StatisticWithIntegrations
  # L'Anagrafe FLC (IntegrationFlc, un valore per provincia/anno/mese) traccia
  # iscritti FLC aggiuntivi rispetto a quelli già presenti in SinCGIL: il
  # valore va sommato (non confrontato/sottratto) al conteggio SinCGIL della
  # categoria FLC per provincia, e di conseguenza al totale iscritti. Lo
  # stesso importo va riportato anche sulla riga "Delega Tesoro" di
  # Tipologie Delega (dall'orchestratore, non da questa classe).
  #
  # Il dato di un mese si applica alle statistiche dello STESSO mese (es. il
  # record di Luglio integra le statistiche di Luglio): nessuno sfasamento.
  class FlcCorrection
    Row = Struct.new(:zoning, :anagrafe, :diff, keyword_init: true)
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
    # esiste il dato Anagrafe FLC e si lasciano invariate (nessuna riga, quindi
    # nessun diff) quelle prive di integrazione.
    def regional_result
      rows = province_zonings.select { |zoning| dato_presente?(zoning) }.map { |zoning| build_row(zoning) }
      Result.new(rows:, total_diff: rows.sum(&:diff))
    end

    def dato_presente?(zoning) = IntegrationFlc.exists?(zoning:, year: @anno, month: @mese)

    def province_zonings = Zoning.comprensori_di(@zoning)

    def build_row(zoning)
      anagrafe = IntegrationFlc.find_by(zoning:, year: @anno, month: @mese).subscribers_af
      Row.new(zoning:, anagrafe:, diff: anagrafe)
    end

    def missing_result(missing)
      Result.new(error: "Non ci sono dati Anagrafe FLC per #{@mese} #{@anno} in " \
        "#{missing.map(&:descrizione_azzonamento).join(', ')}.")
    end
  end
end
```

## Sezioni commentate

### Commento di classe — la storia dietro il ritardo di un mese

```ruby
# L'Anagrafe FLC (IntegrationFlc, un valore per provincia/anno/mese) traccia
# iscritti FLC aggiuntivi rispetto a quelli già presenti in SinCGIL: il
# valore va sommato (non confrontato/sottratto) al conteggio SinCGIL della
# categoria FLC per provincia, e di conseguenza al totale iscritti. Lo
# stesso importo va riportato anche sulla riga "Delega Tesoro" di
# Tipologie Delega (dall'orchestratore, non da questa classe).
#
# Il dato di un mese si applica alle statistiche del mese SUCCESSIVO (es.
# il record di Maggio integra le statistiche di Giugno), per via del ritardo
# con cui l'Anagrafe FLC rende disponibili i dati.
class FlcCorrection
```

> **IT:** Questa classe è il caso di studio più diretto di [[feedback-fitupe-verify-integration-formula]] (memoria di progetto): descritta inizialmente come "come per FILLEA", è stata implementata per analogia diretta con `FilleaCorrection` (stesso formula di **differenza** contro un sottoinsieme SinCGIL) — la prima versione è stata spedita, i test passavano, un controllo manuale su una provincia sembrava plausibile. Solo confrontando dati reali su tutte e quattro le province FVG è emerso che la formula era gravemente sbagliata: una provincia riceveva una correzione di +435, un'altra di -1790 sulla stessa riga, perché il campo SinCGIL scelto per il confronto ("Delega Tesoro") variava in modo incoerente tra le province, a differenza di "Ordinaria Cassa Edile" che invece tracciava consistentemente il proprio totale esterno ovunque. Il meccanismo reale, scoperto solo dopo: (1) è **pura addizione**, non un confronto/sottrazione — `subscribers_af` si somma direttamente al conteggio SinCGIL, senza sottrarre nulla; (2) ha un **ritardo di un mese** — il dato di Maggio si applica alle statistiche di Giugno, per via del ritardo con cui l'Anagrafe FLC rende disponibili i propri dati. Nessuna delle due caratteristiche è deducibile dal nome della classe o da un confronto superficiale con `FilleaCorrection`: sono la ragione per cui questo file, pur avendo una struttura quasi identica a `FilleaCorrection` a un primo sguardo, calcola in realtà qualcosa di concettualmente diverso.
>
> *EN: This class is the most direct case study behind [[feedback-fitupe-verify-integration-formula]] (project memory): initially described as "just like FILLEA," it was implemented by direct analogy to `FilleaCorrection` (the same **difference** formula against a SinCGIL subset) — the first version shipped, tests passed, a manual check on one province looked plausible. Only comparing real data across all four FVG provinces revealed the formula was badly wrong: one province got a +435 correction, another a -1790 correction on the same row, because the SinCGIL field chosen for comparison ("Delega Tesoro") varied inconsistently across provinces, unlike "Ordinaria Cassa Edile" which consistently tracked its own external total everywhere. The real mechanism, discovered only afterward: (1) it's **pure addition**, not a comparison/subtraction — `subscribers_af` is added directly to the SinCGIL count, nothing gets subtracted; (2) it has a **one-month lag** — May's data applies to June's statistics, due to the delay with which Anagrafe FLC makes its own data available. Neither trait is derivable from the class's name or a superficial comparison with `FilleaCorrection`: they're the reason this file, despite having an almost identical structure to `FilleaCorrection` at first glance, actually computes something conceptually different.*

### `Row` — un campo in meno rispetto a `FilleaCorrection::Row`

```ruby
Row = Struct.new(:zoning, :anagrafe, :diff, keyword_init: true)
```

> **IT:** `FilleaCorrection::Row` ha quattro campi (`zoning`, `cassa_edile`, `sincgil`, `diff`) perché la sua formula confronta due valori; `FlcCorrection::Row` ne ha tre (niente `sincgil`) perché non c'è nessun valore SinCGIL da confrontare — `diff` **è** semplicemente `anagrafe`, un'addizione pura, non il risultato di una sottrazione tra due campi. La differenza nella forma dello `Struct` è la traccia più immediata, leggendo solo questo file, di quanto le due formule siano davvero diverse nonostante il resto della classe sia strutturato in modo quasi identico.
>
> *EN: `FilleaCorrection::Row` has four fields (`zoning`, `cassa_edile`, `sincgil`, `diff`) because its formula compares two values; `FlcCorrection::Row` has three (no `sincgil`) because there's no SinCGIL value to compare against — `diff` simply **is** `anagrafe`, a pure addition, not the result of subtracting two fields. The difference in the `Struct`'s shape is the most immediate trace, reading just this file, of how genuinely different the two formulas are despite the rest of the class being structured almost identically.*

### `call`, `regional_result`, `dato_presente?`, `regionale?`, `province_zonings` — identici a `FilleaCorrection`

> **IT:** Struttura per struttura identici ai metodi omonimi di `FilleaCorrection` (vedi `CodeGuide/StatisticWithIntegrations/fillea_correction.md` per il dettaglio completo): stessa politica "blocca a livello provinciale, integra selettivamente a livello regionale" per i dati mancanti, stesso uso di `Zoning#regionale?`/`Zoning.comprensori_di`. L'unica differenza reale in `dato_presente?` è che interroga `IntegrationFlc` con `year: lookup_year, month: lookup_month` invece di `IntegrationFillea` con `year: @anno` — la granularità mensile e il ritardo di un mese (vedi sotto) si propagano fin qui.
>
> *EN: Structurally identical to `FilleaCorrection`'s same-named methods (see `CodeGuide/StatisticWithIntegrations/fillea_correction.md` for the full detail): the same "block at the provincial level, selectively integrate at the regional level" policy for missing data, the same use of `Zoning#regionale?`/`Zoning.comprensori_di`. The one real difference in `dato_presente?` is that it queries `IntegrationFlc` with `year: lookup_year, month: lookup_month` instead of `IntegrationFillea` with `year: @anno` — the monthly granularity and one-month lag (see below) propagate all the way here.*

### `lookup_month`, `lookup_year` *(privati)* — il ritardo di un mese, in codice

```ruby
def lookup_month
  # indice -1 (Gennaio) restituisce naturalmente "Dicembre" per via
  # dell'indicizzazione negativa di Ruby sugli array
  ImportForm::MESI[ImportForm::MESI.index(@mese) - 1]
end

def lookup_year
  ImportForm::MESI.index(@mese).zero? ? (@anno.to_i - 1).to_s : @anno
end
```

> **IT:** Il cuore tecnico del "ritardo di un mese" descritto nel commento di classe: dato il mese richiesto (`@mese`, es. "Giugno"), `lookup_month` cerca il record `IntegrationFlc` del mese **precedente** ("Maggio"). `ImportForm::MESI.index(@mese) - 1` sfrutta deliberatamente l'indicizzazione negativa degli array Ruby: se `@mese` è "Gennaio" (indice 0), `0 - 1 = -1`, e `array[-1]` restituisce l'**ultimo** elemento dell'array — cioè "Dicembre" — esattamente il comportamento voluto per il rollover di fine anno, ottenuto senza un `if`/`case` esplicito, solo sfruttando una proprietà del linguaggio. Il commento inline lo segnala esplicitamente, probabilmente perché è il tipo di "trucco" che un lettore futuro potrebbe scambiare per un bug (un indice negativo sembra un errore a prima vista) se non gli venisse detto che è intenzionale. `lookup_year`, di conseguenza, deve **anche lui** gestire il rollover: se il mese richiesto è Gennaio (`index.zero?`), il record cercato appartiene all'anno **precedente** (`@anno.to_i - 1`), non allo stesso `@anno` — senza questo aggiustamento, cercare "Dicembre dell'anno corrente" per le statistiche di Gennaio prenderebbe l'anno sbagliato.
>
> *EN: The technical heart of the "one-month lag" described in the class comment: given the requested month (`@mese`, e.g. "Giugno"/June), `lookup_month` looks up the **previous** month's `IntegrationFlc` record ("Maggio"/May). `ImportForm::MESI.index(@mese) - 1` deliberately exploits Ruby array's negative indexing: if `@mese` is "Gennaio"/January (index 0), `0 - 1 = -1`, and `array[-1]` returns the array's **last** element — i.e. "Dicembre"/December — exactly the intended year-rollover behavior, achieved with no explicit `if`/`case`, purely by leaning on a language property. The inline comment calls it out explicitly, likely because it's the kind of "trick" a future reader might mistake for a bug (a negative index looks like an error at first glance) unless told it's intentional. `lookup_year`, as a consequence, must **also** handle the rollover: if the requested month is January (`index.zero?`), the looked-up record belongs to the **previous** year (`@anno.to_i - 1`), not the same `@anno` — without this adjustment, looking up "December of the current year" for January's statistics would grab the wrong year.*

### `build_row` *(privato)* — addizione pura, non differenza

```ruby
def build_row(zoning)
  anagrafe = IntegrationFlc.find_by(zoning:, year: lookup_year, month: lookup_month).subscribers_af
  Row.new(zoning:, anagrafe:, diff: anagrafe)
end
```

> **IT:** La riga che materializza la differenza concettuale con `FilleaCorrection#build_row`: nessuna query su `Statistics::ZoningPeriodScope`, nessun conteggio SinCGIL da confrontare — `diff` è semplicemente `anagrafe` (il valore `subscribers_af` letto direttamente dal record `IntegrationFlc`). Questa classe non ha bisogno di sapere nulla sul contenuto di `Import` per calcolare la propria correzione, a differenza di `FilleaCorrection` che deve interrogare SinCGIL per costruire il confronto. Come in `FilleaCorrection`, `.subscribers_af` non ha una guardia esplicita su `nil` — sicuro solo perché `build_row` viene chiamato esclusivamente dopo che `dato_presente?` ha già confermato l'esistenza del record per quel mese/anno di lookup.
>
> *EN: The line that materializes the conceptual difference from `FilleaCorrection#build_row`: no `Statistics::ZoningPeriodScope` query, no SinCGIL count to compare against — `diff` is simply `anagrafe` (the `subscribers_af` value read directly from the `IntegrationFlc` record). This class needs no knowledge of `Import`'s contents to compute its own correction, unlike `FilleaCorrection`, which must query SinCGIL to build the comparison. As in `FilleaCorrection`, `.subscribers_af` has no explicit `nil` guard — safe only because `build_row` is called exclusively after `dato_presente?` has already confirmed the record exists for that lookup month/year.*

### `missing_result` *(privato)*

```ruby
def missing_result(missing)
  Result.new(error: "Non ci sono dati Anagrafe FLC per #{lookup_month} #{lookup_year} in " \
    "#{missing.map(&:descrizione_azzonamento).join(', ')}.")
end
```

> **IT:** Il messaggio d'errore riporta esplicitamente `lookup_month`/`lookup_year` (il mese **precedente** a quello richiesto), non `@mese`/`@anno` — un dettaglio importante per la comprensibilità dell'errore lato utente: se manca il dato Anagrafe FLC di Maggio, un operatore che sta cercando di vedere le statistiche di Giugno deve essere informato che manca il dato di **Maggio**, non un generico "dato mancante per Giugno" che lo indirizzerebbe a cercare/caricare il file sbagliato.
>
> *EN: The error message explicitly reports `lookup_month`/`lookup_year` (the month **before** the one requested), not `@mese`/`@anno` — an important detail for the error's readability from the user's side: if May's Anagrafe FLC data is missing, an operator trying to view June's statistics needs to be told that **May's** data is missing, not a generic "data missing for June" that would point them toward searching for/uploading the wrong file.*
