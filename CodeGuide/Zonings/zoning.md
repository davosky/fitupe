# `Zoning`

**File:** `app/models/zoning.rb`

## Codice completo

```ruby
class Zoning < ApplicationRecord
  has_many :imports, foreign_key: "azzonamento_di_riferimento_id", inverse_of: :azzonamento_di_riferimento,
    dependent: :restrict_with_error
  has_many :import_spis, class_name: "ImportSpi", foreign_key: "azzonamento_di_riferimento_id",
    inverse_of: :azzonamento_di_riferimento, dependent: :restrict_with_error
  has_many :integration_filleas, dependent: :restrict_with_error
  has_many :legends, dependent: :restrict_with_error
  has_many :legend_spis, dependent: :restrict_with_error

  scope :comprensori_di, lambda { |zoning|
    where("codice_azzonamento LIKE ? AND codice_azzonamento != ?", "#{zoning.codice_azzonamento}%",
      zoning.codice_azzonamento).order(:codice_azzonamento)
  }

  validates :codice_azzonamento, presence: true, uniqueness: true
  validates :descrizione_azzonamento, presence: true

  def regionale?
    codice_azzonamento.to_s.length == 1
  end
end
```

## Sezioni commentate

### La gerarchia geografica implicita nel formato di `codice_azzonamento`

> **IT:** `Zoning` non ha una colonna `parent_id` né alcuna relazione `belongs_to :parent`/`has_many :children` esplicita: l'intera gerarchia regione → comprensorio è codificata **dentro la stringa** `codice_azzonamento` per prefisso. Un azzonamento regionale ha un codice di **una sola cifra/lettera** (`regionale?` lo verifica con `length == 1`, es. `"G"` per il FVG); un comprensorio che appartiene a quella regione ha un codice più lungo che **inizia con** lo stesso prefisso (es. `"GB"`, `"GC"`). Questa è la ragione per cui `comprensori_di` è uno `scope` con una `LIKE` (`"#{zoning.codice_azzonamento}%"`) e non una join su una foreign key: non esiste una foreign key da seguire, la relazione è puramente testuale. È un design deliberatamente leggero — niente tabella di raccordo, niente colonna aggiuntiva — che però significa che l'integrità della gerarchia dipende interamente dalla disciplina con cui i codici vengono inseriti (nessun vincolo DB impedisce un codice comprensorio che non inizia col prefisso di nessuna regione esistente).
>
> *EN: `Zoning` has no `parent_id` column or explicit `belongs_to :parent`/`has_many :children` relationship: the entire region → comprensorio hierarchy is encoded **inside the** `codice_azzonamento` **string** by prefix. A regional zoning has a **single-character** code (`regionale?` checks this with `length == 1`, e.g. `"G"` for FVG); a comprensorio belonging to that region has a longer code that **starts with** the same prefix (e.g. `"GB"`, `"GC"`). That's why `comprensori_di` is a `scope` built on a `LIKE` (`"#{zoning.codice_azzonamento}%"`) rather than a join on a foreign key: there's no foreign key to follow, the relationship is purely textual. It's a deliberately lightweight design — no join table, no extra column — but it means the hierarchy's integrity depends entirely on the discipline used when codes are entered (no DB constraint stops a comprensorio code that doesn't start with any existing region's prefix).*

### `regionale?` e `comprensori_di` — le due primitive che tutto il resto del progetto costruisce sopra

> **IT:** Insieme, questi due metodi sono probabilmente il codice più riusato dell'intera applicazione al di fuori di `ApplicationController`: quasi ogni servizio statistico (`Statistics::TotalMembersComparison`, ogni breakdown in `StatisticSpi::*`, `StatisticWithIntegrations::FilleaCorrection`/`FlcCorrection`, ogni pagina di `StatisticPrints`/`StatisticSpiPrints`) li usa per decidere se mostrare i dati di **un singolo comprensorio** o **aggregare la regione e ripetere per ogni comprensorio figlio**. Il pattern ricorrente è `return regional_result if regionale?` seguito da `Zoning.comprensori_di(@zoning).each { ... }` — visto per esempio in `StatisticPrints::ReportPdf#draw_comprensori` e `StatisticSpiPrints::ReportPdf#draw_comprensori` (vedi `CodeGuide/StatisticPrints/report_pdf.md`, `CodeGuide/StatisticSpiPrints/report_pdf.md`). Nota per chi estende il progetto: `Statistics::TotalMembersComparison`, `StatisticWithIntegrations::FilleaCorrection` e `StatisticWithIntegrations::FlcCorrection` ridefiniscono ciascuno un proprio metodo privato `regionale?` che duplica **esattamente** `codice_azzonamento.to_s.length == 1` invece di delegare a `@zoning.regionale?` — funzionalmente identico, ma è un'inconsistenza minore rispetto a chiamare direttamente il metodo del modello, utile da conoscere se questa logica cambiasse mai (andrebbe aggiornata in più punti).
>
> *EN: Together, these two methods are probably the most reused code in the entire application outside `ApplicationController`: nearly every statistics service (`Statistics::TotalMembersComparison`, every breakdown in `StatisticSpi::*`, `StatisticWithIntegrations::FilleaCorrection`/`FlcCorrection`, every page in `StatisticPrints`/`StatisticSpiPrints`) uses them to decide whether to show data for **a single comprensorio** or to **aggregate the region and repeat for each child comprensorio**. The recurring pattern is `return regional_result if regionale?` followed by `Zoning.comprensori_di(@zoning).each { ... }` — seen for example in `StatisticPrints::ReportPdf#draw_comprensori` and `StatisticSpiPrints::ReportPdf#draw_comprensori` (see `CodeGuide/StatisticPrints/report_pdf.md`, `CodeGuide/StatisticSpiPrints/report_pdf.md`). Note for anyone extending the project: `Statistics::TotalMembersComparison`, `StatisticWithIntegrations::FilleaCorrection`, and `StatisticWithIntegrations::FlcCorrection` each redefine their own private `regionale?` that duplicates **exactly** `codice_azzonamento.to_s.length == 1` instead of delegating to `@zoning.regionale?` — functionally identical, but a minor inconsistency versus calling the model method directly, worth knowing if this logic ever changes (it would need updating in more than one place).*

