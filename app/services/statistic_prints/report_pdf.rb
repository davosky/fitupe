module StatisticPrints
  class ReportPdf
    ASAP_DIR = Rails.root.join("app/assets/fonts")
    CONTENT_MARGIN_TOP_MM = 15
    CONTENT_MARGIN_BOTTOM_MM = 15
    CONTENT_MARGIN_LR_MM = 15

    def self.call(...) = new(...).call

    def initialize(form:)
      @form = form
    end

    def call
      margin = [ mm_to_pt(CONTENT_MARGIN_TOP_MM), mm_to_pt(CONTENT_MARGIN_LR_MM),
                mm_to_pt(CONTENT_MARGIN_BOTTOM_MM), mm_to_pt(CONTENT_MARGIN_LR_MM) ]
      Prawn::Document.new(page_size: "A4", page_layout: :landscape, margin: margin) do |pdf|
        register_fonts(pdf)
        pdf.canvas { CoverPage.draw(pdf, form: @form) }
        if @form.legend
          pdf.start_new_page
          LegendPage.draw(pdf, form: @form)
        end
        pdf.start_new_page
        RegionalPage.draw(pdf, form: @form)
        pdf.start_new_page
        CategoriesPage.draw(pdf, form: @form)
      end
    end

    private

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
