# Graph Report - .  (2026-07-15)

## Corpus Check
- 3 files · ~23,296 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 215 nodes · 172 edges · 75 communities (43 shown, 32 thin omitted)
- Extraction: 72% EXTRACTED · 27% INFERRED · 1% AMBIGUOUS · INFERRED: 46 edges (avg confidence: 0.87)
- Token cost: 0 input · 32,649 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Modello User e Autenticazione|Modello User e Autenticazione]]
- [[_COMMUNITY_Pundit e Controlli Autorizzazione Admin|Pundit e Controlli Autorizzazione Admin]]
- [[_COMMUNITY_Dipendenze Frontend (package.json)|Dipendenze Frontend (package.json)]]
- [[_COMMUNITY_Stimulus Controllers e Flash|Stimulus Controllers e Flash]]
- [[_COMMUNITY_Statistici e Origine del Nome Fitupe|Statistici e Origine del Nome Fitupe]]
- [[_COMMUNITY_Config Ambienti e Solid Stack|Config Ambienti e Solid Stack]]
- [[_COMMUNITY_Documentazione e Stack Tecnico|Documentazione e Stack Tecnico]]
- [[_COMMUNITY_BootstrapHotwire e Flash Controller|Bootstrap/Hotwire e Flash Controller]]
- [[_COMMUNITY_Routing, Devise e Locales|Routing, Devise e Locales]]
- [[_COMMUNITY_Solid Queue Job Tables|Solid Queue Job Tables]]
- [[_COMMUNITY_Logo e Favicon|Logo e Favicon]]
- [[_COMMUNITY_Stack AuthAuthzAdmin (CLAUDE.md)|Stack Auth/Authz/Admin (CLAUDE.md)]]
- [[_COMMUNITY_Script Build CSSNPM|Script Build CSS/NPM]]
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
4. `scripts` - 6 edges
5. `Bootstrap CSS Framework` - 6 edges
6. `Fitupe Application` - 6 edges
7. `solid_queue_jobs table` - 6 edges
8. `user FactoryBot factory` - 6 edges
9. `authenticate_admin` - 5 edges
10. `rails_helper RSpec configuration` - 5 edges

## Surprising Connections (you probably didn't know these)
- `Bootstrap Alert Component API` --conceptually_related_to--> `Bootstrap CSS Framework`  [INFERRED]
  app/javascript/controllers/flash_controller.js → CLAUDE.md
- `package.json (JS Build Config)` --shares_data_with--> `Bootstrap CSS Framework`  [INFERRED]
  package.json → CLAUDE.md
- `package.json (JS Build Config)` --shares_data_with--> `Bootswatch Styles (Lumen)`  [INFERRED]
  package.json → CLAUDE.md
- `package.json (JS Build Config)` --shares_data_with--> `Hotwire (Turbo + Stimulus)`  [INFERRED]
  package.json → CLAUDE.md
- `davo admin User seed` --semantically_similar_to--> `user FactoryBot factory`  [INFERRED] [semantically similar]
  db/seeds.rb → spec/factories/users.rb

## Communities (75 total, 32 thin omitted)

### Community 0 - "Modello User e Autenticazione"
Cohesion: 0.14
Nodes (11): Admin::UsersController, users table (schema.rb), davo admin User seed, user FactoryBot factory, DeviseCreateUsers, User::GENDERS, User model spec, User (+3 more)

### Community 1 - "Pundit e Controlli Autorizzazione Admin"
Cohesion: 0.18
Nodes (6): Admin::ApplicationController, ApplicationController, authenticate_admin, user_not_authorized, ApplicationPolicy#admin?, Scope

### Community 2 - "Dipendenze Frontend (package.json)"
Cohesion: 0.12
Nodes (16): browserslist, dependencies, autoprefixer, bootstrap, bootswatch, @hotwired/stimulus, @hotwired/turbo-rails, nodemon (+8 more)

### Community 3 - "Stimulus Controllers e Flash"
Cohesion: 0.20
Nodes (6): Bootstrap Alert Component API, application, connect(), disconnect(), HelloController (Stimulus), Stimulus controllers manifest (index.js)

