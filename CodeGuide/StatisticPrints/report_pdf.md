# `StatisticPrints::ReportPdf`

**File:** `app/services/statistic_prints/report_pdf.rb`

## Codice completo

```ruby
module StatisticPrints
  class ReportPdf
    ASAP_DIR = Rails.root.join("app/assets/fonts")
    CONTENT_MARGIN_TOP_MM = 15
    CONTENT_MARGIN_BOTTOM_MM = 15
    CONTENT_MARGIN_LR_MM = 15

    CONTENT_PAGES = [
      RegionalPage, CategoriesPage, EmploymentStatusPage, MembershipTypesPage, ProvisionalRevocationsPage,
      NationalityGenderPage, WorkStatusAgePage, CategoryGenderNationalityPage
    ].freeze

    def self.call(...) = new(...).call

    def initialize(form:, comparison_service: Statistics::TotalMembersComparison)
      @form = form
      @comparison_service = comparison_service
    end

    def call
      margin = [ mm_to_pt(CONTENT_MARGIN_TOP_MM), mm_to_pt(CONTENT_MARGIN_LR_MM),
                mm_to_pt(CONTENT_MARGIN_BOTTOM_MM), mm_to_pt(CONTENT_MARGIN_LR_MM) ]
      Prawn::Document.new(page_size: "A4", page_layout: :landscape, margin: margin) do |pdf|
        register_fonts(pdf)
        pdf.canvas { CoverPage.draw(pdf, form: @form) }
        draw_legend(pdf)
        draw_zoning_section(pdf, @form.zoning, @form)
        draw_province_sections(pdf)
        draw_back_cover(pdf)
      end
    end

    private

    def draw_legend(pdf)
      return unless @form.legend

      pdf.start_new_page
      LegendPage.draw(pdf, form: @form)
    end

    # Una pagina divisoria con il nome dell'azzonamento, seguita dal set
    # completo di pagine di contenuto per quell'azzonamento.
    def draw_zoning_section(pdf, zoning, form)
      pdf.start_new_page
      ZoningDividerPage.draw(pdf, zoning: zoning, mese: @form.mese, anno: @form.anno)
      draw_content_pages(pdf, form)
    end

    def draw_content_pages(pdf, form)
      CONTENT_PAGES.each do |page_class|
        pdf.start_new_page
        page_class.draw(pdf, form: form, comparison_service: @comparison_service)
      end
    end

    # Quando l'azzonamento scelto è regionale, ripete l'intera sezione
    # (pagina divisoria + set di pagine di contenuto) per ciascun comprensorio.
    def draw_province_sections(pdf)
      return unless @form.zoning.regionale?

      Zoning.comprensori_di(@form.zoning).each do |zoning|
        draw_zoning_section(pdf, zoning, province_form(zoning))
      end
    end

    # Chiude il fascicolo con la controcopertina. Se il numero di pagine fin
    # qui è dispari, inserisce prima una pagina bianca: così l'interno del
    # fascicolo (esclusa la controcopertina) ha un numero di pagine pari,
    # pronto per la stampa fisica fronte/retro.
    def draw_back_cover(pdf)
      pdf.start_new_page if pdf.page_count.odd?
      pdf.start_new_page
      pdf.canvas { BackCoverPage.draw(pdf) }
    end

    def province_form(zoning)
      TotalMembersForm.new(zoning_id: zoning.id, anno: @form.anno, mese: @form.mese)
    end

    def mm_to_pt(mm) = mm * 72 / 25.4

    def register_fonts(pdf)
      pdf.font_families.update(
        "AsapCondensed" => {
          normal: ASAP_DIR.join("AsapCondensed-Regular.ttf"), bold: ASAP_DIR.join("AsapCondensed-Bold.ttf"),
          italic: ASAP_DIR.join("AsapCondensed-Italic.ttf"), bold_italic: ASAP_DIR.join("AsapCondensed-BoldItalic.ttf")
        }
      )
    end
  end
end
```

