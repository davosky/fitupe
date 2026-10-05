# `StatisticWithIntegrations::TotalMembersComparison`

**File:** `app/services/statistic_with_integrations/total_members_comparison.rb`

## Codice completo

```ruby
module StatisticWithIntegrations
  # Riusa Statistics::TotalMembersComparison per tutte le sezioni della
  # dashboard e ricalibra con FilleaCorrection/FlcCorrection le sezioni
  # toccate dalle due direttive di integrazione dati esterni: totale,
  # comprensori, le righe FILLEA/FLC di categorie, le righe "Ordinaria
  # C.E."/"Delega Tesoro" di tipologie_delega, la riga "Attivi" di
  # attivi_pensionati (Pensionati = SPI, mai toccato dalle integrazioni) e la
  # riga "Delega" di tipologie_iscrizione (i lavoratori aggiunti da Cassa
  # Edile/Anagrafe sono per definizione a delega, mai BreviManu) — senza
  # ricalibrare anche queste due sezioni, la loro somma non torna più con il
  # totale corretto. Le altre sezioni (nazionalità, sesso, fasce età, sesso e
  # nazionalità per categoria, ecc.) non hanno un equivalente esterno (Cassa
  # Edile/Anagrafe non dicono sesso né nazionalità) e passano invariate.
  class TotalMembersComparison
    Result = Struct.new(:zoning, :mese, :anno, :anno_precedente, :count_anno, :count_precedente, :diff,
      :diff_percent, :comprensori, :categorie, :attivi_pensionati, :tipologie_iscrizione, :tipologie_delega,
      :nazionalita, :sesso, :provvisorie_revoche, :status_lavorativo, :fasce_eta, :sesso_per_categoria,
      :nazionalita_per_categoria, :fillea_correzione, :flc_correzione, :error, keyword_init: true) do
      def success? = error.blank?
    end

    ORDINARIA_CE = "Ordinaria C.E.".freeze
    DELEGA_TESORO = "Delega Tesoro".freeze
    ATTIVI = "Attivi".freeze

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
      @anno_precedente = (anno.to_i - 1).to_s
    end

    def call
      base = Statistics::TotalMembersComparison.call(zoning: @zoning, anno: @anno, mese: @mese)
      return missing_result(base.error) unless base.success?

      fillea_anno = FilleaCorrection.call(zoning: @zoning, anno: @anno, mese: @mese)
      return missing_result(fillea_anno.error) unless fillea_anno.success?

      flc_anno = FlcCorrection.call(zoning: @zoning, anno: @anno, mese: @mese)
      return missing_result(flc_anno.error) unless flc_anno.success?

      fillea_precedente = FilleaCorrection.call(zoning: @zoning, anno: @anno_precedente, mese: @mese)
      flc_precedente = FlcCorrection.call(zoning: @zoning, anno: @anno_precedente, mese: @mese)

      build_result(base, fillea_anno, fillea_precedente, flc_anno, flc_precedente)
    end

    private

    def build_result(base, fillea_anno, fillea_precedente, flc_anno, flc_precedente)
      fillea_diff_precedente = total_diff_precedente(fillea_precedente)
      flc_diff_precedente = total_diff_precedente(flc_precedente)

      diff_anno = fillea_anno.total_diff + flc_anno.total_diff
      diff_precedente = fillea_diff_precedente + flc_diff_precedente
      count_anno, count_precedente, diff, diff_percent =
        recalibrate(count_anno: base.count_anno, count_precedente: base.count_precedente, diff_anno:,
          diff_precedente:)

      categorie = recalibrate_named(base.categorie, :categoria, "FILLEA", fillea_anno.total_diff,
        fillea_diff_precedente)
      categorie = recalibrate_named(categorie, :categoria, "FLC", flc_anno.total_diff, flc_diff_precedente)

      tipologie_delega = recalibrate_named(base.tipologie_delega, :tipologia, ORDINARIA_CE, fillea_anno.total_diff,
        fillea_diff_precedente)
      tipologie_delega = recalibrate_named(tipologie_delega, :tipologia, DELEGA_TESORO, flc_anno.total_diff,
        flc_diff_precedente)

      tipologie_iscrizione = recalibrate_named(base.tipologie_iscrizione, :tipologia,
        Statistics::MembershipTypeBreakdown::DELEGA, diff_anno, diff_precedente)

      Result.new(zoning: @zoning, mese: @mese, anno: @anno, anno_precedente: @anno_precedente,
        count_anno:, count_precedente:, diff:, diff_percent:,
        comprensori: recalibrate_comprensori(base.comprensori, fillea_anno, fillea_precedente, flc_anno,
          flc_precedente),
        categorie:, tipologie_delega:, tipologie_iscrizione:,
        attivi_pensionati: recalibrate_attivi_pensionati(base.attivi_pensionati, diff_anno, diff_precedente,
          count_anno),
        nazionalita: base.nazionalita, sesso: base.sesso, provvisorie_revoche: base.provvisorie_revoche,
        status_lavorativo: base.status_lavorativo, fasce_eta: base.fasce_eta,
        sesso_per_categoria: base.sesso_per_categoria, nazionalita_per_categoria: base.nazionalita_per_categoria,
        fillea_correzione: fillea_anno, flc_correzione: flc_anno)
    end

    def recalibrate_comprensori(comprensori, fillea_anno, fillea_precedente, flc_anno, flc_precedente)
      comprensori.map do |riga|
        diff_anno = diff_for(riga.zoning, fillea_anno) + diff_for(riga.zoning, flc_anno)
        diff_precedente = diff_precedente_for(riga.zoning, fillea_precedente) +
          diff_precedente_for(riga.zoning, flc_precedente)
        count_anno, count_precedente, diff, diff_percent =
          recalibrate(count_anno: riga.count_anno, count_precedente: riga.count_precedente, diff_anno:,
            diff_precedente:)

        riga.class.new(zoning: riga.zoning, count_anno:, count_precedente:, diff:, diff_percent:)
      end
    end

    # ricalibra una singola riga di un breakdown (categorie/tipologie_delega)
    # individuata per nome, sommando il diff aggregato passato
    def recalibrate_named(righe, attributo, valore, diff_anno, diff_precedente)
      righe.map do |riga|
        next riga unless riga.public_send(attributo) == valore

        count_anno, count_precedente, diff, diff_percent =
          recalibrate(count_anno: riga.count_anno, count_precedente: riga.count_precedente, diff_anno:,
            diff_precedente:)

        riga.class.new(attributo => valore, count_anno:, count_precedente:, diff:, diff_percent:)
      end
    end

    # ricalibra la riga "Attivi" (Pensionati = SPI, non toccato dalle
    # integrazioni) e ricalcola la percentuale di entrambe le righe sul nuovo
    # totale corretto, invariato per il gruppo Pensionati.
    def recalibrate_attivi_pensionati(righe, diff_anno, diff_precedente, totale_anno_corretto)
      righe.map do |riga|
        if riga.gruppo == ATTIVI
          count_anno, count_precedente, diff, diff_percent =
            recalibrate(count_anno: riga.count_anno, count_precedente: riga.count_precedente, diff_anno:,
              diff_precedente:)
        else
          count_anno, count_precedente, diff, diff_percent =
            riga.count_anno, riga.count_precedente, riga.diff, riga.diff_percent
        end

        percentuale = totale_anno_corretto.zero? ? nil : (count_anno.to_f / totale_anno_corretto * 100)
        riga.class.new(gruppo: riga.gruppo, count_anno:, count_precedente:, diff:, diff_percent:, percentuale:)
      end
    end

    def diff_for(zoning, correzione)
      correzione.rows.find { |r| r.zoning == zoning }&.diff || 0
    end

    def diff_precedente_for(zoning, correzione_precedente)
      return 0 unless correzione_precedente.success?

      diff_for(zoning, correzione_precedente)
    end

    def total_diff_precedente(correzione_precedente)
      correzione_precedente.success? ? correzione_precedente.total_diff : 0
    end

    def recalibrate(count_anno:, count_precedente:, diff_anno:, diff_precedente:)
      nuovo_anno = count_anno + diff_anno
      nuovo_precedente = count_precedente + diff_precedente
      nuovo_diff = nuovo_anno - nuovo_precedente
      nuovo_diff_percent = nuovo_precedente.zero? ? nil : (nuovo_diff.to_f / nuovo_precedente * 100)
      [ nuovo_anno, nuovo_precedente, nuovo_diff, nuovo_diff_percent ]
    end

    def missing_result(error)
      Result.new(zoning: @zoning, mese: @mese, anno: @anno, anno_precedente: @anno_precedente, error:)
    end
  end
end
```

