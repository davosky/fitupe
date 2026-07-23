module Statistics
  # Risolve lo scope di Import per un azzonamento/anno/mese. Se l'azzonamento
  # scelto (es. "GB") non ha importazioni dirette, ricade sui dati importati
  # sotto l'azzonamento superiore (es. "G") filtrati per
  # codice_azzonamento_completo.
  class ZoningPeriodScope
    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
    end

    def call
      exact_scope = Import.where(azzonamento_di_riferimento_id: @zoning.id, anno_di_riferimento: @anno,
        mese_di_riferimento: @mese)
      return exact_scope if exact_scope.exists?

      regional_scope
    end

    private

    def regional_scope
      return Import.none if regional_zoning_id.nil?

      Import.where(azzonamento_di_riferimento_id: regional_zoning_id, anno_di_riferimento: @anno,
        mese_di_riferimento: @mese).where("codice_azzonamento_completo LIKE ?", "#{@zoning.codice_azzonamento}%")
    end

    def regional_zoning_id
      codice = @zoning.codice_azzonamento
      return nil if codice.blank? || codice.length <= 1

      Zoning.find_by(codice_azzonamento: codice[0])&.id
    end
  end
end
