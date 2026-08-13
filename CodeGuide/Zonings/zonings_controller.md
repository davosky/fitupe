# `ZoningsController`

**File:** `app/controllers/zonings_controller.rb`

## Codice completo

```ruby
class ZoningsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_zoning, only: %i[show edit update destroy confirm_destroy]

  def index
    authorize Zoning
    @zonings = policy_scope(Zoning).order(:codice_azzonamento)
  end

  def show
  end

  def new
    @zoning = Zoning.new
    authorize @zoning
  end

  def create
    @zoning = Zoning.new(zoning_params)
    authorize @zoning

    if @zoning.save
      redirect_to zonings_path, notice: "Azzonamento creato con successo."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @zoning.update(zoning_params)
      redirect_to zonings_path, notice: "Azzonamento aggiornato con successo."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @zoning.destroy
    redirect_to zonings_path, notice: "Azzonamento eliminato con successo."
  end

  def confirm_destroy
  end

  private

  def set_zoning
    @zoning = Zoning.find(params[:id])
    authorize @zoning
  end

  def zoning_params
    params.require(:zoning).permit(:codice_azzonamento, :descrizione_azzonamento)
  end
end
```

## Sezioni commentate

### L'intero controller — CRUD standard sulla radice di tutta la gerarchia geografica

> **IT:** Struttura identica a decine di altri CRUD di Fitupe (`before_action`/`authorize`/`policy_scope`, sette azioni REST standard), ma il record che gestisce è particolare: `Zoning` è la tabella da cui **dipende** ogni altra risorsa del progetto — `Import`, `ImportSpi`, `IntegrationFillea`, `IntegrationFlc`, `Legend`, `LegendSpi` la referenziano tutte, e ogni servizio statistico costruisce sopra `regionale?`/`comprensori_di` (vedi `CodeGuide/Zonings/zoning.md`). Questo controller non ha bisogno di `set_zonings` (non esiste una select box di azzonamenti-figli da precaricare, a differenza di `LegendsController`/`LegendSpisController`/`IntegrationFilleasController`/`IntegrationFlcsController`, che referenziano `Zoning` come foreign key e quindi hanno tutti un `before_action :set_zonings` per popolare la `collection_select` del form) — qui l'azzonamento **è** la risorsa, non un riferimento da un'altra. Nota che il controller stesso non impone alcun vincolo sul formato di `codice_azzonamento` (una sola cifra per il livello regionale, più lunga per i comprensori): quella regola vive interamente nella convenzione seguita da chi inserisce i dati, non in una validazione — `Zoning#regionale?` la *legge*, non la *impone*.
>
> *EN: Structurally identical to dozens of other Fitupe CRUDs (`before_action`/`authorize`/`policy_scope`, seven standard REST actions), but the record it manages is a special one: `Zoning` is the table every other resource in the project **depends on** — `Import`, `ImportSpi`, `IntegrationFillea`, `IntegrationFlc`, `Legend`, `LegendSpi` all reference it, and every statistics service builds on top of `regionale?`/`comprensori_di` (see `CodeGuide/Zonings/zoning.md`). This controller doesn't need a `set_zonings` (there's no select box of child zonings to preload, unlike `LegendsController`/`LegendSpisController`/`IntegrationFilleasController`/`IntegrationFlcsController`, which all reference `Zoning` as a foreign key and so all carry a `before_action :set_zonings` to populate the form's `collection_select`) — here the zoning **is** the resource, not a reference from another one. Note that the controller itself enforces no constraint on the shape of `codice_azzonamento` (a single character for the regional level, longer for comprensori): that rule lives entirely in the convention followed by whoever enters the data, not in a validation — `Zoning#regionale?` *reads* it, it doesn't *enforce* it.*

### `index`

```ruby
def index
  authorize Zoning
  @zonings = policy_scope(Zoning).order(:codice_azzonamento)
end
```