## Sezioni commentate

### Commento di classe — la mappa completa di cosa viene ricalibrato e perché

```ruby
# Riusa Statistics::TotalMembersComparison per tutte le sezioni della
# dashboard e ricalibra con FilleaCorrection/FlcCorrection le sezioni
# toccate dalle due direttive di integrazione dati esterni: totale,
# comprensori, le righe FILLEA/FLC di categorie, le righe "Ordinaria
# C.E."/"Delega Tesoro" di tipologie_delega, la riga "Attivi" di
# attivi_pensionati (Pensionati = SPI, mai toccato dalle integrazioni) e la
# riga "Delega" di tipologie_iscrizione (i lavoratori aggiunti da Cassa
# Edile/Anagrafe sono per definizione a delega, mai BreviManu) — senza
# ricalibrare anche queste due sezioni, la loro somma non torna più con il
# totale corretto. Le altre sezioni (nazionalità, sesso, fasce età, ecc.)
# non hanno un equivalente esterno e passano invariate da Statistics.
class TotalMembersComparison
```

> **IT:** Questo commento di classe esiste perché una versione precedente di questa esatta classe aveva un bug reale, scoperto e corretto il 2026-08-04: `attivi_pensionati` e `tipologie_iscrizione` **non venivano ricalibrate affatto** — `build_result` passava `base.attivi_pensionati`/`base.tipologie_iscrizione` invariate mentre ogni altra sezione elencata sopra veniva già corretta. Il bug è stato individuato dall'utente confrontando dati reali di luglio 2026 per il FVG: la somma delle righe di Categorie dava 40210, ma la riga "Attivi" di Attivi/Pensionati mostrava 38781 — un gap di 1429, esattamente la correzione combinata FILLEA+FLC di quel periodo. Lo stesso gap di 1429 tra Delega+BreviManu (83684) e il Totale corretto (85113). La lezione generale, ora incorporata nel commento: **qualunque sezione le cui righe sono pensate per sommare esattamente al totale** (Attivi+Pensionati, Delega+BreviManu) deve ricevere il diff aggregato sulla riga che rappresenta "il resto degli iscritti non già coperto da una riga più specifica corretta altrove" — non basta chiedersi "esiste un equivalente esterno diretto per questa sezione?" (la risposta seguirebbe erroneamente "no, lasciala invariata"), bisogna chiedersi anche "questa sezione partiziona esattamente il totale?".
>
> *EN: This class comment exists because an earlier version of this exact class had a real bug, discovered and fixed on 2026-08-04: `attivi_pensionati` and `tipologie_iscrizione` **weren't being recalibrated at all** — `build_result` passed `base.attivi_pensionati`/`base.tipologie_iscrizione` straight through unchanged while every other section listed above was already being corrected. The bug was caught by the user comparing real July-2026 FVG data: summing the Categorie rows gave 40210, but Attivi/Pensionati's "Attivi" row showed 38781 — a 1429 gap, exactly that period's combined FILLEA+FLC correction. The same 1429 gap showed up between Delega+BreviManu (83684) and the corrected Totale (85113). The general lesson, now baked into the comment: **any section whose rows are meant to sum exactly to the total** (Attivi+Pensionati, Delega+BreviManu) needs the aggregate diff applied to whichever row represents "the rest of the members not already covered by a more specific corrected row elsewhere" — it's not enough to ask "does this section have a direct external equivalent?" (the answer would wrongly follow "no, leave it unchanged"), one also has to ask "does this section exactly partition the total?"*

