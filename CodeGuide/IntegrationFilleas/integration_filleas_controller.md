# `IntegrationFilleasController`

**File:** `app/controllers/integration_filleas_controller.rb`

## Codice completo

```ruby
class IntegrationFilleasController < ApplicationController
  before_action :authenticate_user!
  before_action :set_integration_fillea, only: %i[show edit update destroy confirm_destroy]
  before_action :set_zonings, only: %i[new create edit update]

  def index
    authorize IntegrationFillea
    @integration_filleas = policy_scope(IntegrationFillea).includes(:zoning).order(zoning_id: :asc, year: :desc)
  end

  def show
  end

  def new
    @integration_fillea = IntegrationFillea.new
    authorize @integration_fillea
  end

  def create
    @integration_fillea = IntegrationFillea.new(integration_fillea_params)
    authorize @integration_fillea

    if @integration_fillea.save
      redirect_to integration_filleas_path, notice: "Integrazione FILLEA creata con successo."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @integration_fillea.update(integration_fillea_params)
      redirect_to integration_filleas_path, notice: "Integrazione FILLEA aggiornata con successo."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @integration_fillea.destroy
    redirect_to integration_filleas_path, notice: "Integrazione FILLEA eliminata con successo."
  end

  def confirm_destroy
  end

  private

  def set_integration_fillea
    @integration_fillea = IntegrationFillea.find(params[:id])
    authorize @integration_fillea
  end

  def set_zonings
    @zonings = Zoning.order(:codice_azzonamento)
  end

  def integration_fillea_params
    params.require(:integration_fillea).permit(:zoning_id, :year, :subscribers_ce)
  end
end
```

## Sezioni commentate

### L'intero controller — un CRUD standard, e questo È la decisione di design

> **IT:** A prima vista è il più anonimo dei controller del progetto: le sette azioni REST standard (`index, show, new, create, edit, update, destroy, confirm_destroy`), lo stesso schema `before_action`/`authorize`/`policy_scope` ripetuto quasi identico in decine di altri controller CRUD di Fitupe. Ma è proprio questa assenza di logica speciale che è la decisione di design da notare: `IntegrationFillea#subscribers_ce` (il totale iscritti Cassa Edile per provincia/anno) è inserito **manualmente** da un operatore, una volta all'inizio dell'anno — non c'è nessun file da caricare, nessun parsing, nessun servizio di confronto. Il contrasto più istruttivo è con l'integrazione FLC gemella: `IntegrationFlcsController` (CRUD manuale, quasi identico riga per riga a questo file) **coesiste** con un secondo controller, `IntegrationFlcUploadsController`, che avvolge `IntegrationFlcs::ComparisonService` per popolare `subscribers_af` automaticamente da un estratto CSV Anagrafe (vedi `CodeGuide/IntegrationFlcs/README.md`). FILLEA non ha — e non ha mai avuto — un controller di upload equivalente: l'unico modo per valorizzare `subscribers_ce` è questo form. La ragione è nei dati stessi: Cassa Edile fornisce un singolo numero per provincia/anno, non un elenco di codici fiscali da confrontare — non c'è nulla da "confrontare" con SinCGIL a livello di singolo iscritto come invece serve per FLC (vedi `IntegrationFlcs::ComparisonService`, che deve sapere quali codici fiscali mancano, non solo un totale).
>
> *EN: At first glance this is the most anonymous controller in the project: the seven standard REST actions (`index, show, new, create, edit, update, destroy, confirm_destroy`), the same `before_action`/`authorize`/`policy_scope` pattern repeated almost identically across dozens of other Fitupe CRUD controllers. But that very absence of special logic is the design decision worth noting: `IntegrationFillea#subscribers_ce` (the Cassa Edile member total per province/year) is entered **manually** by an operator, once at the start of the year — there's no file to upload, no parsing, no comparison service. The most instructive contrast is with the twin FLC integration: `IntegrationFlcsController` (a manual CRUD, almost line-for-line identical to this file) **coexists** with a second controller, `IntegrationFlcUploadsController`, which wraps `IntegrationFlcs::ComparisonService` to auto-populate `subscribers_af` from an Anagrafe CSV extract (see `CodeGuide/IntegrationFlcs/README.md`). FILLEA has no — and has never had — an equivalent upload controller: this form is the only way to set `subscribers_ce`. The reason is in the data itself: Cassa Edile provides a single number per province/year, not a list of codici fiscali to compare — there's nothing to "compare" against SinCGIL at the individual-member level the way FLC needs (see `IntegrationFlcs::ComparisonService`, which needs to know exactly which codici fiscali are missing, not just a total).*

