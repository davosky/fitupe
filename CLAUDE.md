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
- **Due utenti separati, mai le stesse credenziali**:
  - un utente per il **database di sviluppo**, con credenziali reali che non devono mai essere pubblicate (niente `db/seeds.rb`, niente commit, niente CLAUDE.md) — va creato/impostato a mano in locale (es. `rails console` o `rails runner`)
  - un utente per il **database di test e per `db/seeds.rb`**, con credenziali palesemente fittizie (es. `utente` / `pAssword1234567`) sicure da avere nel repo pubblico

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



# 🔑 Best Practice Essenziali di Sicurezza per Ruby on Rails

​                          

**Di [Harsh Patel](https://www.linkedin.com/in/harsh-patel-072379142/), Cyber Security Enthusiast & Senior Ruby on Rails Dev**

Ruby on Rails ha permesso a innumerevoli sviluppatori di creare applicazioni web in modo rapido ed elegante. Tuttavia, a un grande potere corrisponde una grande responsabilità. Nel panorama delle minacce odierno, mettere in sicurezza la propria applicazione Rails non è opzionale: è una necessità assoluta. In questa guida completa, ti accompagnerò attraverso le best practice di sicurezza essenziali che ogni sviluppatore Rails, dal livello intermedio all'avanzato, dovrebbe conoscere e implementare immediatamente per proteggere le proprie applicazioni dalle vulnerabilità più comuni e dalle minacce emergenti.

------

## Introduzione e Contesto

Nel mondo dello sviluppo web, la sicurezza è un pilastro fondamentale per un software sostenibile e affidabile. Con la filosofia di Rails "convention over configuration", molte funzionalità di sicurezza sono già integrate, ma questo non significa che ci si possa permettere di abbassare la guardia. Le applicazioni web sono costantemente prese di mira da attaccanti che sfruttano debolezze come:

- **SQL Injection:** query malevole che manipolano il database.
- **Cross-Site Scripting (XSS):** iniezione di script malevoli nelle pagine web.
- **Session Hijacking:** furto o manipolazione dei dati di sessione.
- **Cross-Site Request Forgery (CSRF):** comandi non autorizzati trasmessi da un utente di cui l'applicazione web si fida.
- **Upload di File Insicuri:** sfruttamento degli allegati per eseguire codice arbitrario.
- **Esposizione di Dati Sensibili:** perdita di segreti e dettagli di configurazione.

Per un'applicazione Rails di livello produzione, è essenziale un approccio alla sicurezza proattivo e a più livelli. Le seguenti best practice coprono le vulnerabilità più comuni e forniscono esempi di codice concreti e spiegazioni che puoi integrare immediatamente nei tuoi progetti.

------

## Best Practice di Sicurezza Chiave in Ruby on Rails

### 1. Protezione dall'SQL Injection

**Definizione:**

 L'SQL Injection si verifica quando l'input dell'utente non viene sanificato correttamente, permettendo agli attaccanti di modificare le query SQL. Questo può portare a furto di dati, perdita di dati o azioni amministrative non autorizzate.

**Come Nascono le Vulnerabilità:**

 Utilizzando l'interpolazione di stringhe per costruire query SQL:

```
# Esempio di codice vulnerabile:
name = params[:name]
@projects = Project.where("name LIKE '#{name}'")
```

​             

**Implementazione della Best Practice:**

 Utilizza le query parametrizzate di ActiveRecord e i metodi di sanificazione integrati per prevenire l'SQL injection.

```
# Esempio di codice sicuro:
@projects = Project.where("name LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:name])}%")
```

​             

**Spiegazione:**  

- Le **query parametrizzate** effettuano automaticamente l'escape dei caratteri pericolosi.
- **sanitize_sql_like** è particolarmente utile quando si usano i wildcard, garantendo che i caratteri speciali SQL vengano gestiti in modo sicuro.

------

### 2. Mitigazione del Cross-Site Scripting (XSS)

**Definizione:**

 Le vulnerabilità XSS si verificano quando gli attaccanti iniettano JavaScript o HTML malevoli nelle tue pagine web, potenzialmente rubando i dati dell'utente o eseguendo azioni non autorizzate nel browser dell'utente.

**Come Nascono le Vulnerabilità:**

 Restituendo direttamente l'input dell'utente senza una corretta sanificazione:

```
<!-- Esempio di template ERB vulnerabile: -->
<%= raw @product.description %>
```

​             

**Implementazione della Best Practice:**

 Sfrutta l'escaping HTML automatico di Rails e utilizza gli helper di sanificazione quando è necessario consentire HTML limitato.

```
<!-- Esempio di template ERB sicuro: -->
<%= @product.description %>
```

​             

Se devi consentire HTML:

```
# Utilizzo dell'helper sanitize per consentire tag specifici:
allowed_tags = %w[b i u p br]
@safe_content = sanitize(params[:content], tags: allowed_tags)
```

​             

**Spiegazione:**  

- Rails effettua l'auto-escaping per default per prevenire l'XSS.
- L'helper **sanitize** può essere utilizzato per creare una whitelist di tag HTML sicuri quando è richiesto contenuto generato dall'utente.

------

### 3. Gestione Sicura di Segreti, Credenziali e Dati di Configurazione Sensibili

**Definizione:**

 Memorizzare informazioni sensibili come chiavi API, credenziali del database e token segreti in chiaro o nel controllo di versione espone la tua applicazione a rischi gravi.

**Come Nascono le Vulnerabilità:**

 Includendo i segreti direttamente nei file di configurazione:

```
# Cattiva pratica: config/secrets.yml contenente credenziali in chiaro
production:
  secret_key_base: "super_secret_key"
```

​             

**Implementazione della Best Practice:**

 Utilizza le credenziali crittografate di Rails e le variabili d'ambiente per memorizzare i dati sensibili in modo sicuro.

```
# Per modificare le credenziali in Rails 6+:
EDITOR="vim" rails credentials:edit
```

​             

All'interno del file delle credenziali crittografate, memorizza i segreti in modo sicuro:

```
# config/credentials.yml.enc (esempio di contenuto)
aws:
  access_key_id: your_access_key_id
  secret_access_key: your_secret_access_key
secret_key_base: your_production_secret_key
```

​             

E accedi ad essi nella tua applicazione:

```
# Accesso sicuro alle credenziali:
Rails.application.credentials.aws[:access_key_id]
Rails.application.credentials.secret_key_base
```

​             

**Spiegazione:**  

- Le **credenziali crittografate di Rails** garantiscono che i dati sensibili rimangano crittografati a riposo e siano accessibili solo con la master key, che non deve mai essere inclusa nel controllo di versione.
- Le variabili d'ambiente e strumenti come **dotenv-rails** possono gestire ulteriormente la configurazione al di fuori del codice base.

------

### 4. Corretta Gestione delle Sessioni e Cookie Sicuri

**Definizione:**

 Le sessioni tracciano lo stato dell'utente tra le richieste, ma sessioni gestite in modo improprio possono portare a hijacking o attacchi di replay.

**Come Nascono le Vulnerabilità:**

 Utilizzando le impostazioni predefinite dei cookie senza miglioramenti di sicurezza:

```
# Session store predefinito (rischio potenziale):
YourApp::Application.config.session_store :cookie_store, key: '_your_app_session'
```

​             

**Implementazione della Best Practice:**

 Migliora la sicurezza delle sessioni utilizzando session store lato server e impostando opzioni sicure per i cookie.

**ActiveRecord Session Store:**

```
# Nel Gemfile:
gem 'activerecord-session_store'

# Genera la migration ed esegui la migrazione:
rails generate active_record:session_migration
rails db:migrate

# Configura il session store:
YourApp::Application.config.session_store :active_record_store, key: '_your_app_session'
```

​             

**Miglioramenti alla Sicurezza dei Cookie:**

```
# config/environments/production.rb:
Rails.application.configure do
  config.force_ssl = true  # Forza HTTPS
  config.session_store :cookie_store, key: '_your_app_session', secure: Rails.env.production?, httponly: true, same_site: :lax
end
```

​             

**Spiegazione:**  

- I **session store lato server** riducono l'esposizione poiché i dati di sessione vengono mantenuti sul server.
- I flag di sicurezza dei cookie (`secure`, `httponly` e `same_site`) garantiscono che i cookie vengano inviati solo su HTTPS, non siano accessibili tramite JavaScript e forniscano protezione contro attacchi cross-site.

------

### 5. Strategie di Protezione contro il Cross-Site Request Forgery (CSRF)

**Definizione:**

 Gli attacchi CSRF inducono gli utenti autenticati a inviare azioni indesiderate sulle applicazioni web senza il loro consenso.

**Come Nascono le Vulnerabilità:**

 Un attaccante può creare una richiesta malevola che sfrutta la sessione autenticata di un utente.

**Implementazione della Best Practice:**

 Rails include una protezione CSRF integrata. Assicurati che sia abilitata e configurata correttamente nei tuoi controller.

```
# In ApplicationController:
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception  # Solleva un'eccezione se la verifica del token CSRF fallisce
end
```

​             

**Esempio di Form con Token CSRF:**

```
<%= form_with model: @project do |form| %>
  <%= form.label :name %>
  <%= form.text_field :name %>
  <%= form.submit "Save" %>
<% end %>
```

​             

**Spiegazione:**  

- **protect_from_forgery** inserisce automaticamente un token di autenticità nei form, che Rails verifica al momento dell'invio.
- Questo meccanismo integrato difende dal CSRF garantendo che gli invii dei form provengano da fonti fidate.

------

### 6. Upload di File Sicuri e Gestione degli Allegati

**Definizione:**

 Gli upload di file possono essere sfruttati per eseguire codice arbitrario se non validati correttamente, portando potenzialmente alla compromissione del server.

**Come Nascono le Vulnerabilità:**

 Accettando upload di file senza validare tipo, dimensione o effettuare scansioni antimalware:

```
# Approccio vulnerabile: salvataggio "alla cieca" dei file caricati
def upload
  File.open(Rails.root.join('public', 'uploads', params[:file].original_filename), 'wb') do |file|
    file.write(params[:file].read)
  end
end
```

​             

**Implementazione della Best Practice:**

 Utilizza librerie ben mantenute come **ActiveStorage** o **Shrine** per gestire gli upload di file in modo sicuro.

**Esempio con ActiveStorage:**

1. **Configura ActiveStorage:**

```
rails active_storage:install
rails db:migrate
```

​             

1. **Allega File ai Modelli:**

```
class User < ApplicationRecord
  has_one_attached :avatar
end
```

​             

1. **Esempio di Controller con Validazione:**

```
class UsersController < ApplicationController
  def update
    @user = current_user
    if params[:user][:avatar]
      # Valida qui tipo e dimensione del file (ad esempio usando validazioni personalizzate o le validazioni di ActiveStorage)
      @user.avatar.attach(params[:user][:avatar])
    end
    if @user.save
      redirect_to @user, notice: 'Profile updated successfully.'
    else
      render :edit
    end
  end
end
```

​             

**Spiegazione:**  

- **ActiveStorage** astrae la gestione dei file in modo sicuro, memorizzandoli esternamente (ad esempio Amazon S3, Google Cloud Storage) e fornendo validazioni.
- Valida sempre tipo e dimensione del file prima di accettare gli upload.

------

### 7. Autenticazione e Autorizzazione Robuste

**Definizione:**

 Garantire che gli utenti siano chi dichiarano di essere (autenticazione) e che abbiano i permessi per accedere a determinate risorse (autorizzazione) è fondamentale per la sicurezza dell'applicazione.

**Come Nascono le Vulnerabilità:**

 Meccanismi di autenticazione deboli o controlli di accesso mal configurati possono portare ad accessi non autorizzati.

**Implementazione della Best Practice:**

 Sfrutta gem standard del settore come **Devise** per l'autenticazione e **Pundit** o **Cancancan** per l'autorizzazione.

**Installazione e Configurazione di Devise:**

```
# Nel Gemfile:
gem 'devise'
```

​             

```
# Installa Devise:
rails generate devise:install
rails generate devise User
rails db:migrate
```

​             

**Esempio di Protezione delle Route:**

```
Rails.application.routes.draw do
  authenticate :user do
    resources :projects  # Solo gli utenti autenticati possono accedere a queste route
  end
  devise_for :users
  root to: 'home#index'
end
```

​             

**Esempio di Autorizzazione con Pundit:**

1. **Installa Pundit:**

```
# Nel Gemfile:
gem 'pundit'
```

​             

1. **Includi in ApplicationController:**

```
class ApplicationController < ActionController::Base
  include Pundit
  # Gestisce gli accessi non autorizzati
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end
end
```

​             

1. **Definisci una Policy:**

```
# app/policies/project_policy.rb
class ProjectPolicy < ApplicationPolicy
  def update?
    user.admin? || record.owner == user
  end
end
```

​             

**Spiegazione:**  

- **Devise** fornisce flussi di autenticazione sicuri.
- **Pundit** (o Cancancan) consente un controllo granulare sull'accesso alle risorse, garantendo che gli utenti possano eseguire solo le azioni per cui hanno un permesso esplicito.

------

### 8. Monitoraggio e Audit di Sicurezza Continui

**Definizione:**

 La sicurezza non è un'attività da svolgere una tantum. Monitoraggio continuo, audit e test di sicurezza automatizzati aiutano a identificare le vulnerabilità in anticipo e garantiscono una protezione costante nel tempo.

**Come Nascono le Vulnerabilità:**

 Senza audit regolari, anche le applicazioni sicure possono accumulare vulnerabilità nel tempo a causa di dipendenze obsolete o minacce in evoluzione.

**Implementazione della Best Practice:**  

- **Strumenti di Analisi Statica:**

  Utilizza strumenti come [Brakeman](https://github.com/presidentbeef/brakeman) per scansionare il tuo codice alla ricerca delle vulnerabilità più comuni.

- **Audit delle Dipendenze:**

  Utilizza [bundler-audit](https://github.com/rubysec/bundler-audit) per monitorare le vulnerabilità nel tuo Gemfile.lock.

- **Header di Sicurezza:**

  Usa la gem [secure_headers](https://github.com/github/secure_headers) per assicurarti che gli header di sicurezza HTTP siano configurati correttamente.

------

## Approfondimento: Brakeman

**Brakeman** è uno strumento di analisi statica progettato specificamente per le applicazioni Rails. Scansiona il codice sorgente senza eseguirlo, identificando vulnerabilità comuni come SQL injection, XSS e mass assignment non sicuro.

### Installazione e Utilizzo

1. **Installa Brakeman:**

```
gem install brakeman
```

​             

1. **Esegui Brakeman nel tuo progetto Rails:**

```
brakeman
```

​             

Questo comando analizza il tuo codice e produce un report delle potenziali vulnerabilità.

1. **Integrazione con CI/CD:** Puoi aggiungere Brakeman alla tua pipeline CI (ad esempio in un workflow di GitHub Actions) per garantire un monitoraggio continuo:

```
# .github/workflows/security.yml
name: Security Scan

on: [push, pull_request]

jobs:
  brakeman:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.0'
      - name: Install dependencies
        run: bundle install --jobs 4 --retry 3
      - name: Run Brakeman
        run: bundle exec brakeman -q -o brakeman-report.json
```

​             

**Spiegazione:**  

- Brakeman ti aiuta a identificare le vulnerabilità già nelle prime fasi dello sviluppo.
- Le scansioni regolari garantiscono che le nuove vulnerabilità introdotte dalle modifiche al codice vengano individuate prima del deployment.

------

## Approfondimento: bundler-audit

**bundler-audit** controlla il tuo Gemfile.lock alla ricerca di gem con vulnerabilità note. Confronta le tue dipendenze con un database di advisory e ti avvisa se ne vengono trovate.

### Installazione e Utilizzo

1. **Installa bundler-audit:**

```
gem install bundler-audit
```

​             

1. **Esegui bundler-audit nel tuo progetto Rails:**

```
bundler-audit check --update
```

​             

Questo comando:

- Aggiorna il database degli advisory.
- Scansiona il tuo Gemfile.lock alla ricerca di vulnerabilità note.
- Stampa un report con raccomandazioni su come aggiornare o correggere le gem interessate.

1. **Integrazione con CI/CD:** Per un monitoraggio continuo, includi bundler-audit nella tua pipeline CI:

```
# .github/workflows/dependency_audit.yml
name: Dependency Audit

on: [push, pull_request]

jobs:
  bundler_audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.0'
      - name: Install dependencies
        run: bundle install --jobs 4 --retry 3
      - name: Run bundler-audit
        run: bundle exec bundler-audit check --update
```

​             

**Spiegazione:**  

- bundler-audit garantisce che le dipendenze del tuo progetto rimangano sicure, segnalando gem obsolete o vulnerabili.
- L'integrazione nella pipeline CI automatizza il processo e ti tiene informato su eventuali nuove vulnerabilità.

------

**Esempio di Configurazione degli Header di Sicurezza:**

```
# Gemfile:
gem 'secure_headers'
```

​             

```
# config/initializers/secure_headers.rb:
SecureHeaders::Configuration.default do |config|
  config.hsts = "max-age=31536000; includeSubdomains"
  config.x_frame_options = "SAMEORIGIN"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "1; mode=block"
  config.csp = {
    default_src: %w('self'),
    script_src: %w('self' https: 'unsafe-inline'),
    style_src: %w('self' https: 'unsafe-inline'),
    img_src: %w('self' data:),
    object_src: %w('none')
  }
end
```

​             

**Spiegazione:**  

- Le **scansioni di sicurezza regolari** e gli audit delle dipendenze ti aiutano a stare al passo con le potenziali vulnerabilità.
- Gli strumenti automatizzati integrati nella pipeline CI/CD possono fornire un feedback continuo sulla postura di sicurezza della tua applicazione.

------

## Gem, Librerie e Strumenti Aggiuntivi

Migliora la postura di sicurezza della tua applicazione Rails con questi strumenti consigliati:

- **Brakeman:**

  Uno strumento di analisi statica progettato specificamente per Rails, Brakeman scansiona il tuo codice base alla ricerca di vulnerabilità senza eseguire la tua applicazione.

  *[Documentazione Ufficiale](https://brakemanscanner.org/)*

- **bundler-audit:**

  Questa gem controlla il tuo Gemfile.lock alla ricerca di vulnerabilità note nelle tue dipendenze, aiutandoti a mantenere un set di gem aggiornato e sicuro.

  *[Documentazione Ufficiale](https://github.com/rubysec/bundler-audit)*

- **secure_headers:**

  Una gem che semplifica la gestione degli header di sicurezza HTTP, riducendo i rischi derivanti da clickjacking, MIME-sniffing e attacchi XSS.

  *[Repository GitHub](https://github.com/github/secure_headers)*

- **Pundit:**

  Una libreria di autorizzazione leggera che applica il controllo degli accessi a livello di singolo modello, garantendo che solo gli utenti autorizzati possano eseguire azioni specifiche.

  *[Documentazione Ufficiale](https://github.com/varvet/pundit)*

- **ActiveStorage:**

  La soluzione integrata di Rails per l'upload di file, progettata pensando a sicurezza e scalabilità.

  *[Rails Guides su ActiveStorage](https://edgeguides.rubyonrails.org/active_storage_overview.html)*

------

## Checklist delle Best Practice di Sicurezza

Prima di distribuire o effettuare l'audit della tua applicazione Rails, assicurati di aver implementato quanto segue:

- **SQL Injection:**  
  - Usa query parametrizzate e metodi ActiveRecord.
  - Evita la concatenazione di SQL grezzo.
- **Mitigazione XSS:**  
  - Affidati alle funzionalità di auto-escaping di Rails.
  - Usa helper di sanificazione (ad esempio `sanitize`, `h`) dove necessario.
- **Gestione di Segreti e Credenziali:**  
  - Memorizza i dati sensibili nelle credenziali crittografate di Rails o nelle variabili d'ambiente.
  - Non inserire mai i segreti direttamente nel codice sorgente.
- **Gestione delle Sessioni:**  
  - Configura session store sicuri (valuta l'ActiveRecord store).
  - Applica i flag dei cookie secure, httponly e same_site.
- **Protezione CSRF:**  
  - Abilita `protect_from_forgery` in ApplicationController.
  - Assicurati che i token di autenticità siano presenti nei form.
- **Upload di File Sicuri:**  
  - Usa ActiveStorage o Shrine per la gestione dei file.
  - Valida tipi di file, dimensioni ed esegui scansioni per potenziali minacce.
- **Autenticazione e Autorizzazione:**  
  - Implementa Devise per l'autenticazione.
  - Usa Pundit o Cancancan per l'autorizzazione delle risorse.
- **Monitoraggio e Audit Continui:**  
  - Integra Brakeman e bundler-audit nella tua pipeline CI/CD.
  - Rivedi e aggiorna regolarmente gli header di sicurezza usando secure_headers.

------

## Conclusione

Mettere in sicurezza la tua applicazione Ruby on Rails è un processo continuo, a più livelli, che richiede diligenza, gli strumenti giusti e una mentalità proattiva. Implementando queste best practice, dalla difesa contro SQL injection e XSS alla gestione sicura delle sessioni fino alla protezione dei tuoi segreti, non solo proteggi i dati dei tuoi utenti, ma migliori anche l'affidabilità e la fiducia nella tua applicazione.

Ricorda, la sicurezza non è una casella da spuntare una tantum: è un impegno continuo. Rimani informato sugli sviluppi più recenti in materia di sicurezza, effettua audit regolari del tuo codice base e integra costantemente pratiche di sicurezza moderne nel tuo workflow di sviluppo. Il tuo io futuro, e i tuoi utenti, ti ringrazieranno.



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
     - password:pAssword1234567
     - password_confirmation:pAssword1234567
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