### `Result` (Struct) e le tre costanti

```ruby
Result = Struct.new(:zoning, :mese, :anno, :anno_precedente, :count_anno, :count_precedente, :diff,
  :diff_percent, :comprensori, :categorie, :attivi_pensionati, :tipologie_iscrizione, :tipologie_delega,
  :nazionalita, :sesso, :provvisorie_revoche, :status_lavorativo, :fasce_eta, :sesso_per_categoria,
  :nazionalita_per_categoria, :fillea_correzione, :flc_correzione, :error, keyword_init: true) do
  def success? = error.blank?
end

ORDINARIA_CE = "Ordinaria C.E.".freeze
DELEGA_TESORO = "Delega Tesoro".freeze
ATTIVI = "Attivi".freeze
```

> **IT:** `Result` ha esattamente gli stessi campi di `Statistics::TotalMembersComparison::Result` **più due**: `fillea_correzione`/`flc_correzione`. A differenza della decisione presa altrove nel progetto ("Nessuna visibile UI di dettaglio correzione — davo ha esplicitamente chiesto di omettere qualunque card 'Integrazione FILLEA/FLC' dalla vista", vedi memoria di progetto), questi due campi **esistono** nel `Result` ma non sono usati dalla vista principale — probabilmente disponibili per debug/verifica futura senza violare la richiesta esplicita di non mostrarli nella UI standard. Le tre costanti (`ORDINARIA_CE`, `DELEGA_TESORO`, `ATTIVI`) centralizzano le stringhe usate per **individuare** le righe da ricalibrare in `recalibrate_named`/`recalibrate_attivi_pensionati` — un cambiamento all'etichetta esatta usata da uno di questi breakdown (es. se "Ordinaria C.E." venisse rinominata in `Statistics::DelegationTypeBreakdown`) andrebbe sincronizzato qui, altrimenti `recalibrate_named` smetterebbe silenziosamente di trovare corrispondenze (il `next riga unless riga.public_send(attributo) == valore` non solleva errori se nessuna riga corrisponde, semplicemente non ricalibra nulla).
>
> *EN: `Result` has exactly the same fields as `Statistics::TotalMembersComparison::Result` **plus two**: `fillea_correzione`/`flc_correzione`. Unlike the decision made elsewhere in the project ("No visible correction-detail UI — davo explicitly asked to omit any 'Integrazione FILLEA/FLC' detail card from the view," see project memory), these two fields **do exist** on `Result` but aren't used by the main view — likely available for future debugging/verification without violating the explicit request to not show them in the standard UI. The three constants (`ORDINARIA_CE`, `DELEGA_TESORO`, `ATTIVI`) centralize the strings used to **identify** which rows to recalibrate in `recalibrate_named`/`recalibrate_attivi_pensionati` — a change to the exact label used by one of these breakdowns (e.g. if "Ordinaria C.E." were renamed in `Statistics::DelegationTypeBreakdown`) would need syncing here, otherwise `recalibrate_named` would silently stop finding matches (`next riga unless riga.public_send(attributo) == valore` raises nothing if no row matches, it simply recalibrates nothing).*

