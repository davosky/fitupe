module Statistics
  # Distribuzione degli iscritti per status lavorativo (valori dinamici dal
  # campo tipologia_status, es. Dipendente, Pensionato, ...) nell'anno
  # corrente, in ordine alfabetico, senza confronto con l'anno precedente.
  # La percentuale è calcolata sul totale iscritti dello stesso
  # azzonamento/anno/mese. Riusa lo stesso fallback sull'azzonamento
  # superiore di ZoningPeriodScope.
  class WorkStatusBreakdown
    Row = Struct.new(:tipologia_status, :count, :percentuale, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
    end

    def call
      counts.sort.map { |tipologia_status, count| build_row(tipologia_status, count) }
    end

    private

    def build_row(tipologia_status, count)
      percentuale = totale.zero? ? nil : (count.to_f / totale * 100)

      Row.new(tipologia_status:, count:, percentuale:)
    end

    def counts
      @counts ||= scope.where.not(tipologia_status: nil).group(:tipologia_status).count
    end

    def totale
      @totale ||= scope.count
    end

    def scope
      @scope ||= ZoningPeriodScope.call(zoning: @zoning, anno: @anno, mese: @mese)
    end
  end
end
