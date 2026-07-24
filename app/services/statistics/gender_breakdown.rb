module Statistics
  # Distribuzione degli iscritti per sesso (FEMMINE, MASCHI) nell'anno
  # corrente, senza confronto con l'anno precedente. Riusa lo stesso
  # fallback sull'azzonamento superiore di ZoningPeriodScope.
  class GenderBreakdown
    SESSI = {
      "FEMMINE" => "F",
      "MASCHI" => "M"
    }.freeze

    Row = Struct.new(:sesso, :count, :percentuale, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
    end

    def call
      totale = counts.values.sum
      SESSI.keys.map { |sesso| build_row(sesso, totale) }
    end

    private

    def build_row(sesso, totale)
      count = counts.fetch(sesso, 0)
      percentuale = totale.zero? ? nil : (count.to_f / totale * 100)

      Row.new(sesso:, count:, percentuale:)
    end

    def counts
      @counts ||= SESSI.each_with_object({}) do |(sesso, valore), memo|
        memo[sesso] = scope.where(sesso: valore).count
      end
    end

    def scope
      @scope ||= ZoningPeriodScope.call(zoning: @zoning, anno: @anno, mese: @mese)
    end
  end
end
