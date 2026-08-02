module StatisticPrints
  class ZoningDividerPage
    IMAGES_DIR = Rails.root.join("app/assets/images/statistic_prints")
    CGIL_LOGO = IMAGES_DIR.join("logo-cgil.png")

    BLOCK_WIDTH_RATIO = 0.45
    ICON_HEIGHT = 56
    TITLE_SIZE = 26
    ICON_TITLE_GAP = 14
    RULE_GAP = 16
    FOOTER_GAP = 14
    FOOTER_ROW_HEIGHT = 16
    FOOTER_LOGO_HEIGHT = 14
    FOOTER_LABEL_SIZE = 9
    PERIOD_SIZE = 13

    def self.draw(...) = new(...).draw

    def initialize(pdf, zoning:, mese:, anno:)
      @pdf = pdf
      @zoning = zoning
      @mese = mese
      @anno = anno
    end

    def draw
      @pdf.fill_color "000000"
      draw_icon_and_title
      draw_rule
      draw_footer
    end

    private

    def block_width = @pdf.bounds.width * BLOCK_WIDTH_RATIO
    def block_left = @pdf.bounds.left + ((@pdf.bounds.width - block_width) / 2)
    def block_top = (@pdf.bounds.height / 2.0) + (block_height / 2.0)
    def block_height = ICON_HEIGHT + RULE_GAP + FOOTER_GAP + FOOTER_ROW_HEIGHT
    def rule_top = block_top - ICON_HEIGHT - RULE_GAP

    def draw_icon_and_title
      info = @pdf.image CGIL_LOGO.to_s, at: [ block_left, block_top ], height: ICON_HEIGHT
      title_left = block_left + info.scaled_width + ICON_TITLE_GAP
      @pdf.fill_color "000000"
      @pdf.font("AsapCondensed", style: :bold, size: TITLE_SIZE) do
        @pdf.text_box @zoning.descrizione_azzonamento, at: [ title_left, block_top - ((ICON_HEIGHT - TITLE_SIZE) / 2) ],
          width: block_left + block_width - title_left, height: ICON_HEIGHT, valign: :center
      end
    end

    def draw_rule
      @pdf.stroke_color "999999"
      @pdf.stroke_line [ block_left, rule_top ], [ block_left + block_width, rule_top ]
    end

    def draw_footer
      footer_top = rule_top - FOOTER_GAP
      info = @pdf.image CGIL_LOGO.to_s, at: [ block_left, footer_top ], height: FOOTER_LOGO_HEIGHT
      draw_footer_label(block_left + info.scaled_width + 6, footer_top)
      draw_footer_period(footer_top)
    end

    def draw_footer_label(left, top)
      @pdf.fill_color "000000"
      @pdf.font("AsapCondensed", size: FOOTER_LABEL_SIZE) do
        @pdf.text_box "Confederazione Generale Italiana del Lavoro", at: [ left, top ],
          width: block_left + block_width - left, height: FOOTER_ROW_HEIGHT, valign: :center
      end
    end

    def draw_footer_period(top)
      @pdf.fill_color "000000"
      @pdf.font("AsapCondensed", style: :italic, size: PERIOD_SIZE) do
        @pdf.text_box "Tesseramento #{@mese} #{@anno}", at: [ block_left, top ], width: block_width,
          height: FOOTER_ROW_HEIGHT, valign: :center, align: :right
      end
    end
  end
end
