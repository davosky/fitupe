# Graph Report - .  (2026-07-15)

## Corpus Check
- 8 files · ~22,141 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 224 nodes · 185 edges · 75 communities (43 shown, 32 thin omitted)
- Extraction: 69% EXTRACTED · 30% INFERRED · 1% AMBIGUOUS · INFERRED: 56 edges (avg confidence: 0.86)
- Token cost: 0 input · 113,051 output

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
- [[_COMMUNITY_AdminUsersController|Admin::UsersController]]
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

## God Nodes (most connected - your core abstractions)
1. `ApplicationPolicy#admin?` - 12 edges
2. `User` - 10 edges
3. `CLAUDE.md Project Guide` - 10 edges
4. `Bootstrap CSS Framework` - 7 edges
5. `scripts` - 6 edges
6. `Devise Authentication` - 6 edges
7. `Fitupe Application` - 6 edges
8. `solid_queue_jobs table` - 6 edges
9. `user FactoryBot factory` - 6 edges
10. `README Tech Stack Section` - 6 edges

## Surprising Connections (you probably didn't know these)
- `Bootstrap Alert Component API` --conceptually_related_to--> `Bootstrap CSS Framework`  [INFERRED]
  app/javascript/controllers/flash_controller.js → CLAUDE.md
- `Italian Devise Translations` --semantically_similar_to--> `Devise Authentication`  [INFERRED] [semantically similar]
  config/locales/devise.it.yml → CLAUDE.md
- `Italian ActiveRecord Labels for User Model` --semantically_similar_to--> `Devise Authentication`  [INFERRED] [semantically similar]
  config/locales/it.yml → CLAUDE.md
- `README Tech Stack Section` --semantically_similar_to--> `Bootstrap CSS Framework`  [INFERRED] [semantically similar]
  README.md → CLAUDE.md
- `README Tech Stack Section` --semantically_similar_to--> `RSpec + FactoryBot + Capybara Testing Stack`  [INFERRED] [semantically similar]
  README.md → CLAUDE.md

## Communities (75 total, 32 thin omitted)

### Community 0 - "Modello User e Autenticazione"
Cohesion: 0.14
Nodes (11): Admin::UsersController, users table (schema.rb), davo admin User seed, user FactoryBot factory, DeviseCreateUsers, User::GENDERS, User model spec, User (+3 more)

### Community 1 - "Pundit e Controlli Autorizzazione Admin"
Cohesion: 0.20
Nodes (5): Admin::ApplicationController, authenticate_admin, user_not_authorized, ApplicationPolicy#admin?, Scope

### Community 2 - "Documentazione (README, LICENCE, locale IT)"
Cohesion: 0.15
Nodes (17): Administrate Admin Panel, Devise Authentication, Fitupe Application, Pundit Authorization, RSpec + FactoryBot + Capybara Testing Stack, Turbo/Hotwire Compatibility, User Model Fields, User Model Specification (Devise fields) (+9 more)

### Community 3 - "Statistici e Origine del Nome Fitupe"
Cohesion: 0.17
Nodes (12): Analysis of Variance (ANOVA), Box Plot, Chi-Square Test, Pearson Correlation Coefficient, Exploratory Data Analysis (EDA), Fitupe Logo Design, Fitupe Application Name Origin, John Tukey (+4 more)

### Community 4 - "Script Build NPM"
Cohesion: 0.17
Nodes (11): browserslist, devDependencies, esbuild, name, private, scripts, build, build:css (+3 more)

### Community 5 - "Config Ambienti e Solid Stack"
Cohesion: 0.22
Nodes (11): Action Cable adapter configuration, Rails cache store configuration, PostgreSQL database connections configuration, Kamal deploy configuration, Puma server configuration, Solid Queue worker/dispatcher configuration, Recurring scheduled jobs (Solid Queue), Active Storage services configuration (+3 more)

### Community 6 - "Stimulus Controllers e Flash"
Cohesion: 0.20
Nodes (6): Bootstrap Alert Component API, Application, connect(), disconnect(), HelloController (Stimulus), Stimulus controllers manifest (index.js)

### Community 7 - "Dipendenze Frontend (package.json)"
Cohesion: 0.18
Nodes (11): dependencies, autoprefixer, bootstrap, bootswatch, @hotwired/stimulus, @hotwired/turbo-rails, nodemon, @popperjs/core (+3 more)

### Community 8 - "Stack Tecnico (CLAUDE.md)"
Cohesion: 0.22
Nodes (9): bin/jobs script, Anti-Patterns to Avoid, CLAUDE.md Project Guide, Graphify Knowledge Graph Workflow, N+1 Query Performance Rule, Pagy Pagination, PostgreSQL Database Config, Rails Way Convention Over Configuration (+1 more)

### Community 9 - "Bootstrap/Hotwire e Flash Controller"
Cohesion: 0.28
Nodes (9): Bootstrap CSS Framework, Bootswatch Styles (Lumen), ESBuild JS Bundler, Hotwire (Turbo + Stimulus), Stimulus Controllers Convention, FlashController, Flash Controller Registration, esbuild Bundler (+1 more)

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

## Ambiguous Edges - Review These
- `Anti-Patterns to Avoid` → `PostgreSQL Database Config`  [AMBIGUOUS]
  CLAUDE.md · relation: conceptually_related_to
- `Devise.setup configuration (username auth)` → `Admin namespace routes (users)`  [AMBIGUOUS]
  config/routes.rb · relation: conceptually_related_to

## Knowledge Gaps
- **92 isolated node(s):** `name`, `private`, `esbuild`, `build`, `build:css:compile` (+87 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **32 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Anti-Patterns to Avoid` and `PostgreSQL Database Config`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `Devise.setup configuration (username auth)` and `Admin namespace routes (users)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `Bootstrap CSS Framework` connect `Bootstrap/Hotwire e Flash Controller` to `Documentazione (README, LICENCE, locale IT)`, `Stimulus Controllers e Flash`?**
  _High betweenness centrality (0.022) - this node is a cross-community bridge._
- **Why does `User` connect `Modello User e Autenticazione` to `Pundit e Controlli Autorizzazione Admin`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **Why does `Fitupe Application` connect `Documentazione (README, LICENCE, locale IT)` to `Stack Tecnico (CLAUDE.md)`, `Bootstrap/Hotwire e Flash Controller`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `ApplicationPolicy#admin?` (e.g. with `authenticate_admin` and `user_not_authorized`) actually correct?**
  _`ApplicationPolicy#admin?` has 2 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `User` (e.g. with `Admin::UsersController` and `pages_controller.rb`) actually correct?**
  _`User` has 2 INFERRED edges - model-reasoned connections that need verification._