## Sezioni commentate

### `CONTENT_MARGIN_*_MM`, `CONTENT_PAGES`

```ruby
CONTENT_MARGIN_TOP_MM = 15
CONTENT_MARGIN_BOTTOM_MM = 15
CONTENT_MARGIN_LR_MM = 15

CONTENT_PAGES = [
  RegionalPage, CategoriesPage, EmploymentStatusPage, MembershipTypesPage, ProvisionalRevocationsPage,
  NationalityGenderPage, WorkStatusAgePage, CategoryGenderNationalityPage
].freeze
```

> **IT:** Le costanti di margine sono espresse in millimetri e convertite in punti solo al punto d'uso (`mm_to_pt`), la stessa convenzione ripetuta in ogni file Prawn di questa cartella — non esiste un helper condiviso `mm_to_pt`, ogni classe che ne ha bisogno lo ridefinisce privatamente. `CONTENT_PAGES` è l'unico punto della codebase in cui l'ordine delle otto pagine di contenuto del fascicolo è deciso: è un `Array` di classi, non stringhe o simboli, così `page_class.draw(...)` può essere chiamato direttamente senza `constantize`. Aggiungere una nuova pagina di contenuto significa aggiungere una riga qui, nel punto esatto della sequenza in cui deve comparire nel PDF stampato — l'ordine di questo array **è** l'ordine fisico delle pagine.
>
> *EN: The margin constants are expressed in millimeters and converted to points only at the point of use (`mm_to_pt`), the same convention repeated in every Prawn file in this folder — there is no shared `mm_to_pt` helper, every class that needs it redefines it privately. `CONTENT_PAGES` is the single place in the codebase where the order of the booklet's eight content pages is decided: it's an `Array` of classes, not strings or symbols, so `page_class.draw(...)` can be called directly with no `constantize`. Adding a new content page means adding one line here, at the exact point in the sequence where it must appear in the printed PDF — this array's order **is** the physical page order.*

### `initialize`

```ruby
def initialize(form:, comparison_service: Statistics::TotalMembersComparison)
  @form = form
  @comparison_service = comparison_service
end
```

