# CLAUDE.md — Guida per Claude Code

---

## 🏗️ Stack Tecnico

```
Ruby:        >= 4.0.1
Rails:       >= 8.1.3
Database:    PostgreSQL
Frontend:    Hotwire (Turbo + Stimulus)
CSS:         Bootstrap >= 5.3.8 (https://getbootstrap.com/docs/5.3/getting-started/introduction/) + Bootswatch Styles (https://bootswatch.com/)
Testing:     RSpec + FactoryBot + Capybara
Deploy:      Alma Linux + Apache + Phusion Passenger Community Edition (https://www.phusionpassenger.com/docs/tutorials/what_is_passenger/)
```

---

## 📁 Struttura del Progetto

```
app/
  controllers/        # Solo logica HTTP, niente business logic
  models/             # Validazioni, relazioni, scopes, niente logica complessa
  services/           # Business logic: NomeServizio.call(params)
  jobs/               # Background jobs usando rails 8
  views/              # ERB + partials + Turbo Frames/Streams
  components/         # ViewComponent (se usato)
  javascript/         # Stimulus controllers
```

---

## 🤝 Convenzioni di Codice

### Generale

- Lingua dei commenti e dei nomi variabili: inglese
- Lingua dei model, controller, helper, job, service, mailer, view e javascript: inglese
- Lingua delle tabelle e delle colonne: inglese
- Segui i principi di **Rails Way** — convention over configuration
- Metodi privati sempre in fondo alla classe, separati da `private`
- Massimo 10 righe per metodo, massimo 100 righe per classe

### Modelli

- Scopes con lambda: `scope :active, -> { where(active: true) }`
- Validazioni raggruppate per attributo
- Relazioni in cima al file, prima delle validazioni

### Controller

- Solo 8 azioni REST standard + custom (index, show, new, create, edit, update, destroy, confirm_destroy)
- `before_action` per autenticazione e `set_risorsa`
- Risposta JSON sempre con `render json:` non con `to_json`

### Naming

- Controller: plurale (`UsersController`, `PostsController`)
- Modelli: singolare (`User`, `Post`)
- Jobs: `NomeJob` (`WelcomeEmailJob`, `CleanupJob`)
- Tabelle DB: snake_case plurale (`users`, `blog_posts`)

---

## 🧪 Testing

**Approccio: Test-first quando possibile**

```
spec/
  models/           # Unit test su validazioni, metodi, scopes
  controllers/      # Request specs (non controller specs)
  services/         # Unit test su ogni servizio
  system/           # Feature test E2E con Capybara
  factories/        # FactoryBot — una factory per modello
  support/          # Helper condivisi, shared examples
```

### Regole per i Test

- Usa `let` e `let!` (non variabili di istanza in `before`)
- Factories sempre minimali — trait per variazioni
- Un `describe` per classe, un `context` per scenario
- Nomi test leggibili: `"quando l'utente non è autenticato"`
- Coverage minima attesa: **90%** per modelli e services

```ruby
# Esempio factory minima
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { "password123" }

    trait :admin do
      role { :admin }
    end
  end
end
```

---

## 🗄️ Database

- Migrazioni sempre reversibili (usa `reversible do` se necessario)
- Indici su tutte le foreign keys e colonne usate in query frequenti
- Evita `default_scope` — preferisci scopes espliciti
- Per dati sensibili: usa `attr_encrypted` o Rails credentials
- Bulk operations: usa `insert_all` / `update_all` invece di loop

```ruby
# ✅ Migrazione con indice
add_column :posts, :user_id, :bigint, null: false
add_index :posts, :user_id
add_foreign_key :posts, :users
```

---

## 🔒 Sicurezza

- Autenticazione: **Devise**
- Autorizzazione: **Pundit** (policy per ogni modello)
- Params sempre con `strong_parameters` — niente `permit!`
- Query con scope dell'utente corrente (mai esporre dati di altri)
- Secrets in `Rails.application.credentials` o variabili d'ambiente

