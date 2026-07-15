# Graph Report - .  (2026-07-15)

## Corpus Check
- Corpus is ~23,240 words - fits in a single context window. You may not need a graph.

## Summary
- 227 nodes · 165 edges · 83 communities (40 shown, 43 thin omitted)
- Extraction: 75% EXTRACTED · 25% INFERRED · 1% AMBIGUOUS · INFERRED: 41 edges (avg confidence: 0.89)
- Token cost: 0 input · 398,533 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Documentazione e Stack Tecnico|Documentazione e Stack Tecnico]]
- [[_COMMUNITY_Modello User e Autenticazione|Modello User e Autenticazione]]
- [[_COMMUNITY_Pundit Authorization Policy|Pundit Authorization Policy]]
- [[_COMMUNITY_Statistici e Origine del Nome Fitupe|Statistici e Origine del Nome Fitupe]]
- [[_COMMUNITY_Dipendenze Frontend (BootstrapHotwire)|Dipendenze Frontend (Bootstrap/Hotwire)]]
- [[_COMMUNITY_Script Build NPM|Script Build NPM]]
- [[_COMMUNITY_Config Ambienti e Solid Stack|Config Ambienti e Solid Stack]]
- [[_COMMUNITY_Routing, Devise e Locales|Routing, Devise e Locales]]
- [[_COMMUNITY_Stimulus Controllers JS|Stimulus Controllers JS]]
- [[_COMMUNITY_Logo e Favicon|Logo e Favicon]]
- [[_COMMUNITY_Solid Queue Job Tables|Solid Queue Job Tables]]
- [[_COMMUNITY_PagesController|PagesController]]
- [[_COMMUNITY_Script di Avvio Bin|Script di Avvio Bin]]
- [[_COMMUNITY_Controlli Autorizzazione Admin|Controlli Autorizzazione Admin]]
- [[_COMMUNITY_Configurazione Rubocop|Configurazione Rubocop]]
- [[_COMMUNITY_ApplicationController|ApplicationController]]
- [[_COMMUNITY_AdminUsersController|Admin::UsersController]]
- [[_COMMUNITY_UserDashboard (Administrate)|UserDashboard (Administrate)]]
- [[_COMMUNITY_ApplicationJob|ApplicationJob]]
- [[_COMMUNITY_ApplicationRecord|ApplicationRecord]]
- [[_COMMUNITY_Config Application Rails|Config Application Rails]]
- [[_COMMUNITY_CI e Bundler Audit|CI e Bundler Audit]]
- [[_COMMUNITY_Routes CreditsRoot|Routes Credits/Root]]
- [[_COMMUNITY_AdminApplicationController|Admin::ApplicationController]]
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
- [[_COMMUNITY_ApplicationJob Class|ApplicationJob Class]]
- [[_COMMUNITY_ApplicationMailer Class|ApplicationMailer Class]]
- [[_COMMUNITY_ApplicationRecord Class|ApplicationRecord Class]]
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
- [[_COMMUNITY_Solid Queue Recurring Tasks Table|Solid Queue Recurring Tasks Table]]
- [[_COMMUNITY_Solid Queue Semaphores Table|Solid Queue Semaphores Table]]
- [[_COMMUNITY_Pagina Errore 400|Pagina Errore 400]]
- [[_COMMUNITY_Pagina Errore 404|Pagina Errore 404]]
- [[_COMMUNITY_Pagina Errore 406|Pagina Errore 406]]
- [[_COMMUNITY_Pagina Errore 422|Pagina Errore 422]]
- [[_COMMUNITY_Pagina Errore 500|Pagina Errore 500]]

## God Nodes (most connected - your core abstractions)
1. `ApplicationPolicy` - 10 edges
2. `User` - 10 edges
3. `CLAUDE.md Project Guide` - 10 edges
4. `scripts` - 6 edges
5. `Fitupe Application` - 6 edges
6. `solid_queue_jobs table` - 6 edges
7. `user FactoryBot factory` - 6 edges
8. `rails_helper RSpec configuration` - 5 edges
9. `DeviseCreateUsers` - 4 edges
10. `Karl Pearson` - 4 edges

