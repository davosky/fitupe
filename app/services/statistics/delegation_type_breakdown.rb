module Statistics
  # Una riga per ciascuna tipologia di delega (Ordinaria, Ordinaria C.E.,
  # NASPI, DS Agricola, Delega Tesoro, Concomitante), più la riga speciale
  # "Conc. SPI Anno" basata sulla colonna concomitante_spi_anno anziché su
  # tipologia_delega. Riusa lo stesso fallback sull'azzonamento superiore di
  # ZoningPeriodScope.
  class DelegationTypeBreakdown
    TIPOLOGIE = {
      "Ordinaria" => "Ordinaria",
      "Ordinaria C.E." => "Ordinaria Cassa Edile",
      "NASPI" => "NASPI",
      "DS Agricola" => "DS Agricola",
      "Delega Tesoro" => "Delega Tesoro",
      "Concomitante" => "Concomitante"
    }.freeze

    CONC_SPI_ANNO = "Conc. SPI Anno".freeze

    Row = Struct.new(:tipologia, :count_anno, :count_precedente, :diff, :diff_percent, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, anno_precedente:, mese:)
      @zoning = zoning
      @anno = anno
      @anno_precedente = anno_precedente
      @mese = mese
    end

    def call
      righe = TIPOLOGIE.map { |tipologia, valore| build_row(tipologia) { |scope| scope.where(tipologia_delega: valore) } }
      righe + [ build_row(CONC_SPI_ANNO) { |scope| scope.where(concomitante_spi_anno: "SI") } ]
    end

    private

    def build_row(tipologia, &scope_filter)
      count_anno = count_for(@anno, &scope_filter)
      count_precedente = count_for(@anno_precedente, &scope_filter)
      diff = count_anno - count_precedente
      diff_percent = count_precedente.zero? ? nil : (diff.to_f / count_precedente * 100)

      Row.new(tipologia:, count_anno:, count_precedente:, diff:, diff_percent:)
    end

    def count_for(anno, &scope_filter)
      scope = ZoningPeriodScope.call(zoning: @zoning, anno:, mese: @mese)
      scope_filter.call(scope).count
    end
  end
end
