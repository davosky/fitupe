module StatisticWithIntegrations
  # Riusa Statistics::TotalMembersComparison per tutte le sezioni della
  # dashboard e ricalibra con FilleaCorrection le sole sezioni toccate dalla
  # direttiva Cassa Edile: totale, comprensori, la riga FILLEA di categorie e
  # la riga "Ordinaria C.E." di tipologie_delega. Le altre sezioni (nazionalità,
  # sesso, fasce età, ecc.) non hanno un equivalente Cassa Edile e passano
  # invariate da Statistics.
  class TotalMembersComparison
    Result = Struct.new(:zoning, :mese, :anno, :anno_precedente, :count_anno, :count_precedente, :diff,
      :diff_percent, :comprensori, :categorie, :attivi_pensionati, :tipologie_iscrizione, :tipologie_delega,
      :nazionalita, :sesso, :provvisorie_revoche, :status_lavorativo, :fasce_eta, :fillea_correzione, :error,
      keyword_init: true) do
      def success? = error.blank?
    end

    ORDINARIA_CE = "Ordinaria C.E.".freeze

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
      @anno_precedente = (anno.to_i - 1).to_s
    end

    def call
      base = Statistics::TotalMembersComparison.call(zoning: @zoning, anno: @anno, mese: @mese)
      return missing_result(base.error) unless base.success?

      correzione_anno = FilleaCorrection.call(zoning: @zoning, anno: @anno, mese: @mese)
      return missing_result(correzione_anno.error) unless correzione_anno.success?

      correzione_precedente = FilleaCorrection.call(zoning: @zoning, anno: @anno_precedente, mese: @mese)
      build_result(base, correzione_anno, correzione_precedente)
    end

    private

    def build_result(base, correzione_anno, correzione_precedente)
      diff_anno = correzione_anno.total_diff
      diff_precedente = diff_precedente_for(@zoning, correzione_precedente)
      count_anno, count_precedente, diff, diff_percent =
        recalibrate(count_anno: base.count_anno, count_precedente: base.count_precedente,
          diff_anno:, diff_precedente:)

      Result.new(zoning: @zoning, mese: @mese, anno: @anno, anno_precedente: @anno_precedente,
        count_anno:, count_precedente:, diff:, diff_percent:,
        comprensori: recalibrate_comprensori(base.comprensori, correzione_anno, correzione_precedente),
        categorie: recalibrate_named(base.categorie, :categoria, "FILLEA", diff_anno, diff_precedente),
        tipologie_delega: recalibrate_named(base.tipologie_delega, :tipologia, ORDINARIA_CE, diff_anno,
          diff_precedente),
        attivi_pensionati: base.attivi_pensionati, tipologie_iscrizione: base.tipologie_iscrizione,
        nazionalita: base.nazionalita, sesso: base.sesso, provvisorie_revoche: base.provvisorie_revoche,
        status_lavorativo: base.status_lavorativo, fasce_eta: base.fasce_eta,
        fillea_correzione: correzione_anno)
    end

    def recalibrate_comprensori(comprensori, correzione_anno, correzione_precedente)
      comprensori.map do |riga|
        diff_anno = correzione_anno.rows.find { |r| r.zoning == riga.zoning }&.diff || 0
        diff_precedente = diff_precedente_for(riga.zoning, correzione_precedente)
        count_anno, count_precedente, diff, diff_percent =
          recalibrate(count_anno: riga.count_anno, count_precedente: riga.count_precedente, diff_anno:,
            diff_precedente:)

        riga.class.new(zoning: riga.zoning, count_anno:, count_precedente:, diff:, diff_percent:)
      end
    end

    # ricalibra una singola riga di un breakdown (categorie/tipologie_delega)
    # individuata per nome, sommando lo stesso diff aggregato del totale
    def recalibrate_named(righe, attributo, valore, diff_anno, diff_precedente)
      righe.map do |riga|
        next riga unless riga.public_send(attributo) == valore

        count_anno, count_precedente, diff, diff_percent =
          recalibrate(count_anno: riga.count_anno, count_precedente: riga.count_precedente, diff_anno:,
            diff_precedente:)

        riga.class.new(attributo => valore, count_anno:, count_precedente:, diff:, diff_percent:)
      end
    end

    def diff_precedente_for(zoning, correzione_precedente)
      return 0 unless correzione_precedente.success?

      correzione_precedente.rows.find { |r| r.zoning == zoning }&.diff || 0
    end

    def recalibrate(count_anno:, count_precedente:, diff_anno:, diff_precedente:)
      nuovo_anno = count_anno + diff_anno
      nuovo_precedente = count_precedente + diff_precedente
      nuovo_diff = nuovo_anno - nuovo_precedente
      nuovo_diff_percent = nuovo_precedente.zero? ? nil : (nuovo_diff.to_f / nuovo_precedente * 100)

      [ nuovo_anno, nuovo_precedente, nuovo_diff, nuovo_diff_percent ]
    end

    def missing_result(error)
      Result.new(zoning: @zoning, mese: @mese, anno: @anno, anno_precedente: @anno_precedente, error:)
    end
  end
end
