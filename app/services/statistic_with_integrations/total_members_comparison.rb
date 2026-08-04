module StatisticWithIntegrations
  # Riusa Statistics::TotalMembersComparison per tutte le sezioni della
  # dashboard e ricalibra con FilleaCorrection/FlcCorrection le sezioni
  # toccate dalle due direttive di integrazione dati esterni: totale,
  # comprensori, le righe FILLEA/FLC di categorie, le righe "Ordinaria
  # C.E."/"Delega Tesoro" di tipologie_delega, la riga "Attivi" di
  # attivi_pensionati (Pensionati = SPI, mai toccato dalle integrazioni) e la
  # riga "Delega" di tipologie_iscrizione (i lavoratori aggiunti da Cassa
  # Edile/Anagrafe sono per definizione a delega, mai BreviManu) — senza
  # ricalibrare anche queste due sezioni, la loro somma non torna più con il
  # totale corretto. Le altre sezioni (nazionalità, sesso, fasce età, ecc.)
  # non hanno un equivalente esterno e passano invariate da Statistics.
  class TotalMembersComparison
    Result = Struct.new(:zoning, :mese, :anno, :anno_precedente, :count_anno, :count_precedente, :diff,
      :diff_percent, :comprensori, :categorie, :attivi_pensionati, :tipologie_iscrizione, :tipologie_delega,
      :nazionalita, :sesso, :provvisorie_revoche, :status_lavorativo, :fasce_eta, :fillea_correzione,
      :flc_correzione, :error, keyword_init: true) do
      def success? = error.blank?
    end

    ORDINARIA_CE = "Ordinaria C.E.".freeze
    DELEGA_TESORO = "Delega Tesoro".freeze
    ATTIVI = "Attivi".freeze

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

      fillea_anno = FilleaCorrection.call(zoning: @zoning, anno: @anno, mese: @mese)
      return missing_result(fillea_anno.error) unless fillea_anno.success?

      flc_anno = FlcCorrection.call(zoning: @zoning, anno: @anno, mese: @mese)
      return missing_result(flc_anno.error) unless flc_anno.success?

      fillea_precedente = FilleaCorrection.call(zoning: @zoning, anno: @anno_precedente, mese: @mese)
      flc_precedente = FlcCorrection.call(zoning: @zoning, anno: @anno_precedente, mese: @mese)

      build_result(base, fillea_anno, fillea_precedente, flc_anno, flc_precedente)
    end

    private

    def build_result(base, fillea_anno, fillea_precedente, flc_anno, flc_precedente)
      fillea_diff_precedente = total_diff_precedente(fillea_precedente)
      flc_diff_precedente = total_diff_precedente(flc_precedente)

      diff_anno = fillea_anno.total_diff + flc_anno.total_diff
      diff_precedente = fillea_diff_precedente + flc_diff_precedente
      count_anno, count_precedente, diff, diff_percent =
        recalibrate(count_anno: base.count_anno, count_precedente: base.count_precedente, diff_anno:,
          diff_precedente:)

      categorie = recalibrate_named(base.categorie, :categoria, "FILLEA", fillea_anno.total_diff,
        fillea_diff_precedente)
      categorie = recalibrate_named(categorie, :categoria, "FLC", flc_anno.total_diff, flc_diff_precedente)

      tipologie_delega = recalibrate_named(base.tipologie_delega, :tipologia, ORDINARIA_CE, fillea_anno.total_diff,
        fillea_diff_precedente)
      tipologie_delega = recalibrate_named(tipologie_delega, :tipologia, DELEGA_TESORO, flc_anno.total_diff,
        flc_diff_precedente)

      tipologie_iscrizione = recalibrate_named(base.tipologie_iscrizione, :tipologia,
        Statistics::MembershipTypeBreakdown::DELEGA, diff_anno, diff_precedente)

      Result.new(zoning: @zoning, mese: @mese, anno: @anno, anno_precedente: @anno_precedente,
        count_anno:, count_precedente:, diff:, diff_percent:,
        comprensori: recalibrate_comprensori(base.comprensori, fillea_anno, fillea_precedente, flc_anno,
          flc_precedente),
        categorie:, tipologie_delega:, tipologie_iscrizione:,
        attivi_pensionati: recalibrate_attivi_pensionati(base.attivi_pensionati, diff_anno, diff_precedente,
          count_anno),
        nazionalita: base.nazionalita, sesso: base.sesso, provvisorie_revoche: base.provvisorie_revoche,
        status_lavorativo: base.status_lavorativo, fasce_eta: base.fasce_eta,
        fillea_correzione: fillea_anno, flc_correzione: flc_anno)
    end

    def recalibrate_comprensori(comprensori, fillea_anno, fillea_precedente, flc_anno, flc_precedente)
      comprensori.map do |riga|
        diff_anno = diff_for(riga.zoning, fillea_anno) + diff_for(riga.zoning, flc_anno)
        diff_precedente = diff_precedente_for(riga.zoning, fillea_precedente) +
          diff_precedente_for(riga.zoning, flc_precedente)
        count_anno, count_precedente, diff, diff_percent =
          recalibrate(count_anno: riga.count_anno, count_precedente: riga.count_precedente, diff_anno:,
            diff_precedente:)

        riga.class.new(zoning: riga.zoning, count_anno:, count_precedente:, diff:, diff_percent:)
      end
    end

    # ricalibra una singola riga di un breakdown (categorie/tipologie_delega)
    # individuata per nome, sommando il diff aggregato passato
    def recalibrate_named(righe, attributo, valore, diff_anno, diff_precedente)
      righe.map do |riga|
        next riga unless riga.public_send(attributo) == valore

        count_anno, count_precedente, diff, diff_percent =
          recalibrate(count_anno: riga.count_anno, count_precedente: riga.count_precedente, diff_anno:,
            diff_precedente:)

        riga.class.new(attributo => valore, count_anno:, count_precedente:, diff:, diff_percent:)
      end
    end

    # ricalibra la riga "Attivi" (Pensionati = SPI, non toccato dalle
    # integrazioni) e ricalcola la percentuale di entrambe le righe sul nuovo
    # totale corretto, invariato per il gruppo Pensionati.
    def recalibrate_attivi_pensionati(righe, diff_anno, diff_precedente, totale_anno_corretto)
      righe.map do |riga|
        if riga.gruppo == ATTIVI
          count_anno, count_precedente, diff, diff_percent =
            recalibrate(count_anno: riga.count_anno, count_precedente: riga.count_precedente, diff_anno:,
              diff_precedente:)
        else
          count_anno, count_precedente, diff, diff_percent =
            riga.count_anno, riga.count_precedente, riga.diff, riga.diff_percent
        end

        percentuale = totale_anno_corretto.zero? ? nil : (count_anno.to_f / totale_anno_corretto * 100)
        riga.class.new(gruppo: riga.gruppo, count_anno:, count_precedente:, diff:, diff_percent:, percentuale:)
      end
    end

    def diff_for(zoning, correzione)
      correzione.rows.find { |r| r.zoning == zoning }&.diff || 0
    end

    def diff_precedente_for(zoning, correzione_precedente)
      return 0 unless correzione_precedente.success?

      diff_for(zoning, correzione_precedente)
    end

    def total_diff_precedente(correzione_precedente)
      correzione_precedente.success? ? correzione_precedente.total_diff : 0
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