```ruby
# ✅ Sempre scoped all'utente
def set_post
  @post = current_user.posts.find(params[:id])
  # NON: Post.find(params[:id])
end
```

---

## ⚡ Performance

- N+1 queries: usa `includes`, `preload`, `eager_load`
- Cache: `Rails.cache.fetch` per query costose
- Background jobs per operazioni > 200ms (email, PDF, API calls)
- Paginazione sempre con **Pagy** o Kaminari
- `select` esplicito se non servono tutte le colonne

---

## 🚀 Workflow con Claude Code

### Come fare una richiesta efficace

1. Descrivi la **feature** dal punto di vista dell'utente
2. Specifica i **model coinvolti**
3. Indica se vuoi **test inclusi** (di default: sì)
4. Segnala **vincoli** (performance, sicurezza, backward compat)

### Esempio di prompt efficace

```
"Aggiungi la possibilità per gli utenti di commentare i Post.
Un commento ha: testo (max 500 chars), autore (User), e può
essere risposta ad altro commento (thread a un livello).
Include validazioni, migration, RSpec specs e il partial Turbo
per aggiungere commenti senza reload della pagina."
```

### Cose che Claude Code può fare autonomamente

- Creare/modificare migrations e modelli
- Scrivere e lanciare RSpec
- Aggiungere routes e controller actions
- Creare views con Turbo Frames
- Installare e configurare gem standard

### Cose su cui chiedere conferma prima

- Modifiche a tabelle con dati in produzione
- Cambio di gem di autenticazione o autorizzazione
- Refactoring di servizi core
- Modifiche alle Rails credentials

---

## 📦 Gem Principali (personalizza)

```ruby
# Gemfile — gem comuni in questo progetto
gem "administrate"
gem "bcrypt"
gem "bootsnap"
gem "cssbundling-rails"
gem "csv"
gem "capybara"
gem "devise"
gem "devise-i18n"
gem "dotenv-rails"
gem "factory_bot_rails"
gem "faker"
gem "image_processing"
gem "jbuilder"
gem "jsbundling-rails"
gem "kamal"
gem "pagy"
gem "pg"
gem "propshaft"
gem "puma"
gem "pundit"
gem "rails"
gem "rails-i18n"
gem "rspec-rails"
gem "solid_cable"
gem "solid_cache"
gem "solid_queue"
gem "stimulus-rails"
gem "thruster"
gem "turbo-rails"
gem "tzinfo-data"
gem "view_component"
```

---

## 🌍 Variabili d'Ambiente Richieste

```bash
DATABASE_HOST=         # PostgreSQL host es. localhost
DATABASE_USER=		     # db username
DATABASE_PASSWORD=     # db password
SECRET_KEY_BASE=       # generata con rails secret
```

---

## 📋 Comandi Utili

```bash
# Setup
bin/setup                          # setup iniziale
bundle exec rails db:reset         # reset DB con seed

# Test
bundle exec rspec                  # tutti i test
bundle exec rspec spec/models/     # solo model specs
bundle exec rspec --format doc     # output leggibile

# Qualità codice
bundle exec rubocop -A             # auto-fix stile
bundle exec brakeman               # security check

# Development
bin/dev                            # avvia tutti i processi (Procfile.dev)
bundle exec rails console          # console interattiva
bundle exec rails routes | grep X  # cerca routes
```

---

## ❌ Anti-Pattern da Evitare

- ❌ Logica nei controller oltre `set_`, `require_`, `redirect`
- ❌ Callback nei modelli per logica di business (`after_create`, ecc.)
- ❌ Query nei views
- ❌ `rescue Exception` (usa `rescue StandardError` o classi specifiche)
- ❌ `update_all` senza `where` (aggiorna tutta la tabella!)
- ❌ Variabili globali (`$variabile`)
- ❌ Logica nei migrations — solo schema, dati nei seeds/tasks

---

## 📈 Graphify

Questo progetto deve disporre di un grafo della conoscenza situato in `graphify-out/`, contenente nodi principali ("god nodes"), struttura delle comunità e relazioni tra i file. Pertanto si richiede l'installazione e la configurazione di graphify.

