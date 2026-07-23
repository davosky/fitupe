module Statistics
  # Confronta il totale degli iscritti "Attivi" (tutte le categorie tranne
  # SPI) con quello dei "Pensionati" (categoria SPI), anno su anno. Riusa lo
  # stesso fallback sull'azzonamento superiore di ZoningPeriodScope.
  class EmploymentStatusBreakdown
    SPI = "SPI".freeze

    Row = Struct.new(:gruppo, :count_anno, :count_precedente, :diff, :diff_percent, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, anno_precedente:, mese:)
      @zoning = zoning
      @anno = anno
      @anno_precedente = anno_precedente
      @mese = mese
    end

    def call
      [ build_row("Attivi", :attivi), build_row("Pensionati", :pensionati) ]
    end

    private

    def build_row(gruppo, kind)
      count_anno = count_for(@anno, kind)
      count_precedente = count_for(@anno_precedente, kind)
      diff = count_anno - count_precedente
      diff_percent = count_precedente.zero? ? nil : (diff.to_f / count_precedente * 100)

      Row.new(gruppo:, count_anno:, count_precedente:, diff:, diff_percent:)
    end

    def count_for(anno, kind)
      scope = ZoningPeriodScope.call(zoning: @zoning, anno:, mese: @mese)
      pensionati = scope.where(categoria_column(scope) => SPI).count
      kind == :pensionati ? pensionati : scope.count - pensionati
    end

    # La categoria sindacale è stata importata sotto nomi di colonna diversi a
    # seconda dell'intestazione esatta dell'export SinCGIL nel tempo
    # ("Categoria Sindacale" vs "Categoria"). Preferisce categoria_sindacale
    # quando lo scope ha davvero dati in quella colonna, altrimenti categoria.
    def categoria_column(scope)
      if Import.column_names.include?("categoria_sindacale") && scope.where.not(categoria_sindacale: nil).exists?
        :categoria_sindacale
      else
        :categoria
      end
    end
  end
end
