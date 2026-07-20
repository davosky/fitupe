module IntegrationFlcs
  # Compares an Anagrafe FLC extract against the SinCGIL data already
  # imported (Import) for the same azzonamento/anno/mese, and stores the
  # reconciled total (SinCGIL FLC members for that azzonamento, plus those
  # found in Anagrafe FLC but still missing from SinCGIL) as the
  # corresponding IntegrationFlc record's subscribers_af.
  class ComparisonService
    CATEGORIA_SINDACALE = "FLC"

    Result = Struct.new(:integration_flc, :error, keyword_init: true) do
      def success? = error.nil?
    end

    def self.call(...)
      new(...).call
    end

    def initialize(file:, zoning_id:, year:, month:)
      @file = file
      @zoning_id = zoning_id
      @year = year
      @month = month
    end

    def call
      return Result.new(error: missing_sincgil_message) unless sincgil_import_exists?

      integration_flc = IntegrationFlc.find_or_initialize_by(zoning_id: @zoning_id, year: @year, month: @month)
      integration_flc.subscribers_af = sincgil_codici_fiscali.size + missing_codici_fiscali.size
      integration_flc.save!

      Result.new(integration_flc: integration_flc)
    rescue AnagrafeCsvParser::InvalidFile => e
      Result.new(error: e.message)
    end

    private

    def sincgil_import_exists?
      Import.exists?(azzonamento_di_riferimento_id: candidate_zoning_ids, anno_di_riferimento: @year,
        mese_di_riferimento: @month)
    end

    def missing_sincgil_message
      "Devi prima caricare i dati SinCGIL relativi a questo azzonamento, anno e mese."
    end

    def missing_codici_fiscali
      anagrafe_codici_fiscali - sincgil_codici_fiscali
    end

    def anagrafe_codici_fiscali
      @anagrafe_codici_fiscali ||= AnagrafeCsvParser.call(@file)
    end

    # Scoped by azzonamento_di_riferimento (the batch a human chose when
    # importing, regional or provincial per candidate_zoning_ids) and, within
    # that batch, by the per-record codice_azzonamento_completo actually
    # starting with the selected province/region's own code — a regional
    # batch holds every province's members, so this narrows it back down.
    def sincgil_codici_fiscali
      @sincgil_codici_fiscali ||= Import
        .where(azzonamento_di_riferimento_id: candidate_zoning_ids, anno_di_riferimento: @year,
          mese_di_riferimento: @month, categoria_sindacale: CATEGORIA_SINDACALE)
        .where("codice_azzonamento_completo LIKE ?", "#{zoning.codice_azzonamento}%")
        .pluck(:codice_fiscale)
        .filter_map { |codice_fiscale| codice_fiscale&.strip&.upcase.presence }
        .to_set
    end

    # A SinCGIL export can be extracted at the broader "regionale" level
    # (codice_azzonamento a single letter, e.g. "G") covering every province
    # at once, instead of at the specific "provincia" level (e.g. "GB") the
    # operator selected. Either counts as "the import for this azzonamento".
    def candidate_zoning_ids
      @candidate_zoning_ids ||= [ @zoning_id, regional_zoning_id ].compact.uniq
    end

    def regional_zoning_id
      codice = zoning&.codice_azzonamento
      return nil if codice.blank? || codice.length <= 1

      Zoning.find_by(codice_azzonamento: codice[0])&.id
    end

    def zoning
      @zoning ||= Zoning.find_by(id: @zoning_id)
    end
  end
end
