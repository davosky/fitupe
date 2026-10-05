# `StatisticSpiPrints::ReportPdf`

**File:** `app/services/statistic_spi_prints/report_pdf.rb`

## Codice completo

```ruby
module StatisticSpiPrints
  class ReportPdf
    include StatisticPrints::PageLayout

    ASAP_DIR = Rails.root.join("app/assets/fonts")
    CONTENT_MARGIN_TOP_MM = 15
    CONTENT_MARGIN_BOTTOM_MM = 15
    CONTENT_MARGIN_LR_MM = 15

    CONTENT_PAGES = [
      TotalsPage, MultipleDelegationsPage, TipologieDelegaPage, CessazioniPage, ProvvisoriePage, AgeClassesPage
    ].freeze

    def self.call(...) = new(...).call

    def initialize(form:)
      @form = form
    end

    def call
      margin = [ mm(CONTENT_MARGIN_TOP_MM), mm(CONTENT_MARGIN_LR_MM),
                mm(CONTENT_MARGIN_BOTTOM_MM), mm(CONTENT_MARGIN_LR_MM) ]
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
      return unless @form.legend_spi

      pdf.start_new_page
      LegendPage.draw(pdf, form: @form)
    end

    # Una pagina divisoria con il nome dell'azzonamento, seguita dal set
    # completo di pagine di contenuto per quell'azzonamento (come nella
    # versione non-SPI).
    def draw_zoning_section(pdf, zoning, form)
      pdf.start_new_page
      ZoningDividerPage.draw(pdf, zoning: zoning, mese: @form.mese, anno: @form.anno)
      draw_content_pages(pdf, form)
    end

    def draw_content_pages(pdf, form)
      CONTENT_PAGES.each do |page_class|
        pdf.start_new_page
        page_class.draw(pdf, form: form)
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

    # Come nella versione non-SPI: se l'interno del fascicolo (tutto tranne la
    # controcopertina) ha un numero di pagine dispari, inserisce prima una
    # pagina bianca, cosi' e' pronto per la stampa fisica fronte/retro.
    def draw_back_cover(pdf)
      pdf.start_new_page if pdf.page_count.odd?
      pdf.start_new_page
      pdf.canvas { BackCoverPage.draw(pdf) }
    end

    def province_form(zoning)
      TotalMembersForm.new(zoning_id: zoning.id, anno: @form.anno, mese: @form.mese)
    end

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

### Panoramica della classe

> **IT:** L'orchestratore della "Stampa Statistiche SPI", equivalente quasi riga per riga di `StatisticPrints::ReportPdf` (l'orchestratore della stampa Attivi). La struttura del documento — copertina full-bleed, legenda opzionale, sezione dell'azzonamento scelto, ripetizione per comprensorio se regionale, controcopertina con pareggiamento pagine — è identica. Le uniche differenze sono: (1) niente parametro `comparison_service:` iniettabile in `initialize` (la versione Attivi lo ha, con default `Statistics::TotalMembersComparison`, per potersi testare passando un servizio finto); (2) `CONTENT_PAGES` elenca sei classi SPI-specifiche invece delle sette Attivi; (3) `draw_legend` controlla `@form.legend_spi` invece di `@form.legend`. Vale la pena leggere prima `CodeGuide/StatisticSpi/README.md` per capire perché ogni pagina di contenuto SPI (a differenza delle Attivi) mostra sempre sia il totale regionale sia i comprensori nella stessa vista — è la stessa ragione architetturale che spiega la lista `CONTENT_PAGES` qui sotto.
>
> *EN: The orchestrator behind "Stampa Statistiche SPI", an almost line-for-line equivalent of `StatisticPrints::ReportPdf` (the Attivi print orchestrator). The document structure — full-bleed cover, optional legend, the chosen zoning's section, per-comprensorio repetition when regional, back cover with page-count balancing — is identical. The only differences are: (1) no injectable `comparison_service:` parameter in `initialize` (the Attivi version has one, defaulting to `Statistics::TotalMembersComparison`, so tests can pass a fake service); (2) `CONTENT_PAGES` lists six SPI-specific classes instead of Attivi's seven; (3) `draw_legend` checks `@form.legend_spi` instead of `@form.legend`. It's worth reading `CodeGuide/StatisticSpi/README.md` first to understand why every SPI content page (unlike Attivi) always shows both the regional total and the comprensori in the same view — it's the same architectural reason behind the `CONTENT_PAGES` list below.*

### `CONTENT_PAGES`

```ruby
CONTENT_PAGES = [
  TotalsPage, MultipleDelegationsPage, TipologieDelegaPage, CessazioniPage, ProvvisoriePage, AgeClassesPage
].freeze
```

> **IT:** Elenco totalmente diverso da quello Attivi (`RegionalPage, CategoriesPage, EmploymentStatusPage, MembershipTypesPage, ProvisionalRevocationsPage, NationalityGenderPage, WorkStatusAgePage`), perché segue la stessa mappatura 1-a-1 con le sezioni di `StatisticSpi::TotalMembersComparison` descritta in `CodeGuide/StatisticSpi/total_members_comparison.md`: `TotalsPage` per iscritti/deleghe (il doppio campo `iscritti_*`/`deleghe_*` del `Result`), poi una pagina per ciascuna delle quattro sezioni SPI-specifiche (`deleghe_multiple`, `tipologie_delega`, `cessazioni`, `provvisorie`), più `AgeClassesPage` per le fasce d'età. L'ordine nell'array **è** l'ordine di stampa nel PDF — non alfabetico, non casuale: rispecchia l'ordine con cui l'utente le trova nella pagina web Statistiche SPI. `AgeClassesPage` è citata esplicitamente qui perché è il file in cui è stato scoperto e corretto lo storico bug delle pagine bianche (vedi sotto, `draw_content_pages`) — un problema di stato condiviso del cursore Prawn, non di questa classe, ma che si manifesta proprio attraverso il ciclo `draw_content_pages` definito qui.
>
> *EN: A completely different list from the Attivi one (`RegionalPage, CategoriesPage, EmploymentStatusPage, MembershipTypesPage, ProvisionalRevocationsPage, NationalityGenderPage, WorkStatusAgePage`), because it follows the same 1-to-1 mapping to `StatisticSpi::TotalMembersComparison`'s sections described in `CodeGuide/StatisticSpi/total_members_comparison.md`: `TotalsPage` for iscritti/deleghe (the `Result`'s dual `iscritti_*`/`deleghe_*` fields), then one page per each of the four SPI-specific sections (`deleghe_multiple`, `tipologie_delega`, `cessazioni`, `provvisorie`), plus `AgeClassesPage` for age bands. The array's order **is** the print order in the PDF — not alphabetical, not arbitrary: it mirrors the order the user finds them in on the Statistiche SPI web page. `AgeClassesPage` is called out explicitly here because it's the file where the historical blank-page bug was found and fixed (see below, `draw_content_pages`) — a Prawn shared-cursor state issue, not something in this class, but one that manifests precisely through the `draw_content_pages` loop defined here.*

### `initialize`, `call`

```ruby
def initialize(form:)
  @form = form
