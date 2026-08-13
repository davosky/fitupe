# `PagesController`

**File:** `app/controllers/pages_controller.rb`

## Codice completo

```ruby
class PagesController < ApplicationController
  before_action :authenticate_user!

  def index
  end

  def credits
  end
end
```

## Sezioni commentate

### La classe intera — il controller più piccolo del progetto, e perché non ha bisogno di più di questo

> **IT:** Due azioni vuote, nessun `set_risorsa`, nessuna chiamata a `authorize`/`policy_scope`, nessun modello associato. `PagesController` esiste per una sola ragione strutturale, dichiarata in `CLAUDE.md`: dare un posto REST-convenzionale a `index` (montata sulla root dell'applicazione, `root "pages#index"` in `config/routes.rb`) e a `credits` (`get "credits", to: "pages#credits"`), le due pagine statiche che non appartengono a nessun'altra risorsa. Il corpo vuoto di entrambe le azioni è corretto, non incompleto: tutto il contenuto (il logo, la breve spiegazione dello scopo dell'app su `index`; l'acronimo del nome, il significato del logo, i crediti su `credits`) è puramente statico nella view — non c'è nessuna query, nessun dato da caricare in un'istanza. Confrontato con ogni altro controller del progetto (che seguono tutti lo schema `before_action :set_risorsa` + `authorize`), `PagesController` è l'unico che non gestisce un modello ActiveRecord — non ha una `Pundit::Policy` corrispondente, e non ne ha bisogno: non c'è nessun record da autorizzare, solo due pagine che chiunque sia autenticato può vedere.
>
> *EN: Two empty actions, no `set_resource`, no call to `authorize`/`policy_scope`, no associated model. `PagesController` exists for a single structural reason, stated in `CLAUDE.md`: to give a REST-conventional home to `index` (mounted at the application root, `root "pages#index"` in `config/routes.rb`) and `credits` (`get "credits", to: "pages#credits"`), the two static pages that don't belong to any other resource. The empty body of both actions is correct, not incomplete: all the content (the logo, the short explanation of the app's purpose on `index`; the name's acronym, the logo's meaning, the credits on `credits`) is purely static in the view — there's no query, no data to load into an instance variable. Compared to every other controller in the project (which all follow the `before_action :set_resource` + `authorize` pattern), `PagesController` is the only one that doesn't manage an ActiveRecord model — it has no corresponding `Pundit::Policy`, and doesn't need one: there's no record to authorize, just two pages any authenticated user can view.*

### `before_action :authenticate_user!` — l'unica riga di logica dell'intero file

```ruby
before_action :authenticate_user!
```

> **IT:** L'unica protezione applicata è Devise (autenticazione: bisogna essere loggati), non Pundit (autorizzazione: quale ruolo può fare cosa) — coerente con la scelta del progetto di riservare Pundit alle risorse con dati da proteggere per ruolo (`admin`/`manager`/`regular`, vedi `CLAUDE.md`). `index` e `credits` non espongono nulla che differisca per ruolo: un utente `regular` vede esattamente lo stesso logo e lo stesso testo di un `admin`. Se in futuro una di queste due pagine mostrasse contenuto diverso in base al ruolo, sarebbe il segnale che quella logica dovrebbe uscire da qui e diventare una risorsa a sé, con la propria policy — non un `if current_user.admin?` sparso nella view.
>
> *EN: The only protection applied is Devise (authentication: you must be logged in), not Pundit (authorization: which role can do what) — consistent with the project's choice to reserve Pundit for resources with data that needs protecting by role (`admin`/`manager`/`regular`, see `CLAUDE.md`). `index` and `credits` don't expose anything that differs by role: a `regular` user sees exactly the same logo and text as an `admin`. If either of these two pages ever needed to show different content based on role, that would be the signal that the logic should move out of here into a resource of its own, with its own policy — not an `if current_user.admin?` scattered through the view.*
