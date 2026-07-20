module IntegrationFlcs
  # Compares an Anagrafe FLC extract against the SinCGIL data already
  # imported (Import) for the same azzonamento/anno/mese, and stores the
  # count of codici fiscali present in Anagrafe FLC but missing from
  # SinCGIL as the corresponding IntegrationFlc record.
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
      integration_flc.subscribers_af = missing_codici_fiscali.size
      integration_flc.save!

      Result.new(integration_flc: integration_flc)
    rescue AnagrafeCsvParser::InvalidFile => e
      Result.new(error: e.message)
    end

    private

    def sincgil_import_exists?
      Import.exists?(azzonamento_di_riferimento_id: @zoning_id, anno_di_riferimento: @year, mese_di_riferimento: @month)
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

    def sincgil_codici_fiscali
      Import.where(azzonamento_di_riferimento_id: @zoning_id, anno_di_riferimento: @year,
        mese_di_riferimento: @month, categoria_sindacale: CATEGORIA_SINDACALE)
        .pluck(:codice_fiscale)
        .filter_map { |codice_fiscale| codice_fiscale&.strip&.upcase.presence }
        .to_set
    end
  end
end
