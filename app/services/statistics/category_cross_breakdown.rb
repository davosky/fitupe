module Statistics
  # Una riga per categoria sindacale, con il conteggio e la percentuale (sul
  # totale della categoria) di ciascun valore di un secondo attributo (sesso,
  # nazionalità) nel solo anno corrente. Con altro: true aggiunge la colonna
  # ALTRO, cioè gli iscritti della categoria con un valore diverso da quelli
  # elencati (o assente). Riusa il fallback di ZoningPeriodScope.
  class CategoryCrossBreakdown
    ALTRO = "ALTRO".freeze

    Cell = Struct.new(:label, :count, :percentuale, keyword_init: true)
    Row = Struct.new(:categoria, :cells, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:, column:, values:, altro: false)
      @zoning = zoning
      @anno = anno
      @mese = mese
      @column = column
      @values = values
      @altro = altro
    end

    def call
      counts.keys.map(&:first).uniq.sort.map { |categoria| build_row(categoria) }
    end

    private

    def build_row(categoria)
      conteggi = @values.transform_values { |valore| counts.fetch([ categoria, valore ], 0) }
      conteggi[ALTRO] = totale_categoria(categoria) - conteggi.values.sum if @altro
      totale = conteggi.values.sum

      Row.new(categoria:, cells: conteggi.map { |label, count| build_cell(label, count, totale) })
    end

    def build_cell(label, count, totale)
      Cell.new(label:, count:, percentuale: totale.zero? ? nil : (count.to_f / totale * 100))
    end

    def totale_categoria(categoria)
      counts.sum { |(cat, _valore), count| cat == categoria ? count : 0 }
    end

    # { [categoria, valore] => conteggio } con una sola query.
    def counts
      categoria = Import.categoria_sql
      @counts ||= ZoningPeriodScope.call(zoning: @zoning, anno: @anno, mese: @mese)
        .where.not(Arel.sql("#{categoria} IS NULL")).group(Arel.sql(categoria), @column).count
    end
  end
end