Regole:

- Per domande sulla codebase, esegui prima `graphify query "<domanda>"` una volta generato il file `graphify-out/graph.json`. Usa `graphify path "<A>" "<B>"` per le relazioni e `graphify explain "<concetto>"` per approfondire concetti specifici. Questi comandi restituiscono un sottografo circoscritto, solitamente molto più ridotto rispetto a `GRAPH_REPORT.md` o all'output grezzo di `grep`.
- Se esiste il file `graphify-out/wiki/index.md`, utilizzalo per una navigazione generale anziché esplorare direttamente il codice sorgente.
- Consulta `graphify-out/GRAPH_REPORT.md` solo per una panoramica dell'architettura o quando i comandi `query`, `path` o `explain` non forniscono un contesto sufficiente.
- Dopo aver modificato il codice, esegui `graphify update .` per mantenere aggiornato il grafo (operazione basata solo sull'AST, senza costi API).

## 🖥️ Costruzione dell'applicazione

---

*Nome dell'applicazione:* **Fitupe**, leggi il file FITUPE.md per la spiegazione del nome e del logo.

*Scopo dell'applicazione:* Creare statistiche coerenti riguardo l'andamento delle iscrizioni al sindacato.

**Per incominciare costruiamo l'ossatura della applicazione:**

- database:
  - RDBMS: Postgresql >= 18
  - database development: fitupe_development
  - database test: fitupe_test
  - DATABASE_HOST= localhost
    DATABASE_USER= user
    DATABASE_PASSWORD=password
  - usa dotenv-rails per gestire gli accessi ai database
- interfaccia grafica:
  - framework front-end: Bootstrap >= 5.2 (https://getbootstrap.com/docs/5.2/getting-started/introduction/)
  - personalizzazione:  Bootswatch variante Lumen (https://bootswatch.com/lumen/)
- javascript
  - bundler: ESbuild
  - preferire la creazione di controller Stimulus per qualsiasi codice javascript
- autenticazione
  - autenticazione usando la gemma Devise
  - il campo principale per l'autenticazione deve essere **username** e non email
  - ottimizzare Devise in modo che sia compatibile con tutbo-rails
- amministrazione
  - usare la gemma Administrate
  - per ogni modello creato viene creato automaticamente un pannello corrispondente in Administrate
- autorizzazione
  - utillizzare la gemma Pundit per gestire le autorizzazioni degli utenti
  - l'utente con il flag **admin = true** può fare qualsiasi cosa ed ha i permessi più alti

**Disposizione dell'interfaccia principale ad accesso non avvenuto**

Una pagina unica con al centro il logo dell'applicazione e una card dove sono presenti l'inserimento del nome-utente e della password.

**Disposizione dell'interfaccia principale ad accesso avvenuto**

1. utilizzare una barra di navigazione posta in alto
   - inserire a sinistra il nome dell'applicazione
   - inserire a destra un menù a discesa con i link per il logout, per administrate e per la pagina credits
2. contenitore principale
   - creare un controller con due pagine, index e credits
   - associare la pagina index alla root dell'applicazione
   - inserire sulla pagina index al centro il logo dell'applicazione
   - inserire subito sotto il logo una brevissima spiegazione delle mansioni dell'applicazione
3. creazione degli utenti
   - creare un modello User con devise con i seguenti campi:
     - username: string (campo principale per l'autenticazione che deve essere indicizzato)
     - first_name:string
     - last_name:string
     - gender:string
     - region:string
     - province:string
     - category:string
     - admin:boolean
     - manager:boolean
     - regular:boolean
   - creare un primo utente amministratore con i seguenti dati
     - username:utente
     - password:password
     - password_confirmation:password
     - first_name:Davo
     - last_name:Davosky
     - gender:M
     - region:FVG
     - province:FVG
     - category:CGIL
     - admin:true
     - manager:false
     - regular:false
   - creare le views di devise

---

**NOTA BENE:**

i database **fitupe_development** e **fitupe_test** sono già stati creati e sono subito utilizzabili.