### Community 4 - "Statistici e Origine del Nome Fitupe"
Cohesion: 0.17
Nodes (12): Analysis of Variance (ANOVA), Box Plot, Chi-Square Test, Pearson Correlation Coefficient, Exploratory Data Analysis (EDA), Fitupe Logo Design, Fitupe Application Name Origin, John Tukey (+4 more)

### Community 5 - "Config Ambienti e Solid Stack"
Cohesion: 0.22
Nodes (11): Action Cable adapter configuration, Rails cache store configuration, PostgreSQL database connections configuration, Kamal deploy configuration, Puma server configuration, Solid Queue worker/dispatcher configuration, Recurring scheduled jobs (Solid Queue), Active Storage services configuration (+3 more)

### Community 6 - "Documentazione e Stack Tecnico"
Cohesion: 0.20
Nodes (10): bin/jobs script, Anti-Patterns to Avoid, CLAUDE.md Project Guide, Graphify Knowledge Graph Workflow, N+1 Query Performance Rule, Pagy Pagination, PostgreSQL Database Config, Rails Way Convention Over Configuration (+2 more)

### Community 7 - "Bootstrap/Hotwire e Flash Controller"
Cohesion: 0.28
Nodes (9): Bootstrap CSS Framework, Bootswatch Styles (Lumen), ESBuild JS Bundler, Hotwire (Turbo + Stimulus), Stimulus Controllers Convention, FlashController, Flash Controller Registration, esbuild Bundler (+1 more)

### Community 8 - "Routing, Devise e Locales"
Cohesion: 0.22
Nodes (9): Fitupe::Application configuration, Boot: Bundler & Bootsnap setup, Rails application boot/initialize, Admin namespace routes (users), devise_for :users route, Devise.setup configuration (username auth), Devise English translations, English locale (default) (+1 more)

### Community 9 - "Solid Queue Job Tables"
Cohesion: 0.29
Nodes (7): solid_queue_blocked_executions table, solid_queue_claimed_executions table, solid_queue_failed_executions table, solid_queue_jobs table, solid_queue_ready_executions table, solid_queue_recurring_tasks table, solid_queue_scheduled_executions table

### Community 10 - "Logo e Favicon"
Cohesion: 0.33
Nodes (7): Main Logo PNG (Asset Pipeline), Main Logo SVG (Asset Pipeline Copy), Fitupe Main Logo (PNG), Fitupe Main Logo (SVG), Sigma (Standard Deviation) Symbolism, Fitupe Favicon (public/icon.svg), Devise Sessions New View

### Community 11 - "Stack Auth/Authz/Admin (CLAUDE.md)"
Cohesion: 0.38
Nodes (7): Administrate Admin Panel, Devise Authentication, Fitupe Application, Pundit Authorization, Turbo/Hotwire Compatibility, User Model Fields, User Model Specification (Devise fields)

### Community 12 - "Script Build CSS/NPM"
Cohesion: 0.33
Nodes (6): scripts, build, build:css, build:css:compile, build:css:prefix, watch:css

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
- **88 isolated node(s):** `name`, `private`, `esbuild`, `build`, `build:css:compile` (+83 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **32 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Anti-Patterns to Avoid` and `PostgreSQL Database Config`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `Devise.setup configuration (username auth)` and `Admin namespace routes (users)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `User` connect `Modello User e Autenticazione` to `Pundit e Controlli Autorizzazione Admin`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **Why does `Bootstrap CSS Framework` connect `Bootstrap/Hotwire e Flash Controller` to `Stimulus Controllers e Flash`, `Stack Auth/Authz/Admin (CLAUDE.md)`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **Why does `authenticate_admin` connect `Pundit e Controlli Autorizzazione Admin` to `Modello User e Autenticazione`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `ApplicationPolicy#admin?` (e.g. with `authenticate_admin` and `user_not_authorized`) actually correct?**
  _`ApplicationPolicy#admin?` has 2 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `User` (e.g. with `Admin::UsersController` and `pages_controller.rb`) actually correct?**
  _`User` has 2 INFERRED edges - model-reasoned connections that need verification._