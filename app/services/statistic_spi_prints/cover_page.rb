module StatisticSpiPrints
  class CoverPage
    BACKGROUND_IMAGE = Rails.root.join("app/assets/images/statistic_prints/cover_background_spi.png")

    # Fraction-based boxes (relative to the background image) where the blank
    # spaces for the dynamic azzonamento/mese/anno text sit.
    ZONING_BOX = { left: 0.8164, top: 0.1411, width: 0.1240, height: 0.0290 }.freeze
    MONTH_BOX = { left: 0.8073, top: 0.2540, width: 0.0892, height: 0.0423 }.freeze
    YEAR_BOX = { left: 0.8965, top: 0.2540, width: 0.0656, height: 0.0423 }.freeze

    def self.draw(...) = new(...).draw

    def initialize(pdf, form:)
      @pdf = pdf
      @form = form
    end

    def draw
      draw_background
      draw_zoning
      draw_month
      draw_year
    end

    private

    def draw_background
      @pdf.image BACKGROUND_IMAGE.to_s, at: [ 0, @pdf.bounds.top ], width: @pdf.bounds.width, height: @pdf.bounds.height
    end

    def draw_zoning
      @pdf.fill_color "FFFFFF"
      @pdf.font("AsapCondensed", size: 13) do
        @pdf.text_box @form.zoning.descrizione_azzonamento, **fractional_box(ZONING_BOX), align: :left
      end
    end

    def draw_month
      @pdf.fill_color "FFFFFF"
      @pdf.font("AsapCondensed", size: 20) do
        @pdf.text_box @form.mese, **fractional_box(MONTH_BOX), align: :center
      end
    end

    def draw_year
      @pdf.fill_color "FFFFFF"
      @pdf.font("AsapCondensed", size: 20) do
        @pdf.text_box @form.anno, **fractional_box(YEAR_BOX), align: :center
      end
    end

    def fractional_box(box)
      width = @pdf.bounds.width
      height = @pdf.bounds.height
      {
        at: [ box[:left] * width, height - (box[:top] * height) ],
        width: box[:width] * width, height: box[:height] * height
      }
    end
  end
end
