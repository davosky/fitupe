module Statistics
  # Per ogni categoria, il mese con la maggiore crescita e quello con il
  # maggiore calo rispetto al mese precedente, nell'anno scelto e nel
  # precedente. Riusa i conteggi (già integrati FILLEA/FLC e con l'anno
  # precedente tagliato allo stesso mese) di AnnualCategoryProgression; il
  # primo confronto possibile è Febbraio su Gennaio.
  class MonthlyCategoryProgression
    Result = Struct.new(:anno, :anno_precedente, :rows, :error) do
      def success? = error.blank?
    end

    Row = Struct.new(:categoria, :anno, :precedente)
    Extremes = Struct.new(:progressione, :regressione)
    Change = Struct.new(:mese, :diff, :diff_percent)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:)
      @progression = AnnualCategoryProgression.call(zoning:, anno:)
    end

    def call
      return Result.new(error: @progression.error) unless @progression.success?

      precedente = @progression.rows_precedente.index_by(&:categoria)
      rows = @progression.rows_anno.map do |row|
        Row.new(categoria: row.categoria, anno: extremes(row), precedente: extremes(precedente[row.categoria]))
      end
      Result.new(anno: @progression.anno, anno_precedente: @progression.anno_precedente, rows:)
    end

    private

    # Solo variazioni effettive: senza alcun mese in crescita (o in calo) il
    # rispettivo estremo resta nil invece di mostrare un falso "miglior mese".
    def extremes(row)
      changes = changes(row.counts)
      Extremes.new(progressione: changes.select { |c| c.diff.positive? }.max_by(&:diff),
        regressione: changes.select { |c| c.diff.negative? }.min_by(&:diff))
    end

    def changes(counts)
      @progression.mesi.drop(1).zip(counts.each_cons(2)).map do |mese, (prima, dopo)|
        Change.new(mese:, diff: dopo - prima, diff_percent: prima.zero? ? nil : (dopo - prima).to_f / prima * 100)
      end
    end
  end
end