### `call` — quattro chiamate, tre livelli di severità sui dati mancanti

```ruby
def call
  base = Statistics::TotalMembersComparison.call(zoning: @zoning, anno: @anno, mese: @mese)
  return missing_result(base.error) unless base.success?

  fillea_anno = FilleaCorrection.call(zoning: @zoning, anno: @anno, mese: @mese)
  return missing_result(fillea_anno.error) unless fillea_anno.success?

  flc_anno = FlcCorrection.call(zoning: @zoning, anno: @anno, mese: @mese)
  return missing_result(flc_anno.error) unless flc_anno.success?

  fillea_precedente = FilleaCorrection.call(zoning: @zoning, anno: @anno_precedente, mese: @mese)
  flc_precedente = FlcCorrection.call(zoning: @zoning, anno: @anno_precedente, mese: @mese)

  build_result(base, fillea_anno, fillea_precedente, flc_anno, flc_precedente)
end
```

> **IT:** Quattro chiamate a servizi esterni a questa classe, ma con una netta asimmetria tra anno corrente e anno precedente: `base`/`fillea_anno`/`flc_anno` (tutti riferiti a `@anno`) **bloccano** l'intera pagina con `missing_result` se falliscono — coerente con la politica "mancano i dati dell'anno richiesto → fallisci in modo visibile" già vista in ogni altro `TotalMembersComparison`/`*Correction` del progetto. `fillea_precedente`/`flc_precedente` (riferiti a `@anno_precedente`) **non vengono controllati affatto** qui — nessun `return missing_result(...) unless ...success?` per loro — perché la politica "l'anno precedente mancante non blocca mai, ricade silenziosamente su un valore non corretto" (documentata nella memoria di progetto) è delegata interamente a `build_result`/`total_diff_precedente`/`diff_precedente_for`, che sanno gestire un `Result` di correzione fallito senza propagarne l'errore. Da notare: `base` (i dati SinCGIL Attivi) viene controllato **prima** delle due correzioni — se SinCGIL non ha dati per questo periodo, non ha senso nemmeno verificare le integrazioni esterne.
>
> *EN: Four calls to services external to this class, but with a clear asymmetry between the current and previous year: `base`/`fillea_anno`/`flc_anno` (all referring to `@anno`) **block** the entire page with `missing_result` if they fail — consistent with the "the requested year's data is missing → fail visibly" policy already seen in every other `TotalMembersComparison`/`*Correction` in the project. `fillea_precedente`/`flc_precedente` (referring to `@anno_precedente`) are **not checked at all** here — no `return missing_result(...) unless ...success?` for them — because the policy "a missing previous year never blocks, it silently falls back to an uncorrected value" (documented in project memory) is delegated entirely to `build_result`/`total_diff_precedente`/`diff_precedente_for`, which know how to handle a failed correction `Result` without propagating its error. Worth noting: `base` (the SinCGIL Attivi data) is checked **before** the two corrections — if SinCGIL has no data for this period, checking the external integrations doesn't make sense either.*