> **IT:** `comparison_service:` è un punto di iniezione esplicito, non solo un default comodo. `@comparison_service` viene passato intatto fino a `page_class.draw(pdf, form:, comparison_service:)` per ognuna delle `CONTENT_PAGES` (in pratica solo `RegionalPage` lo usa davvero — le altre pagine calcolano le proprie percentuali da servizi `*Breakdown` diversi che non necessitano di questo parametro, ma lo ricevono comunque per uniformità di firma). Il motivo dell'iniezione è la testabilità: gli specs possono passare un doppio/stub al posto di `Statistics::TotalMembersComparison` senza dover popolare dati `Import` reali solo per generare un PDF di prova. È un'asimmetria deliberata rispetto al fascicolo gemello SPI: `StatisticSpiPrints::ReportPdf` **non** ha questo parametro — le sue pagine di contenuto chiamano `StatisticSpi::TotalMembersComparison` direttamente, con i propri default, perché quel fascicolo non ha mai avuto lo stesso bisogno di stub nei test. Le due gerarchie sono cugine, non identiche.
>
> *EN: `comparison_service:` is an explicit injection point, not just a convenient default. `@comparison_service` is threaded unchanged through to `page_class.draw(pdf, form:, comparison_service:)` for every one of the `CONTENT_PAGES` (in practice only `RegionalPage` actually uses it — the other content pages compute their own percentages from different `*Breakdown` services that don't need this parameter, but receive it anyway for signature uniformity). The reason for the injection is testability: specs can pass a stub/double instead of `Statistics::TotalMembersComparison` without having to seed real `Import` data just to generate a test PDF. It's a deliberate asymmetry versus the sibling SPI booklet: `StatisticSpiPrints::ReportPdf` does **not** have this parameter — its content pages call `StatisticSpi::TotalMembersComparison` directly, with their own defaults, because that booklet never had the same need for test stubs. The two hierarchies are cousins, not identical twins.*

### `call`

```ruby
def call
  margin = [ mm_to_pt(CONTENT_MARGIN_TOP_MM), mm_to_pt(CONTENT_MARGIN_LR_MM),
            mm_to_pt(CONTENT_MARGIN_BOTTOM_MM), mm_to_pt(CONTENT_MARGIN_LR_MM) ]
  Prawn::Document.new(page_size: "A4", page_layout: :landscape, margin: margin) do |pdf|
    register_fonts(pdf)
    pdf.canvas { CoverPage.draw(pdf, form: @form) }
    draw_legend(pdf)
    draw_zoning_section(pdf, @form.zoning, @form)
    draw_province_sections(pdf)
    draw_back_cover(pdf)
  end
end
```

> **IT:** L'array `margin` a quattro elementi segue la convenzione di Prawn `[top, right, bottom, left]` (in senso orario, come il CSS `margin` shorthand) — qui `right` e `left` sono lo stesso valore mm-to-pt riusato due volte, non un errore di battitura. Ogni pagina di contenuto disegna dentro questo margine (15mm su tutti e quattro i lati), mentre `CoverPage` e `BackCoverPage` sono le uniche due chiamate avvolte in `pdf.canvas { ... }`: `canvas` rimappa temporaneamente `pdf.bounds` all'intera pagina fisica A4, ignorando il margine configurato, così lo sfondo può coprire il foglio interamente (full-bleed) invece di fermarsi al bordo del margine di 15mm. Questa è l'unica sequenza in cui l'ordine delle chiamate conta per un motivo non ovvio: `CoverPage` disegna testo **bianco** (vedi `cover_page.md`), quindi `pdf.fill_color` resta bianco quando Prawn passa alla pagina successiva — ogni pagina disegnata dopo (`LegendPage`, `ZoningDividerPage`, le `CONTENT_PAGES`) deve fare il proprio `pdf.fill_color "000000"` di reset a inizio `draw`, perché lo stato del colore di riempimento in Prawn è globale al documento, non scoped al blocco o alla pagina corrente.
>
> *EN: The four-element `margin` array follows Prawn's `[top, right, bottom, left]` convention (clockwise, like the CSS `margin` shorthand) — here `right` and `left` are the same mm-to-pt value reused twice, not a typo. Every content page draws inside this margin (15mm on all four sides), while `CoverPage` and `BackCoverPage` are the only two calls wrapped in `pdf.canvas { ... }`: `canvas` temporarily remaps `pdf.bounds` to the entire physical A4 page, ignoring the configured margin, so the background can cover the sheet full-bleed instead of stopping at the 15mm margin edge. This is the one sequence where call order matters for a non-obvious reason: `CoverPage` draws **white** text (see `cover_page.md`), so `pdf.fill_color` stays white when Prawn moves to the next page — every page drawn afterward (`LegendPage`, `ZoningDividerPage`, the `CONTENT_PAGES`) must do its own `pdf.fill_color "000000"` reset at the start of `draw`, because Prawn's fill-color state is global to the document, not scoped to the current block or page.*

### `draw_legend`

```ruby
def draw_legend(pdf)
  return unless @form.legend

  pdf.start_new_page
  LegendPage.draw(pdf, form: @form)
end
```

> **IT:** La legenda è opzionale per definizione — `@form.legend` è un `Legend.find_by(...)` che può tornare `nil` se nessuno ha compilato una legenda per quell'azzonamento/anno/mese (vedi `TotalMembersForm#legend`). `return unless` evita di chiamare `pdf.start_new_page` quando non serve: se lo si chiamasse comunque, si otterrebbe una pagina completamente vuota nel fascicolo stampato invece che semplicemente saltare la sezione.
>
> *EN: The legend is optional by design — `@form.legend` is a `Legend.find_by(...)` that can return `nil` if nobody has filled in a legend for that zoning/year/month (see `TotalMembersForm#legend`). `return unless` avoids calling `pdf.start_new_page` when it isn't needed: calling it regardless would leave a completely blank page in the printed booklet instead of simply skipping the section.*

### `draw_zoning_section`, `draw_content_pages`

```ruby
def draw_zoning_section(pdf, zoning, form)
  pdf.start_new_page
  ZoningDividerPage.draw(pdf, zoning: zoning, mese: @form.mese, anno: @form.anno)
  draw_content_pages(pdf, form)
end

def draw_content_pages(pdf, form)
  CONTENT_PAGES.each do |page_class|
    pdf.start_new_page
    page_class.draw(pdf, form: form, comparison_service: @comparison_service)
  end
end
```

> **IT:** `draw_zoning_section` è la funzione riusata sia per l'azzonamento scelto dall'utente sia per ciascun comprensorio (vedi `draw_province_sections`), quindi accetta `zoning` e `form` come parametri anche se, nel primo caso, coincidono già con `@form.zoning`/`@form` — perché nel secondo caso (ripetizione per comprensorio) sono un `Zoning` figlio e un `TotalMembersForm` costruito ad hoc da `province_form`, diversi da `@form`. `mese`/`anno` invece vengono sempre letti da `@form`, mai dal parametro `form`, perché il periodo di riferimento del fascicolo è unico e non cambia comprensorio per comprensorio (a differenza dello `zoning`, il periodo non fa parte del `TotalMembersForm` ricostruito per ogni provincia).
>
> *EN: `draw_zoning_section` is the function reused both for the user-chosen zoning and for each comprensorio (see `draw_province_sections`), so it takes `zoning` and `form` as parameters even though, in the first case, they already coincide with `@form.zoning`/`@form` — because in the second case (per-comprensorio repetition) they're a child `Zoning` and an ad-hoc `TotalMembersForm` built by `province_form`, different from `@form`. `mese`/`anno`, on the other hand, are always read from `@form`, never from the `form` parameter, because the booklet's reference period is single and doesn't change comprensorio by comprensorio (unlike `zoning`, the period isn't part of the `TotalMembersForm` rebuilt for each province).*

