module StatisticPrints
  class ZoningDividerPage
    TITLE_SIZE = 28
    SUBTITLE_SIZE = 14
    GAP = 10

    def self.draw(...) = new(...).draw

    def initialize(pdf, zoning:, mese:, anno:)
      @pdf = pdf
      @zoning = zoning
      @mese = mese
      @anno = anno
    end

    def draw
      @pdf.fill_color "000000"
      draw_title
      draw_subtitle
    end

    private

    def block_height = (TITLE_SIZE * 1.2) + GAP + (SUBTITLE_SIZE * 1.2)
    def top = (@pdf.bounds.height / 2.0) + (block_height / 2.0)

    def draw_title
      @pdf.font("AsapCondensed", style: :bold, size: TITLE_SIZE) do
        @pdf.text_box @zoning.descrizione_azzonamento, at: [ @pdf.bounds.left, top ], width: @pdf.bounds.width,
          height: TITLE_SIZE * 1.2, align: :center, valign: :center
      end
    end

    def draw_subtitle
      @pdf.font("AsapCondensed", style: :italic, size: SUBTITLE_SIZE) do
        @pdf.text_box "#{@mese} #{@anno}", at: [ @pdf.bounds.left, top - (TITLE_SIZE * 1.2) - GAP ],
          width: @pdf.bounds.width, height: SUBTITLE_SIZE * 1.2, align: :center, valign: :center
      end
    end
  end
end