### `build_result` — il punto di assemblaggio

```ruby
def build_result(base, fillea_anno, fillea_precedente, flc_anno, flc_precedente)
  fillea_diff_precedente = total_diff_precedente(fillea_precedente)
  flc_diff_precedente = total_diff_precedente(flc_precedente)

  diff_anno = fillea_anno.total_diff + flc_anno.total_diff
  diff_precedente = fillea_diff_precedente + flc_diff_precedente
  count_anno, count_precedente, diff, diff_percent =
    recalibrate(count_anno: base.count_anno, count_precedente: base.count_precedente, diff_anno:,
      diff_precedente:)

  categorie = recalibrate_named(base.categorie, :categoria, "FILLEA", fillea_anno.total_diff,
    fillea_diff_precedente)
  categorie = recalibrate_named(categorie, :categoria, "FLC", flc_anno.total_diff, flc_diff_precedente)

  tipologie_delega = recalibrate_named(base.tipologie_delega, :tipologia, ORDINARIA_CE, fillea_anno.total_diff,
    fillea_diff_precedente)
  tipologie_delega = recalibrate_named(tipologie_delega, :tipologia, DELEGA_TESORO, flc_anno.total_diff,
    flc_diff_precedente)

  tipologie_iscrizione = recalibrate_named(base.tipologie_iscrizione, :tipologia,
    Statistics::MembershipTypeBreakdown::DELEGA, diff_anno, diff_precedente)

  # ... Result.new(...)
end
```

> **IT:** Il punto centrale da cui si dipartono tutte le ricalibrazioni, ed è qui che si vede più chiaramente **quale diff va dove**:
>
> - Il **totale** (`count_anno`/`count_precedente`/`diff`/`diff_percent`) riceve la somma di entrambe le correzioni (`fillea_anno.total_diff + flc_anno.total_diff`) — entrambe le integrazioni contribuiscono al totale complessivo.
> - **Categorie**: due chiamate separate a `recalibrate_named`, **incatenate** (`categorie = recalibrate_named(categorie, ...)` riassegna la variabile), una per la riga "FILLEA" con `fillea_anno.total_diff`, una per la riga "FLC" con `flc_anno.total_diff` — ciascuna correzione tocca **solo la propria riga**, non entrambe. Lo stesso schema si ripete identico per **Tipologie Delega** (righe "Ordinaria C.E." e "Delega Tesoro").
> - **Tipologie Iscrizione**: una sola chiamata, sulla riga "Delega", ma con il **diff combinato** (`diff_anno`, la somma di entrambe le correzioni) — perché entrambe le integrazioni, FILLEA e FLC, aggiungono lavoratori che sono per definizione "a delega" (mai BreviManu), quindi entrambe contribuiscono alla stessa riga.
>
> `fillea_diff_precedente`/`flc_diff_precedente` vengono calcolati **una sola volta** all'inizio del metodo (tramite `total_diff_precedente`, che gestisce il caso "correzione dell'anno precedente fallita" restituendo 0) e poi riusati per ogni sezione — non ricalcolati per ciascuna, evitando di ripetere la logica di fallback per ogni chiamata a `recalibrate_named`.
>
> *EN: The central point every recalibration branches from, and where **which diff goes where** is clearest:
>
> - The **total** (`count_anno`/`count_precedente`/`diff`/`diff_percent`) receives the sum of both corrections (`fillea_anno.total_diff + flc_anno.total_diff`) — both integrations contribute to the overall total.
> - **Categorie**: two separate calls to `recalibrate_named`, **chained** (`categorie = recalibrate_named(categorie, ...)` reassigns the variable), one for the "FILLEA" row with `fillea_anno.total_diff`, one for the "FLC" row with `flc_anno.total_diff` — each correction touches **only its own row**, not both. The same scheme repeats identically for **Tipologie Delega** ("Ordinaria C.E." and "Delega Tesoro" rows).
> - **Tipologie Iscrizione**: a single call, on the "Delega" row, but with the **combined** diff (`diff_anno`, the sum of both corrections) — because both integrations, FILLEA and FLC, add workers who are by definition "delega-paid" (never BreviManu), so both contribute to the same row.
>
> `fillea_diff_precedente`/`flc_diff_precedente` are computed **once**, at the top of the method (via `total_diff_precedente`, which handles the "previous year's correction failed" case by returning 0) and then reused across every section — not recomputed per section, avoiding repeating the fallback logic for every `recalibrate_named` call.*

### `recalibrate_comprensori` *(privato)*