## Surprising Connections (you probably didn't know these)
- `package.json (JS Build Config)` --shares_data_with--> `Bootstrap CSS Framework`  [INFERRED]
  package.json → CLAUDE.md
- `package.json (JS Build Config)` --shares_data_with--> `Bootswatch Styles (Lumen)`  [INFERRED]
  package.json → CLAUDE.md
- `package.json (JS Build Config)` --shares_data_with--> `Hotwire (Turbo + Stimulus)`  [INFERRED]
  package.json → CLAUDE.md
- `davo admin User seed` --semantically_similar_to--> `user FactoryBot factory`  [INFERRED] [semantically similar]
  db/seeds.rb → spec/factories/users.rb
- `CLAUDE.md Project Guide` --references--> `FITUPE.md Naming & Logo Document`  [EXTRACTED]
  CLAUDE.md → FITUPE.md

## Hyperedges (group relationships)
- **Fisher + Tukey + Pearson form the FiTuPe name** — fitupe_ronald_fisher, fitupe_karl_pearson, fitupe_john_tukey, fitupe_fitupe_name [EXTRACTED 1.00]
- **Fitupe auth/authz/admin core stack** — claude_devise, claude_pundit, claude_administrate, claude_fitupe_app [EXTRACTED 1.00]
- **Development environment bootstrap sequence** — bin_setup, bin_rails, bin_dev [EXTRACTED 1.00]
- **Administrate User Management Pattern** — admin_application_controller_application_controller, admin_users_controller_users_controller, dashboards_user_dashboard_user_dashboard, models_user_user [INFERRED 0.85]
- **Stimulus Controller Registration Flow** — javascript_application_application, controllers_application_application, controllers_index, controllers_hello_controller_hello_controller [EXTRACTED 1.00]
- **Pundit Authorization Failure Handling** — controllers_application_controller_application_controller, controllers_application_controller_user_not_authorized, policies_application_policy_application_policy, admin_application_controller_authenticate_admin [INFERRED 0.85]
- **Solid Cache/Queue/Cable multi-database production architecture** — config_database_config, config_cache_config, config_queue_config, config_cable_config, environments_production_config [INFERRED 0.85]
- **Devise username-based authentication configuration** — initializers_devise_config, config_routes_devise_for_users, locales_it_translations, locales_devise_en_translations [INFERRED 0.80]
- **Application internationalization (i18n) configuration** — config_application_config, locales_it_translations, locales_en_translations, locales_devise_en_translations [INFERRED 0.85]
- **Rails default static public error pages** — public_400_error_page, public_404_error_page, public_406_unsupported_browser_error_page, public_422_error_page, public_500_error_page [INFERRED 0.85]
- **RSpec test suite configuration and fixtures** — spec_rails_helper_config, spec_spec_helper_config, factories_users_user_factory, models_user_spec_user_spec, requests_pages_spec_pages_spec [INFERRED 0.85]
- **User schema, migration, seed and factory pipeline** — db_schema_users_table, migrate_20260715111350_devise_create_users_devisecreateusers, db_seeds_davo_user, factories_users_user_factory [INFERRED 0.85]

## Communities (83 total, 43 thin omitted)

### Community 0 - "Documentazione e Stack Tecnico"
Cohesion: 0.12
Nodes (19): bin/jobs script, Administrate Admin Panel, Anti-Patterns to Avoid, Bootstrap CSS Framework, Bootswatch Styles (Lumen), CLAUDE.md Project Guide, Devise Authentication, Fitupe Application (+11 more)

### Community 1 - "Modello User e Autenticazione"
Cohesion: 0.16
Nodes (13): Admin::UsersController, PagesController, UserDashboard, users table (schema.rb), davo admin User seed, user FactoryBot factory, DeviseCreateUsers, User::GENDERS (+5 more)

### Community 2 - "Pundit Authorization Policy"
Cohesion: 0.17
Nodes (3): ApplicationController, ApplicationPolicy, Scope

