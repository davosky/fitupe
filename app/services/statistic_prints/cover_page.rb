module StatisticPrints
  class CoverPage
    BACKGROUND_IMAGE = Rails.root.join("app/assets/images/statistic_prints/cover_background.png")

    # Fraction-based box (relative to the background image) where the blank
    # space for the dynamic period text sits, below the "Statistiche" headline.
    PERIOD_BOX = { left: 0.5675, top: 0.4662, width: 0.4141, height: 0.0772 }.freeze

    def self.draw(...) = new(...).draw

    def initialize(pdf, form:)
      @pdf = pdf
      @form = form
    end

    def draw
      draw_background
      draw_period
    end

    private

    def draw_background
      @pdf.image BACKGROUND_IMAGE.to_s, at: [ 0, @pdf.bounds.top ], width: @pdf.bounds.width, height: @pdf.bounds.height
    end

    def draw_period
      @pdf.fill_color "FFFFFF"
      @pdf.font("AsapCondensed", size: 26) do
        @pdf.text_box "#{@form.mese} #{@form.anno}", **period_box, align: :left
      end
    end

    def period_box
      width = @pdf.bounds.width
      height = @pdf.bounds.height
      {
        at: [ PERIOD_BOX[:left] * width, height - (PERIOD_BOX[:top] * height) ],
        width: PERIOD_BOX[:width] * width, height: PERIOD_BOX[:height] * height
      }
    end
  end
end
