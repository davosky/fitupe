# `LegendsController`

**File:** `app/controllers/legends_controller.rb`

## Codice completo

```ruby
class LegendsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_legend, only: %i[show edit update destroy confirm_destroy]
  before_action :set_zonings, only: %i[new create edit update]

  def index
    authorize Legend
    @legends = policy_scope(Legend).includes(:zoning).order(year: :desc, month: :desc)
  end

  def show
  end

  def new
    @legend = Legend.new
    authorize @legend
  end

  def create
    @legend = Legend.new(legend_params)
    authorize @legend

    if @legend.save
      redirect_to legends_path, notice: "Legenda creata con successo."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @legend.update(legend_params)
      redirect_to legends_path, notice: "Legenda aggiornata con successo."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @legend.destroy
    redirect_to legends_path, notice: "Legenda eliminata con successo."
  end

  def confirm_destroy
  end

  private

  def set_legend
    @legend = Legend.find(params[:id])
    authorize @legend
  end

  def set_zonings
    @zonings = Zoning.order(:codice_azzonamento)
  end

  def legend_params
    params.require(:legend).permit(:zoning_id, :year, :month, :description)
  end
end
```

## Sezioni commentate

### L'intero controller — CRUD standard, la stessa forma di `IntegrationFilleasController`

> **IT:** Stesso schema `before_action`/`authorize`/`policy_scope` di ogni altro CRUD Fitupe, con l'aggiunta di `set_zonings` (`before_action`, azioni `new create edit update`) per popolare la `collection_select` del form — pattern condiviso con `IntegrationFilleasController`/`IntegrationFlcsController` e, gemello per gemello, con `LegendSpisController` (vedi `CodeGuide/LegendSpis/legend_spis_controller.md`, quasi identico a questo file salvo il nome della risorsa). A differenza di `ZoningsController`, qui `set_zonings` serve perché `Legend` **referenzia** un azzonamento tramite `zoning_id` (una foreign key, non la risorsa stessa) — il form deve offrire l'elenco completo degli azzonamenti tra cui scegliere.
>
> *EN: Same `before_action`/`authorize`/`policy_scope` shape as every other Fitupe CRUD, plus `set_zonings` (`before_action`, `new create edit update` actions) to populate the form's `collection_select` — a pattern shared with `IntegrationFilleasController`/`IntegrationFlcsController` and, twin for twin, with `LegendSpisController` (see `CodeGuide/LegendSpis/legend_spis_controller.md`, nearly identical to this file except for the resource name). Unlike `ZoningsController`, `set_zonings` is needed here because `Legend` **references** a zoning via `zoning_id` (a foreign key, not the resource itself) — the form has to offer the full list of zonings to choose from.*

### `index`

```ruby
def index
  authorize Legend
  @legends = policy_scope(Legend).includes(:zoning).order(year: :desc, month: :desc)
end
```

> **IT:** `order(year: :desc, month: :desc)` mostra prima le legende più recenti, senza raggruppare per azzonamento (a differenza di `IntegrationFilleasController#index`, che ordina `zoning_id: :asc, year: :desc` — raggruppato per azzonamento). La differenza riflette l'uso: le integrazioni FILLEA si controllano azzonamento per azzonamento ("manca l'integrazione di questa provincia?"), le legende si scrivono e si rivedono cronologicamente ("qual è l'ultima legenda che ho compilato?"). `includes(:zoning)` evita N+1 quando la vista mostra `legend.zoning.descrizione_azzonamento` per ogni riga (vedi `app/views/legends/index.html.erb`).
>
> *EN: `order(year: :desc, month: :desc)` shows the most recent legends first, without grouping by zoning (unlike `IntegrationFilleasController#index`, which orders `zoning_id: :asc, year: :desc` — grouped by zoning). The difference reflects usage: FILLEA integrations are checked zoning by zoning ("is this province's integration missing?"), legends are written and reviewed chronologically ("what's the last legend I filled in?"). `includes(:zoning)` avoids N+1 queries when the view shows `legend.zoning.descrizione_azzonamento` for every row (see `app/views/legends/index.html.erb`).*

### `legend_params` *(privato)* — il quarto campo, `description`

```ruby
def legend_params
  params.require(:legend).permit(:zoning_id, :year, :month, :description)
end
```

> **IT:** `description` è permesso qui esattamente come un campo qualsiasi, anche se lato modello non è una colonna reale (vedi `has_rich_text` in `CodeGuide/Legends/legend.md`) — ActionText espone comunque un setter `description=` che accetta l'HTML grezzo inviato dal Trix editor, quindi `permit` funziona senza bisogno di trattamenti speciali. Rispetto a `IntegrationFilleasController#integration_fillea_params` (tre campi), qui ce n'è un quarto: `month`, perché `Legend` è granulare per mese mentre `IntegrationFillea` è granulare per anno (vedi `CodeGuide/Legends/legend.md`).
>
> *EN: `description` is permitted here just like any other field, even though on the model side it isn't a real column (see `has_rich_text` in `CodeGuide/Legends/legend.md`) — ActionText still exposes a `description=` setter that accepts the raw HTML sent by the Trix editor, so `permit` works with no special handling needed. Compared to `IntegrationFilleasController#integration_fillea_params` (three fields), there's a fourth one here: `month`, because `Legend` is granular per month while `IntegrationFillea` is granular per year (see `CodeGuide/Legends/legend.md`).*
