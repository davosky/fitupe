# `LegendSpisController`

**File:** `app/controllers/legend_spis_controller.rb`

## Codice completo

```ruby
class LegendSpisController < ApplicationController
  before_action :authenticate_user!
  before_action :set_legend_spi, only: %i[show edit update destroy confirm_destroy]
  before_action :set_zonings, only: %i[new create edit update]

  def index
    authorize LegendSpi
    @legend_spis = policy_scope(LegendSpi).includes(:zoning).order(year: :desc, month: :desc)
  end

  def show
  end

  def new
    @legend_spi = LegendSpi.new
    authorize @legend_spi
  end

  def create
    @legend_spi = LegendSpi.new(legend_spi_params)
    authorize @legend_spi

    if @legend_spi.save
      redirect_to legend_spis_path, notice: "Legenda SPI creata con successo."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @legend_spi.update(legend_spi_params)
      redirect_to legend_spis_path, notice: "Legenda SPI aggiornata con successo."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @legend_spi.destroy
    redirect_to legend_spis_path, notice: "Legenda SPI eliminata con successo."
  end

  def confirm_destroy
  end

  private

  def set_legend_spi
    @legend_spi = LegendSpi.find(params[:id])
    authorize @legend_spi
  end

  def set_zonings
    @zonings = Zoning.order(:codice_azzonamento)
  end

  def legend_spi_params
    params.require(:legend_spi).permit(:zoning_id, :year, :month, :description)
  end
end
```

## Sezioni commentate

### L'intero controller — clone riga per riga di `LegendsController`

> **IT:** Identico a `LegendsController` (vedi `CodeGuide/Legends/legends_controller.md`) in ogni azione, sostituendo `Legend`/`legend` con `LegendSpi`/`legend_spi` e i testi dei messaggi flash con "Legenda SPI". Stesso `set_zonings` per popolare la `collection_select`, stesso ordinamento `year: :desc, month: :desc` in `index`, stessi quattro `legend_spi_params` permessi. L'unica differenza reale, fuori dal codice Ruby, è visiva: le view usano icone SVG proprie (`legend/legendaspi-logo.svg`, `legend/legendaspi-logo-show.svg`) che condividono la stessa cartella `app/assets/images/legend/` delle icone di `Legend` invece di averne una propria — coerente con come le altre coppie Attivi/SPI del progetto tendono a riusare cartelle asset condivise per varianti dello stesso concetto grafico.
>
> *EN: Identical to `LegendsController` (see `CodeGuide/Legends/legends_controller.md`) in every action, swapping `Legend`/`legend` for `LegendSpi`/`legend_spi` and the flash message text for "Legenda SPI". Same `set_zonings` to populate the `collection_select`, same `year: :desc, month: :desc` ordering in `index`, same four permitted `legend_spi_params`. The one real difference, outside the Ruby code, is visual: the views use their own SVG icons (`legend/legendaspi-logo.svg`, `legend/legendaspi-logo-show.svg`) that share the same `app/assets/images/legend/` folder as `Legend`'s icons rather than having a folder of their own — consistent with how the project's other Attivi/SPI pairs tend to reuse shared asset folders for variants of the same graphic concept.*

### Perché esiste come file separato invece di un `type` su `LegendsController`

> **IT:** Stessa motivazione già data per il modello (vedi `CodeGuide/LegendSpis/legend_spi.md`): Fitupe non introduce mai un discriminatore polimorfico per distinguere Attivi da SPI, preferisce due controller REST paralleli e completamente indipendenti, ciascuno con le proprie route (`resources :legends` / `resources :legend_spis` in `config/routes.rb`) e la propria policy (`LegendPolicy`/`LegendSpiPolicy`, identiche riga per riga). Il costo è la duplicazione vista qui; il beneficio è che ogni dominio può evolvere — o essere rimosso — senza toccare l'altro.
>
> *EN: Same reasoning already given for the model (see `CodeGuide/LegendSpis/legend_spi.md`): Fitupe never introduces a polymorphic discriminator to distinguish Attivi from SPI, it prefers two parallel, fully independent REST controllers, each with its own routes (`resources :legends` / `resources :legend_spis` in `config/routes.rb`) and its own policy (`LegendPolicy`/`LegendSpiPolicy`, identical line for line). The cost is the duplication seen here; the benefit is that each domain can evolve — or be removed — without touching the other.*
