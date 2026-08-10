# `StatisticWithIntegrationsPrintsController`

**File:** `app/controllers/statistic_with_integrations_prints_controller.rb`

## Codice completo

```ruby
class StatisticWithIntegrationsPrintsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_zonings

  def index
    @total_members_form = TotalMembersForm.new(total_members_params)

    respond_to do |format|
      format.html
      format.pdf { render_pdf }
    end
  end

  private

  def set_zonings
    @zonings = Zoning.order(:codice_azzonamento)
  end

  def total_members_params
    params.fetch(:total_members_form, {}).permit(:zoning_id, :anno, :mese)
  end

  def render_pdf
    unless @total_members_form.valid?
      return redirect_to statistic_with_integrations_prints_path, alert: "Compila azzonamento, anno e mese"
    end

    pdf = StatisticPrints::ReportPdf.call(form: @total_members_form,
      comparison_service: StatisticWithIntegrations::TotalMembersComparison)
    send_data pdf.render, filename: pdf_filename, type: "application/pdf", disposition: "inline"
  end

  def pdf_filename
    form = @total_members_form
    slug = "#{form.zoning.codice_azzonamento}-#{form.anno}-#{form.mese}".parameterize
    "statistiche-integrazioni-#{slug}.pdf"
  end
end
```

## Sezioni commentate

### L'intero controller — nessuna riga di logica propria di PDF

> **IT:** Questo è, in un certo senso, il file più importante da leggere per capire **perché** `StatisticPrints::ReportPdf` accetta un `comparison_service:` iniettabile (vedi `CodeGuide/StatisticPrints/report_pdf.md`): questo controller **è** il motivo di quella scelta architetturale. Non esiste, e non è mai esistita, una classe `StatisticPrintsWithIntegrations::ReportPdf` separata — l'intero PDF "Stampa Statistiche Con Integrazioni" è prodotto dallo stesso identico generatore Prawn di `StatisticPrintsController`, con un solo argomento diverso. Confrontando questo file riga per riga con `app/controllers/statistic_prints_controller.rb` (il controller gemello, senza integrazioni), le uniche tre differenze sono: (1) `render_pdf` passa `comparison_service: StatisticWithIntegrations::TotalMembersComparison` invece di lasciare il default (`Statistics::TotalMembersComparison`); (2) il redirect di validazione fallita punta a `statistic_with_integrations_prints_path` invece di `statistic_prints_path`; (3) `pdf_filename` produce `"statistiche-integrazioni-<slug>.pdf"` invece di `"statistiche-<slug>.pdf"`. Nient'altro — nessuna vista propria oltre `index.html.erb` (che mostra solo il form), nessun servizio proprio in `app/services/`, nessuna riga di logica di dominio: l'intera "feature" è una singola sostituzione di parametro.
>
> Questo è un esempio concreto e diretto di dependency injection usata esattamente per lo scopo per cui esiste: il generatore PDF (`StatisticPrints::ReportPdf`) non sa e non deve sapere che esistono le integrazioni FILLEA/FLC — riceve semplicemente "un oggetto che risponde a `.call(zoning:, anno:, mese:)` e restituisce un `Result` con la stessa forma" (il duck type condiviso da `Statistics::TotalMembersComparison` e `StatisticWithIntegrations::TotalMembersComparison`, vedi `CodeGuide/StatisticWithIntegrations/total_members_comparison.md`). Aggiungere una terza dashboard PDF con una terza fonte di correzione, in futuro, richiederebbe solo un nuovo controller di questa stessa forma, non nessuna modifica a `ReportPdf` o alle pagine di contenuto.
>
> *EN: This is, in a sense, the single most important file to read to understand **why** `StatisticPrints::ReportPdf` accepts an injectable `comparison_service:` (see `CodeGuide/StatisticPrints/report_pdf.md`): this controller **is** the reason for that architectural choice. There is, and never was, a separate `StatisticPrintsWithIntegrations::ReportPdf` class — the entire "Stampa Statistiche Con Integrazioni" PDF is produced by the exact same Prawn generator as `StatisticPrintsController`, with just one different argument. Comparing this file line by line against `app/controllers/statistic_prints_controller.rb` (the sibling controller, with no integrations), the only three differences are: (1) `render_pdf` passes `comparison_service: StatisticWithIntegrations::TotalMembersComparison` instead of leaving the default (`Statistics::TotalMembersComparison`); (2) the failed-validation redirect points to `statistic_with_integrations_prints_path` instead of `statistic_prints_path`; (3) `pdf_filename` produces `"statistiche-integrazioni-<slug>.pdf"` instead of `"statistiche-<slug>.pdf"`. Nothing else — no view of its own beyond `index.html.erb` (which just shows the form), no service of its own under `app/services/`, no domain logic of any kind: the entire "feature" is a single parameter substitution.
>
> This is a concrete, direct example of dependency injection used for exactly the purpose it exists for: the PDF generator (`StatisticPrints::ReportPdf`) doesn't know, and doesn't need to know, that the FILLEA/FLC integrations exist — it simply receives "an object that responds to `.call(zoning:, anno:, mese:)` and returns a `Result` with the same shape" (the duck type shared by `Statistics::TotalMembersComparison` and `StatisticWithIntegrations::TotalMembersComparison`, see `CodeGuide/StatisticWithIntegrations/total_members_comparison.md`). Adding a third PDF dashboard with a third correction source, in the future, would only require a new controller of this exact shape, no changes to `ReportPdf` or the content pages.*

### Cosa manca deliberatamente: nessun `StatisticSpiPrints` equivalente

> **IT:** Non esiste una `StatisticSpiWithIntegrationsPrintsController` (né una `StatisticSpiWithIntegrationsController` per la dashboard a schermo): le integrazioni FILLEA/FLC riguardano esclusivamente i lavoratori Attivi (vedi il commento di classe di `StatisticWithIntegrations::TotalMembersComparison`, "Pensionati = SPI, mai toccato dalle integrazioni"), quindi non ha senso strutturale che esista un equivalente SPI di questo controller — a differenza di quasi ogni altra feature del progetto (Statistiche, Stampe, Importazioni), che hanno tutte una coppia Attivi/SPI. Un'assenza deliberata, non un lavoro rimasto da fare.
>
> *EN: There is no `StatisticSpiWithIntegrationsPrintsController` (nor a `StatisticSpiWithIntegrationsController` for the on-screen dashboard): the FILLEA/FLC integrations concern exclusively Attivi workers (see `StatisticWithIntegrations::TotalMembersComparison`'s class comment, "Pensionati = SPI, never touched by the integrations"), so it wouldn't structurally make sense for an SPI equivalent of this controller to exist — unlike almost every other feature in the project (Statistics, Prints, Imports), which all have an Attivi/SPI pair. A deliberate absence, not leftover work.*