### Le cinque `has_many :dependent, restrict_with_error` — perché niente `dependent: :destroy`

> **IT:** Ogni relazione da `Zoning` verso il resto del dominio usa `dependent: :restrict_with_error`, mai `:destroy` né `:nullify`: un azzonamento che ha già importazioni, integrazioni o legende collegate **non può essere eliminato** — `destroy` fallisce e l'errore compare tra `@zoning.errors`. Questa è una scelta di integrità dei dati storici: un azzonamento non è un'entità "usa e getta" collegata a un solo record, è la chiave geografica attorno a cui ruotano anni di importazioni CSV, statistiche e report PDF già generati — cancellarlo a cascata (`:destroy`) distruggerebbe silenziosamente dati storici, e scollegarlo (`:nullify`) lascerebbe record orfani con una foreign key nulla che nessun altro punto del codice si aspetta di gestire (`ZoningPeriodScope`, i breakdown SPI, ecc. presumono sempre un `azzonamento_di_riferimento_id` valido). `restrict_with_error` è l'unica delle tre opzioni che rende l'eliminazione un'azione esplicitamente rifiutata invece che silenziosamente distruttiva o silenziosamente incoerente.
>
> *EN: Every relationship from `Zoning` to the rest of the domain uses `dependent: :restrict_with_error`, never `:destroy` or `:nullify`: a zoning that already has imports, integrations, or legends attached to it **cannot be deleted** — `destroy` fails and the error shows up in `@zoning.errors`. This is a historical-data-integrity choice: a zoning isn't a disposable entity tied to one record, it's the geographic key that years of CSV imports, statistics, and already-generated PDF reports revolve around — cascading the delete (`:destroy`) would silently destroy historical data, and unlinking it (`:nullify`) would leave orphaned records with a null foreign key that no other part of the codebase expects to handle (`ZoningPeriodScope`, the SPI breakdowns, etc. all assume a valid `azzonamento_di_riferimento_id`). `restrict_with_error` is the only one of the three options that makes deletion an explicitly refused action instead of silently destructive or silently inconsistent.*

### Il doppio `belongs_to`-equivalente su `Import`/`ImportSpi`: `foreign_key` + `inverse_of` esplicito

> **IT:** `has_many :imports` e `has_many :import_spis` sono le uniche due relazioni della classe con `foreign_key:` e `inverse_of:` espliciti, invece del default Rails dedotto dal nome. La ragione: la colonna su `Import`/`ImportSpi` non si chiama `zoning_id` ma `azzonamento_di_riferimento_id` — un nome più descrittivo scelto lato tabella (l'azzonamento "di riferimento" per quella importazione) che rompe la convenzione automatica di Rails, quindi va dichiarato a mano su entrambi i lati della relazione. `class_name: "ImportSpi"` su `import_spis` è necessario per lo stesso motivo per cui lo è altrove nel progetto: il nome del metodo (`import_spis`, plurale regolare) non deriva automaticamente dal nome della classe (`ImportSpi`, che Rails pluralizzerebbe in `ImportSpis`) — vedi la stessa scelta in `CodeGuide/ImportSpis/README.md`.
>
> *EN: `has_many :imports` and `has_many :import_spis` are the only two relationships on the class with explicit `foreign_key:` and `inverse_of:`, instead of the Rails-inferred default. The reason: the column on `Import`/`ImportSpi` isn't called `zoning_id` but `azzonamento_di_riferimento_id` — a more descriptive name chosen on the table side (the "reference" zoning for that import) that breaks Rails' automatic convention, so it has to be declared by hand on both sides of the relationship. `class_name: "ImportSpi"` on `import_spis` is needed for the same reason it is elsewhere in the project: the method name (`import_spis`, regular plural) doesn't automatically derive from the class name (`ImportSpi`, which Rails would pluralize as `ImportSpis`) — see the same choice documented in `CodeGuide/ImportSpis/README.md`.*