> **IT:** `order(:codice_azzonamento)` è un ordinamento alfabetico sul codice, non su `descrizione_azzonamento` — con il formato di codifica per prefisso documentato in `zoning.md` (regione a una cifra seguita dai suoi comprensori), questo ordinamento ha un effetto collaterale utile: ogni azzonamento regionale compare immediatamente prima dei propri comprensori figli nell'elenco (es. `"G"`, poi `"GB"`, `"GC"`, ...), perché l'ordinamento lessicografico delle stringhe rispetta naturalmente la gerarchia dei prefissi. Non è documentato come intenzionale nel codice, ma è coerente con il modo in cui `descrizione_azzonamento` viene usata altrove solo come etichetta leggibile, mai come chiave di ordinamento.
>
> *EN: `order(:codice_azzonamento)` orders alphabetically by code, not by `descrizione_azzonamento` — given the prefix-based encoding documented in `zoning.md` (a single-character region followed by its comprensori), this ordering has a useful side effect: every regional zoning appears immediately before its child comprensori in the list (e.g. `"G"`, then `"GB"`, `"GC"`, ...), because lexicographic string ordering naturally respects prefix hierarchy. It isn't documented as intentional in the code, but it's consistent with how `descrizione_azzonamento` is used everywhere else purely as a human-readable label, never as a sort key.*

### `create`, `update`, `destroy` — e perché `destroy` può fallire silenziosamente qui più che altrove

```ruby
def destroy
  @zoning.destroy
  redirect_to zonings_path, notice: "Azzonamento eliminato con successo."
end
```

> **IT:** Come in ogni altro CRUD del progetto, `destroy` non controlla il valore di ritorno né gestisce l'eventuale fallimento: se `Zoning#destroy` fallisce per via dei cinque vincoli `dependent: :restrict_with_error` (vedi `zoning.md` — un azzonamento con importazioni, integrazioni o legende collegate non può essere eliminato), l'utente viene comunque rediretto a `zonings_path` con il messaggio "eliminato con successo", anche se **non è stato eliminato**. Questo è lo stesso pattern (non un bug isolato) presente in tutti gli altri controller CRUD di Fitupe che condividono questo schema `destroy` senza `if @record.destroy` — ma qui l'impatto pratico è più alto: `Zoning` è quasi sempre referenziato da qualcosa (è la radice della gerarchia geografica), quindi `destroy` su un azzonamento in uso fallirà silenziosamente più spesso che su altre risorse più "foglia". `confirm_destroy` mitiga il rischio di click accidentali, ma non intercetta questo caso: la conferma chiede solo "sei sicuro?", non verifica se l'eliminazione andrà effettivamente a buon fine.
>
> *EN: Like every other CRUD in the project, `destroy` doesn't check the return value or handle a possible failure: if `Zoning#destroy` fails because of the five `dependent: :restrict_with_error` constraints (see `zoning.md` — a zoning with attached imports, integrations, or legends can't be deleted), the user is still redirected to `zonings_path` with the "deleted successfully" message, even though it **was not deleted**. This is the same pattern (not an isolated bug) present in every other Fitupe CRUD controller that shares this `destroy` shape without an `if @record.destroy` guard — but the practical impact is higher here: `Zoning` is almost always referenced by something (it's the root of the geographic hierarchy), so `destroy` on an in-use zoning will silently fail more often than on other, more "leaf" resources. `confirm_destroy` mitigates accidental clicks, but doesn't catch this case: the confirmation only asks "are you sure?", it doesn't verify the deletion will actually succeed.*

### `zoning_params` *(privato)*

```ruby
def zoning_params
  params.require(:zoning).permit(:codice_azzonamento, :descrizione_azzonamento)
end
```

> **IT:** Solo due campi ammessi, e sono esattamente le due colonne validate dal modello (`codice_azzonamento`, `descrizione_azzonamento` — vedi `zoning.md`). Nessun campo per esprimere esplicitamente la gerarchia (niente `parent_id`): coerente con la scelta del modello di codificarla per prefisso dentro `codice_azzonamento` stesso, non con una relazione separata da gestire nel form.
>
> *EN: Only two fields allowed, and they're exactly the two columns validated by the model (`codice_azzonamento`, `descrizione_azzonamento` — see `zoning.md`). No field to explicitly express the hierarchy (no `parent_id`): consistent with the model's choice to encode it by prefix inside `codice_azzonamento` itself, not via a separate relationship to manage in the form.*