### Community 3 - "Statistici e Origine del Nome Fitupe"
Cohesion: 0.17
Nodes (12): Analysis of Variance (ANOVA), Box Plot, Chi-Square Test, Pearson Correlation Coefficient, Exploratory Data Analysis (EDA), Fitupe Logo Design, Fitupe Application Name Origin, John Tukey (+4 more)

### Community 4 - "Dipendenze Frontend (Bootstrap/Hotwire)"
Cohesion: 0.17
Nodes (12): dependencies, autoprefixer, bootstrap, bootstrap-icons, bootswatch, @hotwired/stimulus, @hotwired/turbo-rails, nodemon (+4 more)

### Community 5 - "Script Build NPM"
Cohesion: 0.17
Nodes (11): browserslist, devDependencies, esbuild, name, private, scripts, build, build:css (+3 more)

### Community 6 - "Config Ambienti e Solid Stack"
Cohesion: 0.22
Nodes (11): Action Cable adapter configuration, Rails cache store configuration, PostgreSQL database connections configuration, Kamal deploy configuration, Puma server configuration, Solid Queue worker/dispatcher configuration, Recurring scheduled jobs (Solid Queue), Active Storage services configuration (+3 more)

### Community 7 - "Routing, Devise e Locales"
Cohesion: 0.22
Nodes (9): Fitupe::Application configuration, Boot: Bundler & Bootsnap setup, Rails application boot/initialize, Admin namespace routes (users), devise_for :users route, Devise.setup configuration (username auth), Devise English translations, English locale (default) (+1 more)

### Community 8 - "Stimulus Controllers JS"
Cohesion: 0.29
Nodes (3): application, HelloController (Stimulus), Stimulus controllers manifest (index.js)

### Community 9 - "Logo e Favicon"
Cohesion: 0.25
Nodes (8): Main Logo PNG (Asset Pipeline), Main Logo SVG (Asset Pipeline Copy), Fitupe Main Logo (PNG), Fitupe Main Logo (SVG), Sigma (Standard Deviation) Symbolism, Fitupe Favicon (public/icon.png), Fitupe Favicon (public/icon.svg), Devise Sessions New View

### Community 10 - "Solid Queue Job Tables"
Cohesion: 0.29
Nodes (7): solid_queue_blocked_executions table, solid_queue_claimed_executions table, solid_queue_failed_executions table, solid_queue_jobs table, solid_queue_ready_executions table, solid_queue_recurring_executions table, solid_queue_scheduled_executions table

### Community 12 - "Script di Avvio Bin"
Cohesion: 0.50
Nodes (4): bin/dev script, bin/docker-entrypoint script, bin/rails script, bin/setup script

### Community 13 - "Controlli Autorizzazione Admin"
Cohesion: 0.50
Nodes (4): authenticate_admin, user_not_authorized, ApplicationPolicy#admin?, ApplicationPolicy

### Community 14 - "Configurazione Rubocop"
Cohesion: 0.67
Nodes (3): bin/rubocop script, Rubocop Configuration File, Rubocop Rails Omakase Style

## Ambiguous Edges - Review These
- `Devise.setup configuration (username auth)` → `Admin namespace routes (users)`  [AMBIGUOUS]
  config/routes.rb · relation: conceptually_related_to

## Knowledge Gaps
- **101 isolated node(s):** `name`, `private`, `esbuild`, `build`, `build:css:compile` (+96 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **43 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Devise.setup configuration (username auth)` and `Admin namespace routes (users)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `dependencies` connect `Dipendenze Frontend (Bootstrap/Hotwire)` to `Script Build NPM`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **Why does `User` connect `Modello User e Autenticazione` to `Controlli Autorizzazione Admin`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `User` (e.g. with `Admin::UsersController` and `PagesController`) actually correct?**
  _`User` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `name`, `private`, `esbuild` to the rest of the system?**
  _105 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Documentazione e Stack Tecnico` be split into smaller, more focused modules?**
  _Cohesion score 0.11695906432748537 - nodes in this community are weakly interconnected._