```ruby
def recalibrate_comprensori(comprensori, fillea_anno, fillea_precedente, flc_anno, flc_precedente)
  comprensori.map do |riga|
    diff_anno = diff_for(riga.zoning, fillea_anno) + diff_for(riga.zoning, flc_anno)
    diff_precedente = diff_precedente_for(riga.zoning, fillea_precedente) +
      diff_precedente_for(riga.zoning, flc_precedente)
    count_anno, count_precedente, diff, diff_percent =
      recalibrate(count_anno: riga.count_anno, count_precedente: riga.count_precedente, diff_anno:,
        diff_precedente:)

    riga.class.new(zoning: riga.zoning, count_anno:, count_precedente:, diff:, diff_percent:)
  end
end
```

> **IT:** A differenza di `build_result` (che usa `total_diff`, un unico numero aggregato per l'intera regione), qui il diff va calcolato **per singola provincia** (`riga.zoning`), perché `FilleaCorrection`/`FlcCorrection` producono una correzione diversa per ciascuna provincia figlia — da cui `diff_for(riga.zoning, correzione)`, che cerca la riga specifica di quella provincia dentro `correzione.rows` invece di sommare `total_diff`. `riga.class.new(...)` (non `Statistics::TotalMembersComparison::Row.new(...)` esplicito) è un dettaglio di robustezza: costruisce una nuova riga con la stessa classe di quella originale, qualunque essa sia, invece di assumerne il nome — se la classe `Row` interna di `Statistics::TotalMembersComparison` cambiasse nome, questo codice continuerebbe a funzionare senza modifiche.
>
> *EN: Unlike `build_result` (which uses `total_diff`, a single aggregated number for the whole region), the diff here must be computed **per individual province** (`riga.zoning`), because `FilleaCorrection`/`FlcCorrection` produce a different correction for each child province — hence `diff_for(riga.zoning, correzione)`, which looks up that specific province's row inside `correzione.rows` instead of summing `total_diff`. `riga.class.new(...)` (not an explicit `Statistics::TotalMembersComparison::Row.new(...)`) is a robustness detail: it builds a new row using the same class as the original one, whatever that is, instead of assuming its name — if `Statistics::TotalMembersComparison`'s internal `Row` class were ever renamed, this code would keep working unchanged.*

### `recalibrate_named` *(privato)*

```ruby
# ricalibra una singola riga di un breakdown (categorie/tipologie_delega)
# individuata per nome, sommando il diff aggregato passato
def recalibrate_named(righe, attributo, valore, diff_anno, diff_precedente)
  righe.map do |riga|
    next riga unless riga.public_send(attributo) == valore

    count_anno, count_precedente, diff, diff_percent =
      recalibrate(count_anno: riga.count_anno, count_precedente: riga.count_precedente, diff_anno:,
        diff_precedente:)

    riga.class.new(attributo => valore, count_anno:, count_precedente:, diff:, diff_percent:)
  end
end
```

> **IT:** Il metodo generico che rende possibile la ricalibrazione mirata di una singola riga dentro un array di righe eterogenee, riusato per Categorie, Tipologie Delega e (con `diff_anno`/`diff_precedente` combinati) Tipologie Iscrizione — la controparte generica di `recalibrate_attivi_pensionati`, che invece è specifica perché deve anche ricalcolare `percentuale`. `attributo` (un simbolo, `:categoria` o `:tipologia`) è passato dinamicamente perché i due breakdown target hanno `Row` con nomi di campo diversi per "l'etichetta della riga" — `riga.public_send(attributo)` legge quel campo qualunque sia il suo nome, e `riga.class.new(attributo => valore, ...)` lo riscrive nello stesso modo generico. `next riga unless ...` lascia **invariate** (stesso oggetto, non una copia) tutte le righe che non corrispondono al `valore` cercato — solo la riga il cui nome combacia viene effettivamente ricostruita.
>
> *EN: The generic method that makes it possible to target-recalibrate a single row inside an array of heterogeneous rows, reused for Categorie, Tipologie Delega, and (with combined `diff_anno`/`diff_precedente`) Tipologie Iscrizione — the generic counterpart to `recalibrate_attivi_pensionati`, which is instead specific because it also needs to recompute `percentuale`. `attributo` (a symbol, `:categoria` or `:tipologia`) is passed dynamically because the two target breakdowns have `Row`s with different field names for "the row's label" — `riga.public_send(attributo)` reads that field whatever its name, and `riga.class.new(attributo => valore, ...)` rewrites it the same generic way. `next riga unless ...` leaves every row that doesn't match the sought `valore` **unchanged** (the same object, not a copy) — only the row whose name matches actually gets rebuilt.*

### `recalibrate_attivi_pensionati` *(privato)* — il metodo aggiunto dal fix del 2026-08-04

```ruby
# ricalibra la riga "Attivi" (Pensionati = SPI, non toccato dalle
# integrazioni) e ricalcola la percentuale di entrambe le righe sul nuovo
# totale corretto, invariato per il gruppo Pensionati.
def recalibrate_attivi_pensionati(righe, diff_anno, diff_precedente, totale_anno_corretto)
  righe.map do |riga|
    if riga.gruppo == ATTIVI
      count_anno, count_precedente, diff, diff_percent =
        recalibrate(count_anno: riga.count_anno, count_precedente: riga.count_precedente, diff_anno:,
          diff_precedente:)
    else
      count_anno, count_precedente, diff, diff_percent =
        riga.count_anno, riga.count_precedente, riga.diff, riga.diff_percent
    end

    percentuale = totale_anno_corretto.zero? ? nil : (count_anno.to_f / totale_anno_corretto * 100)
    riga.class.new(gruppo: riga.gruppo, count_anno:, count_precedente:, diff:, diff_percent:, percentuale:)
  end
end
```

> **IT:** Questo è il metodo che ha risolto il bug del 2026-08-04 descritto nel commento di classe. Non poteva riusare `recalibrate_named` per due ragioni: (1) `Statistics::EmploymentStatusBreakdown::Row` ha un campo `percentuale` in più (è l'unica sezione "ibrida" con confronto anno su anno **e** percentuale, vedi `CodeGuide/StatisticPrints/README.md`) che `recalibrate_named` non conosce e non ricalcolerebbe; (2) la riga "Pensionati" **non** va ricalibrata (le integrazioni riguardano solo lavoratori attivi), ma la sua `percentuale` **va comunque ricalcolata**, perché il denominatore (il totale iscritti) è cambiato anche se il numeratore di quella riga specifica no. Il ramo `if riga.gruppo == ATTIVI` applica il diff aggregato solo alla riga Attivi; il ramo `else` porta avanti i valori originali di conteggio/diff della riga Pensionati **senza modificarli** — ma poi, fuori dal branch, `percentuale` viene ricalcolata per **entrambe** le righe (`riga.class.new(..., percentuale:)` è fuori dall'`if`/`else`) contro `totale_anno_corretto` (il totale già ricalibrato, passato da `build_result`). Questo è esattamente il dettaglio che, prima del fix, mancava: la riga Pensionati aveva sia il conteggio sia la percentuale invariati, quando solo il conteggio doveva restare invariato.
>
> *EN: This is the method that fixed the 2026-08-04 bug described in the class comment. It couldn't reuse `recalibrate_named` for two reasons: (1) `Statistics::EmploymentStatusBreakdown::Row` has one extra `percentuale` field (it's the one "hybrid" section with both a year-over-year comparison **and** a percentage, see `CodeGuide/StatisticPrints/README.md`) that `recalibrate_named` doesn't know about and wouldn't recompute; (2) the "Pensionati" row must **not** be recalibrated (the integrations only concern active workers), but its `percentuale` **must still be recomputed**, because the denominator (the member total) changed even though that specific row's numerator didn't. The `if riga.gruppo == ATTIVI` branch applies the aggregate diff only to the Attivi row; the `else` branch carries forward the Pensionati row's original count/diff values **unmodified** — but then, outside the branch, `percentuale` is recomputed for **both** rows (`riga.class.new(..., percentuale:)` sits outside the `if`/`else`) against `totale_anno_corretto` (the already-recalibrated total, passed in from `build_result`). This is exactly the detail that was missing before the fix: the Pensionati row had both its count and its percentage left unchanged, when only the count should have stayed unchanged.*

