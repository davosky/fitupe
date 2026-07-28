module StatisticPrints
  class CoverPdf
    BACKGROUND_IMAGE = Rails.root.join("app/assets/images/statistic_prints/cover_background.png")
    ASAP_DIR = Rails.root.join("app/assets/fonts")
    CONTENT_MARGIN_MM = 10

    # Fraction-based box (relative to the background image) where the blank
    # space for the dynamic period text sits, below the "Statistiche" headline.
    PERIOD_BOX = { left: 0.5675, top: 0.4662, width: 0.4141, height: 0.0772 }.freeze

    def self.call(...) = new(...).call

    def initialize(form:)
      @form = form
    end

    def call
      Prawn::Document.new(page_size: "A4", page_layout: :landscape, margin: mm_to_pt(CONTENT_MARGIN_MM)) do |pdf|
        register_fonts(pdf)
        pdf.canvas { draw_cover(pdf) }
      end
    end

    private

    def draw_cover(pdf)
      draw_background(pdf)
      draw_period(pdf)
    end

    def draw_background(pdf)
      pdf.image BACKGROUND_IMAGE.to_s, at: [ 0, pdf.bounds.top ], width: pdf.bounds.width, height: pdf.bounds.height
    end

    def draw_period(pdf)
      pdf.fill_color "FFFFFF"
      pdf.font("AsapCondensed", size: 26) do
        pdf.text_box "#{@form.mese} #{@form.anno}", **period_box(pdf), align: :left
      end
    end

    def period_box(pdf)
      width = pdf.bounds.width
      height = pdf.bounds.height
      {
        at: [ PERIOD_BOX[:left] * width, height - (PERIOD_BOX[:top] * height) ],
        width: PERIOD_BOX[:width] * width, height: PERIOD_BOX[:height] * height
      }
    end

    def mm_to_pt(mm) = mm * 72 / 25.4

    def register_fonts(pdf)
      pdf.font_families.update(
        "AsapCondensed" => {
          normal: ASAP_DIR.join("AsapCondensed-Regular.ttf"), bold: ASAP_DIR.join("AsapCondensed-Bold.ttf"),
          italic: ASAP_DIR.join("AsapCondensed-Italic.ttf"), bold_italic: ASAP_DIR.join("AsapCondensed-BoldItalic.ttf")
        }
      )
    end
  end
end
