module Statistics
  # Distribuzione degli iscritti per fascia d'età (calcolata da data_nascita
  # rispetto alla data odierna) nell'anno corrente, senza confronto con
  # l'anno precedente. Riusa lo stesso fallback sull'azzonamento superiore di
  # ZoningPeriodScope. Le fasce sono calcolate con un'unica query SQL
  # raggruppata (CASE + GROUP BY), senza caricare i singoli iscritti in Ruby.
  class AgeBreakdown
    BANDS = [
      [ "GIOVANI", 30 ],
      [ "TRENTENNI", 40 ],
      [ "QUARANTENNI", 50 ],
      [ "CINQUANTENNI", 60 ],
      [ "SESSANTENNI", 70 ],
      [ "SETTANTENNI", 80 ],
      [ "OTTANTENNI", 90 ],
      [ "NOVANTENNI", 100 ],
      [ "HIGHLANDERS", nil ]
    ].freeze

    AGE_EXPR = "EXTRACT(YEAR FROM AGE(data_nascita))".freeze

    Row = Struct.new(:fascia, :count, :percentuale, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
    end

    def call
      BANDS.map { |fascia, _| build_row(fascia) }
    end

    private

    def build_row(fascia)
      count = counts.fetch(fascia, 0)
      percentuale = totale.zero? ? nil : (count.to_f / totale * 100)

      Row.new(fascia:, count:, percentuale:)
    end

    def counts
      @counts ||= scope.where.not(data_nascita: nil).group(Arel.sql(band_case_sql)).count
    end

    def totale
      @totale ||= scope.count
    end

    def scope
      @scope ||= ZoningPeriodScope.call(zoning: @zoning, anno: @anno, mese: @mese)
    end

    def band_case_sql
      whens = BANDS.filter_map { |fascia, upper| "WHEN #{AGE_EXPR} < #{upper} THEN '#{fascia}'" if upper }
      "CASE #{whens.join(' ')} ELSE 'HIGHLANDERS' END"
    end
  end
end