### `draw_province_sections`, `province_form`

```ruby
def draw_province_sections(pdf)
  return unless @form.zoning.regionale?

  Zoning.comprensori_di(@form.zoning).each do |zoning|
    draw_zoning_section(pdf, zoning, province_form(zoning))
  end
end

def province_form(zoning)
  TotalMembersForm.new(zoning_id: zoning.id, anno: @form.anno, mese: @form.mese)
end
```

> **IT:** Questo è il cuore del comportamento "un fascicolo, più sezioni": se l'utente ha scelto un azzonamento regionale, il documento non si ferma alla sezione regionale — ripete l'intera sequenza (pagina divisoria + tutte le `CONTENT_PAGES`) una volta per ciascun comprensorio figlio. `province_form` costruisce un `TotalMembersForm` nuovo, non riusa `@form` con lo `zoning_id` cambiato al volo: `TotalMembersForm` è un `ActiveModel::Model` leggero (non `ActiveRecord`, vedi `app/models/total_members_form.rb`), quindi costruirne uno nuovo per ogni comprensorio è economico e più sicuro che mutare lo stato di `@form` dentro un ciclo. Nota che `province_form` non passa `legend:` — le pagine per comprensorio non hanno una propria legenda separata da quella regionale, che si mostra una sola volta a inizio fascicolo tramite `draw_legend`.
>
> *EN: This is the heart of the "one booklet, several sections" behavior: if the user picked a regional zoning, the document doesn't stop at the regional section — it repeats the entire sequence (divider page + all `CONTENT_PAGES`) once per child comprensorio. `province_form` builds a brand new `TotalMembersForm` rather than reusing `@form` with the `zoning_id` swapped in place: `TotalMembersForm` is a lightweight `ActiveModel::Model` (not `ActiveRecord`, see `app/models/total_members_form.rb`), so building a fresh one per comprensorio is cheap and safer than mutating `@form`'s state inside a loop. Note that `province_form` doesn't pass `legend:` — per-comprensorio pages don't have their own legend separate from the regional one, which is shown exactly once at the start of the booklet via `draw_legend`.*