### `index`

```ruby
def index
  authorize IntegrationFillea
  @integration_filleas = policy_scope(IntegrationFillea).includes(:zoning).order(zoning_id: :asc, year: :desc)
end
```

> **IT:** `authorize IntegrationFillea` (la classe, non un'istanza) è la forma Pundit standard per un'azione che non opera su un record specifico. `policy_scope(IntegrationFillea)` applica `IntegrationFilleaPolicy::Scope`, che qui restituisce tutto o niente in base al ruolo (`user.admin? || user.manager? ? scope.all : scope.none`) — non uno scope per-utente come `current_user.posts` visto nell'esempio di `CLAUDE.md`, perché le integrazioni non appartengono a un singolo utente, appartengono all'organizzazione. `includes(:zoning)` evita N+1 query quando la vista mostra il nome dell'azzonamento per ogni riga. L'ordinamento `zoning_id: :asc, year: :desc` raggruppa le righe per azzonamento e, dentro ogni azzonamento, mostra prima l'anno più recente — l'ordine più utile per un operatore che controlla se manca l'integrazione dell'anno corrente.
>
> *EN: `authorize IntegrationFillea` (the class, not an instance) is the standard Pundit form for an action that doesn't operate on a specific record. `policy_scope(IntegrationFillea)` applies `IntegrationFilleaPolicy::Scope`, which here returns everything-or-nothing based on role (`user.admin? || user.manager? ? scope.all : scope.none`) — not a per-user scope like `current_user.posts` from the `CLAUDE.md` example, because integrations don't belong to a single user, they belong to the organization. `includes(:zoning)` avoids N+1 queries when the view shows the zoning name for each row. The `zoning_id: :asc, year: :desc` ordering groups rows by zoning and, within each zoning, shows the most recent year first — the most useful order for an operator checking whether the current year's integration is missing.*

### `create`, `update`, `destroy` — nessuna sorpresa, ed è voluto

```ruby
def create
  @integration_fillea = IntegrationFillea.new(integration_fillea_params)
  authorize @integration_fillea

  if @integration_fillea.save
    redirect_to integration_filleas_path, notice: "Integrazione FILLEA creata con successo."
  else
    render :new, status: :unprocessable_entity
  end
end
```

> **IT:** Nessuna logica oltre `save`/`update`/`destroy` diretti sul modello — tutta la vera "logica di business" di questa risorsa (i vincoli su cosa rende valido un record) vive nelle validazioni del modello `IntegrationFillea` (vedi `CodeGuide/IntegrationFilleas/integration_fillea.md`), non nel controller. `authorize @integration_fillea` (l'istanza, non la classe) qui, a differenza di `index`, perché ora esiste un record specifico su cui verificare il permesso — anche se `IntegrationFilleaPolicy` in pratica applica la stessa regola `admin_or_manager?` a ogni azione, indipendentemente dal record. `status: :unprocessable_entity` su un salvataggio fallito è la convenzione HTTP standard del progetto per un form con errori di validazione, non un'eccezione o un redirect silenzioso.
>
> *EN: No logic beyond direct `save`/`update`/`destroy` on the model — all this resource's actual "business logic" (the constraints on what makes a record valid) lives in the `IntegrationFillea` model's validations (see `CodeGuide/IntegrationFilleas/integration_fillea.md`), not in the controller. `authorize @integration_fillea` (the instance, not the class) here, unlike `index`, because there's now a specific record to check permission against — even though `IntegrationFilleaPolicy` in practice applies the same `admin_or_manager?` rule to every action, regardless of the record. `status: :unprocessable_entity` on a failed save is the project's standard HTTP convention for a form with validation errors, not an exception or a silent redirect.*

### `integration_fillea_params` *(privato)*

```ruby
def integration_fillea_params
  params.require(:integration_fillea).permit(:zoning_id, :year, :subscribers_ce)
end
```

> **IT:** Strong parameters standard, senza `permit!` (coerente con la regola di sicurezza esplicita in `CLAUDE.md`). I tre campi ammessi corrispondono esattamente alle tre colonne che hanno senso per un utente: `zoning_id`/`year` identificano il periodo, `subscribers_ce` è l'unico dato effettivamente inserito manualmente — nessun campo di sistema (`created_at`, ecc.) è mai esposto.
>
> *EN: Standard strong parameters, no `permit!` (consistent with the explicit security rule in `CLAUDE.md`). The three allowed fields match exactly the three columns that make sense for a user: `zoning_id`/`year` identify the period, `subscribers_ce` is the one piece of data actually entered by hand — no system field (`created_at`, etc.) is ever exposed.*