end

def call
  margin = [ mm(CONTENT_MARGIN_TOP_MM), mm(CONTENT_MARGIN_LR_MM),
            mm(CONTENT_MARGIN_BOTTOM_MM), mm(CONTENT_MARGIN_LR_MM) ]
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

> **IT:** `initialize` ha una sola dipendenza (`form:`), non due come la versione Attivi — conferma diretta dell'assenza di `comparison_service:` notata sopra: nessuna delle pagine di contenuto SPI accetta un servizio di confronto iniettabile, perché tutte chiamano il proprio `StatisticSpi::*Breakdown` corrispondente direttamente (si veda ad es. `AgeClassesPage#initialize`, che pure accetta un `breakdown_service:` iniettabile ma è un parametro *per-pagina*, non condiviso dall'orchestratore). `call` è identico riga per riga alla versione Attivi: stesso calcolo margine in punti da millimetri, stesso `Prawn::Document.new` in A4 orizzontale, stessa sequenza copertina→legenda→sezione azzonamento scelto→sezioni comprensori→controcopertina. `pdf.canvas { CoverPage.draw(...) }` è l'unico punto, insieme a `draw_back_cover`, in cui si esce temporaneamente dal margine configurato per un disegno full-bleed (vedi gotcha Prawn su `canvas` in `cover_page.md`/`back_cover_page.md`).
>
> *EN: `initialize` has a single dependency (`form:`), not two like the Attivi version — direct confirmation of the missing `comparison_service:` noted above: none of the SPI content pages accept an injectable comparison service, because they all call their corresponding `StatisticSpi::*Breakdown` directly (see e.g. `AgeClassesPage#initialize`, which does accept an injectable `breakdown_service:`, but that's a *per-page* parameter, not one shared by the orchestrator). `call` is line-for-line identical to the Attivi version: same margin-in-points-from-millimeters computation, same `Prawn::Document.new` in landscape A4, same cover→legend→chosen-zoning-section→comprensori-sections→back-cover sequence. `pdf.canvas { CoverPage.draw(...) }` is the one spot, along with `draw_back_cover`, where the configured margin is temporarily bypassed for full-bleed art (see the Prawn `canvas` gotcha in `cover_page.md`/`back_cover_page.md`).*

### `draw_legend`

```ruby
def draw_legend(pdf)
  return unless @form.legend_spi

  pdf.start_new_page
  LegendPage.draw(pdf, form: @form)
end
```

> **IT:** L'unica riga di `call` con una condizione diversa dalla versione Attivi: `@form.legend_spi` invece di `@form.legend`. `TotalMembersForm` (o l'equivalente form SPI) espone entrambi i metodi indipendentemente, e ciascuno risolve il proprio modello (`LegendSpi` per questo, `Legend` per l'Attivi — due modelli separati in `app/models/`, non una singola tabella con uno scope). La pagina legenda viene quindi disegnata solo se esiste un testo di legenda specifico per gli SPI selezionato dall'utente in fase di configurazione della stampa; se assente, `draw_legend` non consuma nessuna pagina (nessun `start_new_page`), a differenza di `draw_zoning_section` e `draw_back_cover` che vengono sempre eseguite.
>
> *EN: The one line in `call` with a condition different from the Attivi version: `@form.legend_spi` instead of `@form.legend`. `TotalMembersForm` (or the SPI equivalent form) exposes both methods independently, and each resolves its own model (`LegendSpi` for this one, `Legend` for Attivi — two separate models under `app/models/`, not one table with a scope). The legend page is therefore only drawn if a SPI-specific legend text was selected by the user when configuring the print job; if absent, `draw_legend` consumes no page at all (no `start_new_page`), unlike `draw_zoning_section` and `draw_back_cover`, which always run.*

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
    page_class.draw(pdf, form: form)
  end
end
```

> **IT:** Identico alla versione Attivi tranne che per la firma di `page_class.draw`: qui è `draw(pdf, form: form)`, senza `comparison_service: @comparison_service` in coda — di nuovo il riflesso dell'assenza del servizio iniettabile in `initialize`. Ogni `page_class.draw` inizia sempre da `pdf.start_new_page`, quindi nessuna pagina di contenuto SPI condivide mai il cursore verticale con la pagina precedente: il rischio di "azzeramento del cursore" descritto nel gotcha di `AgeClassesPage` è **interno** a una singola pagina (tra la sezione regionale e la riga di comprensori disegnate nella stessa pagina), non tra pagine diverse in questo ciclo.
>
> *EN: Identical to the Attivi version except for `page_class.draw`'s signature: here it's `draw(pdf, form: form)`, with no trailing `comparison_service: @comparison_service` — again a reflection of the missing injectable service in `initialize`. Every `page_class.draw` always starts from `pdf.start_new_page`, so no SPI content page ever shares its vertical cursor with the previous page: the "cursor zeroing" risk described in the `AgeClassesPage` gotcha is **internal** to a single page (between the regional section and the row of comprensori drawn on that same page), not across different pages in this loop.*

### `draw_province_sections`, `draw_back_cover`, `province_form`, `mm_to_pt`, `register_fonts`

```ruby
def draw_province_sections(pdf)
  return unless @form.zoning.regionale?

  Zoning.comprensori_di(@form.zoning).each do |zoning|
    draw_zoning_section(pdf, zoning, province_form(zoning))
  end
end

def draw_back_cover(pdf)
  pdf.start_new_page if pdf.page_count.odd?
  pdf.start_new_page
  pdf.canvas { BackCoverPage.draw(pdf) }
end

def province_form(zoning)
  TotalMembersForm.new(zoning_id: zoning.id, anno: @form.anno, mese: @form.mese)
end


def register_fonts(pdf)
  pdf.font_families.update(
    "AsapCondensed" => {
      normal: ASAP_DIR.join("AsapCondensed-Regular.ttf"), bold: ASAP_DIR.join("AsapCondensed-Bold.ttf"),
      italic: ASAP_DIR.join("AsapCondensed-Italic.ttf"), bold_italic: ASAP_DIR.join("AsapCondensed-BoldItalic.ttf")
    }
  )
end
```

> **IT:** Cinque metodi identici, riga per riga, alla versione Attivi (a parte i commenti, leggermente riformulati). Da notare in particolare: `province_form` costruisce sempre un `TotalMembersForm` — **la stessa classe form usata dalla stampa Attivi**, non un `TotalMembersSpiForm` dedicato — perché il form serve solo a portare `zoning_id`/`anno`/`mese` fino alle pagine di contenuto, e questi tre campi sono identici tra le due aree statistiche; è ogni singola `*Page`/`*Breakdown` SPI a interpretare quel form nel modo giusto (chiamando `StatisticSpi::*Breakdown` invece di `Statistics::*Breakdown`). `mm_to_pt` è duplicato invece di condiviso, coerente con la convenzione, già documentata per l'area Attivi, di inlineare la conversione mm→pt per-file piuttosto che estrarla in un helper condiviso. `register_fonts` è byte-per-byte identico: stesso font AsapCondensed, stessa cartella `ASAP_DIR`, nessuna variante SPI per la tipografia.
>
> *EN: Five methods identical, line for line, to the Attivi version (aside from slightly reworded comments). Worth noting in particular: `province_form` always builds a `TotalMembersForm` — **the same form class used by the Attivi print**, not a dedicated `TotalMembersSpiForm` — because the form only needs to carry `zoning_id`/`anno`/`mese` down to the content pages, and those three fields are identical across both statistics areas; it's each individual SPI `*Page`/`*Breakdown` that interprets that form the right way (calling `StatisticSpi::*Breakdown` instead of `Statistics::*Breakdown`). `mm_to_pt` is duplicated rather than shared, consistent with the convention — already documented for the Attivi area — of inlining the mm→pt conversion per-file instead of extracting it into a shared helper. `register_fonts` is byte-for-byte identical: same AsapCondensed font, same `ASAP_DIR` folder, no SPI-specific typography variant.*

> **Nota 2026-10-05 / Note:** dove il testo cita `mm_to_pt` o la conversione `* 72 / 25.4` ripetuta nelle pagine, dal refactor si tratta dell'helper condiviso `mm` di `StatisticPrints::PageLayout` (vedi `CodeGuide/StatisticPrints/page_layout.md`). / Where the text mentions `mm_to_pt` or the `* 72 / 25.4` conversion repeated in pages, since the refactor that is the shared `mm` helper of `StatisticPrints::PageLayout`.
