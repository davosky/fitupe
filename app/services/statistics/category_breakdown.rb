module Statistics
  # Una riga per ciascuna categoria sindacale presente nell'azzonamento
  # scelto (es. FILCAMS, FILLEA, ...), confrontando anno e anno precedente.
  # Riusa lo stesso fallback sull'azzonamento superiore di ZoningPeriodScope.
  class CategoryBreakdown
    Row = Struct.new(:categoria, :count_anno, :count_precedente, :diff, :diff_percent, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, anno_precedente:, mese:)
      @zoning = zoning
      @anno = anno
      @anno_precedente = anno_precedente
      @mese = mese
    end

    def call
      categorie_presenti.map { |categoria| build_row(categoria) }
    end

    private

    def categorie_presenti
      (counts_anno.keys + counts_precedente.keys).uniq.sort
    end

    def build_row(categoria)
      count_anno = counts_anno.fetch(categoria, 0)
      count_precedente = counts_precedente.fetch(categoria, 0)
      diff = count_anno - count_precedente
      diff_percent = count_precedente.zero? ? nil : (diff.to_f / count_precedente * 100)

      Row.new(categoria:, count_anno:, count_precedente:, diff:, diff_percent:)
    end

    def counts_anno
      @counts_anno ||= counts_for(@anno)
    end

    def counts_precedente
      @counts_precedente ||= counts_for(@anno_precedente)
    end

    def counts_for(anno)
      scope = ZoningPeriodScope.call(zoning: @zoning, anno:, mese: @mese)
      scope.where.not(categoria_column(scope) => nil).group(categoria_column(scope)).count
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
