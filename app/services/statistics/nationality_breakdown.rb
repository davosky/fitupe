module Statistics
  # Distribuzione degli iscritti per nazionalità (ITALIANA, UE, EXTRAUE)
  # nell'anno corrente, senza confronto con l'anno precedente. Riusa lo
  # stesso fallback sull'azzonamento superiore di ZoningPeriodScope.
  class NationalityBreakdown
    NAZIONALITA = {
      "ITALIANA" => "ITALIA",
      "UE" => "UE",
      "EXTRAUE" => "EXTRAUE"
    }.freeze

    Row = Struct.new(:nazionalita, :count, :percentuale, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
    end

    def call
      totale = counts.values.sum
      NAZIONALITA.keys.map { |nazionalita| build_row(nazionalita, totale) }
    end

    private

    def build_row(nazionalita, totale)
      count = counts.fetch(nazionalita, 0)
      percentuale = totale.zero? ? nil : (count.to_f / totale * 100)

      Row.new(nazionalita:, count:, percentuale:)
    end

    def counts
      @counts ||= NAZIONALITA.each_with_object({}) do |(nazionalita, valore), memo|
        memo[nazionalita] = scope.where(nazionalita: valore).count
      end
    end

    def scope
      @scope ||= ZoningPeriodScope.call(zoning: @zoning, anno: @anno, mese: @mese)
    end
  end
end
