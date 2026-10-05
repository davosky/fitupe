module StatisticPrints
  # Disegno condiviso dalle pagine dei due fascicoli (Attivi e SPI):
  # conversione mm → punti, spaziature, intestazione di pagina e messaggi.
  # Le spaziature leggono SECTION_GAP_MM / COLUMN_GAP_MM della classe che
  # include il modulo.
  module PageLayout
    private

    def mm(value) = value * 72 / 25.4
    def section_gap = mm(self.class::SECTION_GAP_MM)
    def column_gap = mm(self.class::COLUMN_GAP_MM)
    def period_subtitle = "Tesseramento #{@form.mese} #{@form.anno}"

    # Titolo in grassetto, sottotitolo grigio opzionale e filetto orizzontale.
    def draw_page_heading(title, subtitle: nil, gap: section_gap)
      @pdf.font("AsapCondensed", style: :bold, size: 16) { @pdf.text title }
      draw_page_subtitle(subtitle) if subtitle
      @pdf.move_down 8
      @pdf.stroke_color "CCCCCC"
      @pdf.stroke_horizontal_rule
      @pdf.move_down gap
    end

    def draw_page_subtitle(subtitle)
      @pdf.move_down 2
      @pdf.font("AsapCondensed", size: 10) { @pdf.text subtitle, color: "666666" }
    end

    def draw_message(message, color = "666666")
      @pdf.font("AsapCondensed", size: 12) { @pdf.text message, color: color }
    end
  end
end