### `diff_for`, `diff_precedente_for`, `total_diff_precedente` *(privati)* — la rete di sicurezza per l'anno precedente

```ruby
def diff_for(zoning, correzione)
  correzione.rows.find { |r| r.zoning == zoning }&.diff || 0
end

def diff_precedente_for(zoning, correzione_precedente)
  return 0 unless correzione_precedente.success?

  diff_for(zoning, correzione_precedente)
end

def total_diff_precedente(correzione_precedente)
  correzione_precedente.success? ? correzione_precedente.total_diff : 0
end
```

> **IT:** Questi tre metodi implementano interamente la politica "l'anno precedente mancante non blocca mai" menzionata sopra a proposito di `call`. `total_diff_precedente`/`diff_precedente_for` controllano esplicitamente `correzione_precedente.success?`: se la correzione dell'anno precedente è fallita (nessun dato Cassa Edile/Anagrafe per quell'anno), la correzione applicata per l'anno precedente è semplicemente **0** — equivalente a trattare l'anno precedente come "non integrato", non a bloccare la pagina. `diff_for` (usato sia per l'anno corrente sia, tramite `diff_precedente_for`, per l'anno precedente quando la correzione ha successo) ha una propria piccola rete di sicurezza indipendente: `.find { ... }&.diff || 0` restituisce 0 anche se quella specifica provincia non ha una riga nella correzione (es. una provincia della regione priva di dato Cassa Edile in `FilleaCorrection#regional_result`, che la esclude da `rows` invece di generare una riga a zero — vedi `CodeGuide/StatisticWithIntegrations/fillea_correction.md`) — coerente con "province senza integrazione restano invariate".
>
> *EN: These three methods entirely implement the "a missing previous year never blocks" policy mentioned above regarding `call`. `total_diff_precedente`/`diff_precedente_for` explicitly check `correzione_precedente.success?`: if the previous year's correction failed (no Cassa Edile/Anagrafe data for that year), the correction applied for the previous year is simply **0** — equivalent to treating the previous year as "not integrated," not to blocking the page. `diff_for` (used both for the current year and, via `diff_precedente_for`, for the previous year when the correction succeeds) has its own small independent safety net: `.find { ... }&.diff || 0` returns 0 even if that specific province has no row in the correction (e.g. a province in the region with no Cassa Edile data, in `FilleaCorrection#regional_result`, which excludes it from `rows` instead of producing a zero row — see `CodeGuide/StatisticWithIntegrations/fillea_correction.md`) — consistent with "provinces without integration data stay unchanged."*

