module StatisticSpi
  # Conta le pratiche provvisorie (colonna provvisoria = 'SI'), a livello
  # regionale e per comprensorio. Nessuna riconciliazione DISTINCT ON e'
  # necessaria (ogni provvisoria e' gia' un record additivo). Come
  # CessazioniBreakdown la percentuale e' calcolata sul totale deleghe del
  # periodo, non sul totale delle provvisorie stesse (sono un sottoinsieme
  # delle deleghe, non le esauriscono).
  class ProvvisorieBreakdown
    Row = Struct.new(:zoning, :totale, :deleghe_totale, :percentuale, keyword_init: true)
    Result = Struct.new(:totale, :comprensori, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
    end

    def call
      if @zoning.regionale?
        Result.new(totale: build_row(@zoning, counts_by_comprensorio.values.sum, deleghe_by_comprensorio.values.sum),
          comprensori: province_zonings.map { |zoning| build_row(zoning, counts_by_comprensorio[zoning.codice_azzonamento].to_i,
            deleghe_by_comprensorio[zoning.codice_azzonamento]) })
      else
        Result.new(totale: build_row(@zoning, counts_by_comprensorio[@zoning.codice_azzonamento].to_i,
          deleghe_by_comprensorio[@zoning.codice_azzonamento]), comprensori: [])
      end
    end

    private

    def build_row(zoning, totale, deleghe_totale)
      deleghe_totale ||= 0
      percentuale = deleghe_totale.zero? ? nil : (totale.to_f / deleghe_totale * 100)

      Row.new(zoning:, totale:, deleghe_totale:, percentuale:)
    end

    def province_zonings
      Zoning.comprensori_di(@zoning)
    end

    def regional_zoning
      @zoning.regionale? ? @zoning : Zoning.find_by(codice_azzonamento: @zoning.codice_azzonamento[0])
    end

    def regional_scope
      return ImportSpi.none if regional_zoning.nil?

      ZoningPeriodScope.call(zoning: regional_zoning, anno: @anno, mese: @mese)
    end

    def deleghe_by_comprensorio
      @deleghe_by_comprensorio ||= regional_scope.group("SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2)").count
    end

    def counts_by_comprensorio
      @counts_by_comprensorio ||= regional_scope.where(provvisoria: "SI")
        .group("SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2)").count
    end
  end
end