### `draw_back_cover`

```ruby
def draw_back_cover(pdf)
  pdf.start_new_page if pdf.page_count.odd?
  pdf.start_new_page
  pdf.canvas { BackCoverPage.draw(pdf) }
end
```

> **IT:** Il commento originale nel codice spiega il "cosa" (pareggia il numero di pagine per la stampa fronte/retro), ma vale la pena essere espliciti sul "perché conta l'ordine": il controllo `page_count.odd?` va fatto **prima** di aggiungere la pagina della copertina posteriore stessa, altrimenti quest'ultima verrebbe conteggiata nel calcolo della parità e il risultato sarebbe sbagliato. Il fascicolo interno (tutto tranne la copertina posteriore) deve avere un numero pari di pagine perché, in un fascicolo stampato fronte/retro con rilegatura, un numero dispari lascerebbe l'ultima pagina di contenuto sul retro di un foglio la cui altra facciata è la copertina posteriore — non è un errore fisico, ma rompe l'aspettativa "contenuto sempre fronte, copertina posteriore sempre da sola su un foglio proprio".
>
> *EN: The original source comment explains the "what" (evens out the page count for duplex printing), but it's worth being explicit about why order matters: the `page_count.odd?` check must happen **before** adding the back-cover page itself, otherwise the back cover would be counted in the parity calculation and the result would be wrong. The internal booklet (everything but the back cover) must have an even page count because, in a duplex-printed, bound booklet, an odd count would leave the last content page on the back of a sheet whose other face is the back cover — not physically broken, but it breaks the expectation that "content is always front-facing, the back cover always sits alone on its own sheet."*

### `mm_to_pt`, `register_fonts`

```ruby
def mm_to_pt(mm) = mm * 72 / 25.4

def register_fonts(pdf)
  pdf.font_families.update(
    "AsapCondensed" => {
      normal: ASAP_DIR.join("AsapCondensed-Regular.ttf"), bold: ASAP_DIR.join("AsapCondensed-Bold.ttf"),
      italic: ASAP_DIR.join("AsapCondensed-Italic.ttf"), bold_italic: ASAP_DIR.join("AsapCondensed-BoldItalic.ttf")
    }
  )
end
```

> **IT:** `register_fonts` è chiamato una sola volta, subito dopo la creazione del `Prawn::Document`, prima di disegnare qualunque pagina: registra la famiglia `"AsapCondensed"` con i suoi quattro stili (`normal`/`bold`/`italic`/`bold_italic`) nel documento, e ogni pagina successiva la richiama per nome (`@pdf.font("AsapCondensed", ...)`) senza doverla ri-registrare. Se questa chiamata mancasse, o venisse fatta dopo `CoverPage.draw`, il primo `@pdf.font("AsapCondensed", ...)` fallirebbe con un font non trovato — è un prerequisito silenzioso da cui dipendono tutte le pagine di questa cartella.
>
> *EN: `register_fonts` is called exactly once, right after creating the `Prawn::Document`, before drawing any page: it registers the `"AsapCondensed"` family with its four styles (`normal`/`bold`/`italic`/`bold_italic`) on the document, and every later page references it by name (`@pdf.font("AsapCondensed", ...)`) without re-registering it. If this call were missing, or made after `CoverPage.draw`, the first `@pdf.font("AsapCondensed", ...)` would fail with a missing-font error — it's a silent prerequisite that every page in this folder depends on.*