### `recalibrate`, `missing_result` *(privati)*

```ruby
def recalibrate(count_anno:, count_precedente:, diff_anno:, diff_precedente:)
  nuovo_anno = count_anno + diff_anno
  nuovo_precedente = count_precedente + diff_precedente
  nuovo_diff = nuovo_anno - nuovo_precedente
  nuovo_diff_percent = nuovo_precedente.zero? ? nil : (nuovo_diff.to_f / nuovo_precedente * 100)
  [ nuovo_anno, nuovo_precedente, nuovo_diff, nuovo_diff_percent ]
end

def missing_result(error)
  Result.new(zoning: @zoning, mese: @mese, anno: @anno, anno_precedente: @anno_precedente, error:)
end
```

> **IT:** `recalibrate` è il singolo punto di calcolo condiviso da **ogni** ricalibrazione della classe — il totale, i comprensori, categorie, tipologie delega, tipologie iscrizione, Attivi/Pensionati — tutti passano da qui, restituendo un array a quattro elementi destrutturato dal chiamante (`count_anno, count_precedente, diff, diff_percent = recalibrate(...)`). La logica è semplice per costruzione (somma i due diff ai due conteggi, ricalcola diff e percentuale da zero sui nuovi valori) proprio perché tutta la complessità di **quale** diff passare a questo metodo è già stata risolta a monte, in `build_result`/`recalibrate_comprensori`/`recalibrate_named`/`recalibrate_attivi_pensionati`. `nuovo_diff_percent` usa la stessa guardia sullo zero (`nil`, non `0`/`Infinity`) ripetuta identica in ogni altro `TotalMembersComparison` del progetto. `missing_result` non ha `total_diff`/dettagli di correzione: un `Result` di errore lascia semplicemente `nil` ogni altro campo, lo stesso pattern già visto in `Statistics::TotalMembersComparison#missing_data_result`.
>
> *EN: `recalibrate` is the single computation point shared by **every** recalibration in the class — the total, comprensori, categorie, tipologie delega, tipologie iscrizione, Attivi/Pensionati — all pass through here, returning a four-element array destructured by the caller (`count_anno, count_precedente, diff, diff_percent = recalibrate(...)`). The logic is simple by construction (add the two diffs to the two counts, recompute diff and percentage from scratch on the new values) precisely because all the complexity of **which** diff to pass to this method has already been resolved upstream, in `build_result`/`recalibrate_comprensori`/`recalibrate_named`/`recalibrate_attivi_pensionati`. `nuovo_diff_percent` uses the same zero guard (`nil`, not `0`/`Infinity`) repeated identically across every other `TotalMembersComparison` in the project. `missing_result` has no `total_diff`/correction details: an error `Result` simply leaves every other field `nil`, the same pattern already seen in `Statistics::TotalMembersComparison#missing_data_result`.*
