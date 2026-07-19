# Graph Report - fitupe  (2026-07-19)

## Corpus Check
- 91 files · ~32,033 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 409 nodes · 369 edges · 106 communities (56 shown, 50 thin omitted)
- Extraction: 82% EXTRACTED · 17% INFERRED · 1% AMBIGUOUS · INFERRED: 63 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `625d06ce`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Modello User e Autenticazione|Modello User e Autenticazione]]
- [[_COMMUNITY_Pundit e Controlli Autorizzazione Admin|Pundit e Controlli Autorizzazione Admin]]
- [[_COMMUNITY_Documentazione (README, LICENCE, locale IT)|Documentazione (README, LICENCE, locale IT)]]
- [[_COMMUNITY_Statistici e Origine del Nome Fitupe|Statistici e Origine del Nome Fitupe]]
- [[_COMMUNITY_Script Build NPM|Script Build NPM]]
- [[_COMMUNITY_Config Ambienti e Solid Stack|Config Ambienti e Solid Stack]]
- [[_COMMUNITY_Stimulus Controllers e Flash|Stimulus Controllers e Flash]]
- [[_COMMUNITY_Dipendenze Frontend (package.json)|Dipendenze Frontend (package.json)]]
- [[_COMMUNITY_Stack Tecnico (CLAUDE.md)|Stack Tecnico (CLAUDE.md)]]
- [[_COMMUNITY_BootstrapHotwire e Flash Controller|Bootstrap/Hotwire e Flash Controller]]
- [[_COMMUNITY_Logo e Favicon|Logo e Favicon]]
- [[_COMMUNITY_Routing, Devise e Locales|Routing, Devise e Locales]]
- [[_COMMUNITY_Solid Queue Job Tables|Solid Queue Job Tables]]
- [[_COMMUNITY_Script di Avvio Bin|Script di Avvio Bin]]
- [[_COMMUNITY_Configurazione Rubocop|Configurazione Rubocop]]
- [[_COMMUNITY_Convenzioni RSpecNaming (CLAUDE.md)|Convenzioni RSpec/Naming (CLAUDE.md)]]
- [[_COMMUNITY_CI e Bundler Audit|CI e Bundler Audit]]
- [[_COMMUNITY_Routes CreditsRoot|Routes Credits/Root]]
- [[_COMMUNITY_ApplicationRecord|ApplicationRecord]]
- [[_COMMUNITY_AdminUsersController|Admin::UsersController]]
- [[_COMMUNITY_ApplicationMailer|ApplicationMailer]]
- [[_COMMUNITY_README|README]]
- [[_COMMUNITY_Bin Brakeman|Bin Brakeman]]
- [[_COMMUNITY_Bin Bundler Audit|Bin Bundler Audit]]
- [[_COMMUNITY_Bin CI|Bin CI]]
- [[_COMMUNITY_Bin Kamal|Bin Kamal]]
- [[_COMMUNITY_Bin Rake|Bin Rake]]
- [[_COMMUNITY_Bin Thrust|Bin Thrust]]
- [[_COMMUNITY_Application Helper Module|Application Helper Module]]
- [[_COMMUNITY_JS Application Entry|JS Application Entry]]
- [[_COMMUNITY_Userfull_name|User#full_name]]
- [[_COMMUNITY_Userpassword_required|User#password_required?]]
- [[_COMMUNITY_Policy Scoperesolve|Policy Scope#resolve]]
- [[_COMMUNITY_Service Worker Module|Service Worker Module]]
- [[_COMMUNITY_Assets Config|Assets Config]]
- [[_COMMUNITY_CSP Config|CSP Config]]
- [[_COMMUNITY_Filter Parameter Config|Filter Parameter Config]]
- [[_COMMUNITY_Inflections Config|Inflections Config]]
- [[_COMMUNITY_Health Check Route|Health Check Route]]
- [[_COMMUNITY_Solid Cable Messages Table|Solid Cable Messages Table]]
- [[_COMMUNITY_Solid Cache Entries Table|Solid Cache Entries Table]]
- [[_COMMUNITY_Solid Queue Processes Table|Solid Queue Processes Table]]
- [[_COMMUNITY_Solid Queue Pauses Table|Solid Queue Pauses Table]]
- [[_COMMUNITY_Solid Queue Semaphores Table|Solid Queue Semaphores Table]]
- [[_COMMUNITY_Pagina Errore 400|Pagina Errore 400]]
- [[_COMMUNITY_Pagina Errore 404|Pagina Errore 404]]
- [[_COMMUNITY_Pagina Errore 406|Pagina Errore 406]]
- [[_COMMUNITY_Pagina Errore 422|Pagina Errore 422]]
- [[_COMMUNITY_Pagina Errore 500|Pagina Errore 500]]
- [[_COMMUNITY_Community 75|Community 75]]
- [[_COMMUNITY_Community 76|Community 76]]
- [[_COMMUNITY_Community 77|Community 77]]
- [[_COMMUNITY_Community 78|Community 78]]
- [[_COMMUNITY_Community 79|Community 79]]
- [[_COMMUNITY_Community 80|Community 80]]
- [[_COMMUNITY_Community 81|Community 81]]
- [[_COMMUNITY_Community 82|Community 82]]
- [[_COMMUNITY_Community 83|Community 83]]
- [[_COMMUNITY_Community 84|Community 84]]
- [[_COMMUNITY_Community 85|Community 85]]
- [[_COMMUNITY_Community 86|Community 86]]
- [[_COMMUNITY_Community 87|Community 87]]
- [[_COMMUNITY_Community 88|Community 88]]
- [[_COMMUNITY_Community 89|Community 89]]
- [[_COMMUNITY_Community 90|Community 90]]
- [[_COMMUNITY_Community 91|Community 91]]

## God Nodes (most connected - your core abstractions)
1. `CLAUDE.md — Guida per Claude Code` - 15 edges
2. `ImportsController` - 13 edges
3. `ApplicationPolicy#admin?` - 12 edges
4. `ZoningsController` - 11 edges
5. `ApplicationPolicy` - 10 edges
6. `CsvImporterService` - 10 edges
7. `User` - 10 edges
8. `CLAUDE.md Project Guide` - 10 edges
9. `ZoningPolicy` - 8 edges
10. `Bootstrap CSS Framework` - 7 edges

## Surprising Connections (you probably didn't know these)
- `Bootstrap Alert Component API` --conceptually_related_to--> `Bootstrap CSS Framework`  [INFERRED]
  app/javascript/controllers/flash_controller.js → CLAUDE.md
- `Italian Devise Translations` --semantically_similar_to--> `Devise Authentication`  [INFERRED] [semantically similar]
  config/locales/devise.it.yml → CLAUDE.md
- `Italian ActiveRecord Labels for User Model` --semantically_similar_to--> `Devise Authentication`  [INFERRED] [semantically similar]
  config/locales/it.yml → CLAUDE.md
- `README Tech Stack Section` --semantically_similar_to--> `RSpec + FactoryBot + Capybara Testing Stack`  [INFERRED] [semantically similar]
  README.md → CLAUDE.md
- `README Tech Stack Section` --semantically_similar_to--> `Devise Authentication`  [INFERRED] [semantically similar]
  README.md → CLAUDE.md

## Communities (106 total, 50 thin omitted)

### Community 0 - "Modello User e Autenticazione"
Cohesion: 0.13
Nodes (13): Admin::UsersController, PagesController, UserDashboard, users table (schema.rb), davo admin User seed, user FactoryBot factory, DeviseCreateUsers, User::GENDERS (+5 more)

### Community 1 - "Pundit e Controlli Autorizzazione Admin"
Cohesion: 0.13
Nodes (9): Admin::ApplicationController, ApplicationController, authenticate_admin, ApplicationController, user_not_authorized, ApplicationPolicy#admin?, ApplicationPolicy, Scope (+1 more)

### Community 2 - "Documentazione (README, LICENCE, locale IT)"
Cohesion: 0.07
Nodes (35): bin/jobs script, Administrate Admin Panel, Anti-Patterns to Avoid, Bootstrap CSS Framework, Bootswatch Styles (Lumen), CLAUDE.md Project Guide, Devise Authentication, ESBuild JS Bundler (+27 more)

### Community 3 - "Statistici e Origine del Nome Fitupe"
Cohesion: 0.17
Nodes (12): Analysis of Variance (ANOVA), Box Plot, Chi-Square Test, Pearson Correlation Coefficient, Exploratory Data Analysis (EDA), Fitupe Logo Design, Fitupe Application Name Origin, John Tukey (+4 more)

### Community 4 - "Script Build NPM"
Cohesion: 0.08
Nodes (23): browserslist, dependencies, autoprefixer, bootstrap, bootstrap-icons, bootswatch, @hotwired/stimulus, @hotwired/turbo-rails (+15 more)

### Community 5 - "Config Ambienti e Solid Stack"
Cohesion: 0.22
Nodes (11): Action Cable adapter configuration, Rails cache store configuration, PostgreSQL database connections configuration, Kamal deploy configuration, Puma server configuration, Solid Queue worker/dispatcher configuration, Recurring scheduled jobs (Solid Queue), Active Storage services configuration (+3 more)

### Community 6 - "Stimulus Controllers e Flash"
Cohesion: 0.16
Nodes (7): Bootstrap Alert Component API, Application, application, connect(), disconnect(), HelloController (Stimulus), Stimulus controllers manifest (index.js)

### Community 7 - "Dipendenze Frontend (package.json)"
Cohesion: 0.06
Nodes (34): ❌ Anti-Pattern da Evitare, CLAUDE.md — Guida per Claude Code, code:block1 (Ruby:        >= 4.0.1), code:bash (# Setup), code:block2 (app/), code:block3 (spec/), code:ruby (# Esempio factory minima), code:ruby (# ✅ Migrazione con indice) (+26 more)

### Community 9 - "Bootstrap/Hotwire e Flash Controller"
Cohesion: 0.33
Nodes (5): 1. Ronald Aylmer Fisher, 2. Karl Pearson, 5. John Tukey, Costruzione del logo della applicazione, Costruzione del nome della applicazione

### Community 10 - "Logo e Favicon"
Cohesion: 0.25
Nodes (9): Main Logo PNG (Asset Pipeline), Main Logo SVG (Asset Pipeline Copy), Navbar Logo (Horizontal Wordmark), Navbar Brand Link, Fitupe Main Logo (PNG), Fitupe Main Logo (SVG), Sigma (Standard Deviation) Symbolism, Fitupe Favicon (public/icon.svg) (+1 more)

### Community 11 - "Routing, Devise e Locales"
Cohesion: 0.22
Nodes (9): Fitupe::Application configuration, Boot: Bundler & Bootsnap setup, Rails application boot/initialize, Admin namespace routes (users), devise_for :users route, Devise.setup configuration (username auth), Devise English translations, English locale (default) (+1 more)

### Community 12 - "Solid Queue Job Tables"
Cohesion: 0.29
Nodes (7): solid_queue_blocked_executions table, solid_queue_claimed_executions table, solid_queue_failed_executions table, solid_queue_jobs table, solid_queue_ready_executions table, solid_queue_recurring_tasks table, solid_queue_scheduled_executions table

### Community 13 - "Script di Avvio Bin"
Cohesion: 0.50
Nodes (4): bin/dev script, bin/docker-entrypoint script, bin/rails script, bin/setup script

### Community 14 - "Configurazione Rubocop"
Cohesion: 0.67
Nodes (3): bin/rubocop script, Rubocop Configuration File, Rubocop Rails Omakase Style

### Community 75 - "Community 75"
Cohesion: 0.33
Nodes (5): Avvio del progetto, code:bash (bin/setup   # setup iniziale (dipendenze, database)), Fitupe, Licenza, Stack tecnico

### Community 76 - "Community 76"
Cohesion: 0.40
Nodes (4): Copyright (c) 2026, Davo Davosky - The Davosky Connection, English, Italiano

## Ambiguous Edges - Review These
- `Anti-Patterns to Avoid` → `PostgreSQL Database Config`  [AMBIGUOUS]
  CLAUDE.md · relation: conceptually_related_to
- `Devise.setup configuration (username auth)` → `Admin namespace routes (users)`  [AMBIGUOUS]
  config/routes.rb · relation: conceptually_related_to

## Knowledge Gaps
- **133 isolated node(s):** `name`, `private`, `esbuild`, `build`, `build:css:compile` (+128 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **50 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Anti-Patterns to Avoid` and `PostgreSQL Database Config`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `Devise.setup configuration (username auth)` and `Admin namespace routes (users)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `User` connect `Modello User e Autenticazione` to `Pundit e Controlli Autorizzazione Admin`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Why does `authenticate_admin` connect `Pundit e Controlli Autorizzazione Admin` to `Modello User e Autenticazione`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Why does `Bootstrap CSS Framework` connect `Documentazione (README, LICENCE, locale IT)` to `Stimulus Controllers e Flash`?**
  _High betweenness centrality (0.008) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `ApplicationPolicy#admin?` (e.g. with `authenticate_admin` and `user_not_authorized`) actually correct?**
  _`ApplicationPolicy#admin?` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `name`, `private`, `esbuild` to the rest of the system?**
  _136 weakly-connected nodes found - possible documentation gaps or missing edges._