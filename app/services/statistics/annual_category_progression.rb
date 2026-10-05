module Statistics
  # Come AnnualProgression (stessi mesi, controlli e crescita %), ma con una
  # riga per categoria sindacale dell'azzonamento scelto invece che per
  # comprensorio. Le integrazioni si sommano solo alle righe FILLEA e FLC, come
  # in Statistiche Con Integrazioni.
  class AnnualCategoryProgression < AnnualProgression
    CATEGORY_CORRECTIONS = {
      "FILLEA" => StatisticWithIntegrations::FilleaCorrection, "FLC" => StatisticWithIntegrations::FlcCorrection
    }.freeze

    Row = Struct.new(:categoria, :counts, :crescita) { def label = categoria }
    Gap = Struct.new(:categoria, :crescita_precedente, :crescita_anno, :differenza) { def label = categoria }

    private

    def rows(anno)
      (@rows ||= {})[anno] ||= categorie.map do |categoria|
        counts = mesi.map { |mese| counts_by(anno).fetch([ categoria, mese ], 0) + integrazione(categoria, anno, mese) }
        Row.new(categoria:, counts:, crescita: crescita(counts.first, counts.last))
      end
    end

    def gaps
      precedente = rows(@anno_precedente).index_by(&:categoria)
      rows(@anno).map do |row|
        prev = precedente[row.categoria].crescita
        differenza = row.crescita - prev if row.crescita && prev
        Gap.new(categoria: row.categoria, crescita_precedente: prev, crescita_anno: row.crescita, differenza:)
      end
    end

    def categorie
      @categorie ||= [ @anno, @anno_precedente ].flat_map { |anno| counts_by(anno).keys.map(&:first) }.uniq.sort
    end

    # { [categoria, mese] => conteggio } con una sola query per anno. Lo stesso
    # anno può avere mesi importati con "Categoria" e altri con "Categoria
    # Sindacale": Import.categoria_sql le unisce.
    def counts_by(anno)
      categoria = Import.categoria_sql
      (@counts_by ||= {})[anno] ||= scope(@zoning, anno, mesi).where.not(Arel.sql("#{categoria} IS NULL"))
        .group(Arel.sql(categoria), :mese_di_riferimento).count
    end

    def integrazione(categoria, anno, mese)
      correction = CATEGORY_CORRECTIONS[categoria]
      return 0 unless correction

      result = correction.call(zoning: @zoning, anno:, mese:)
      result.success? ? result.total_diff : 0
    end
  end
end
