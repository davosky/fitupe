module StatisticPrints
  class ReportPdf
    ASAP_DIR = Rails.root.join("app/assets/fonts")
    CONTENT_MARGIN_TOP_MM = 15
    CONTENT_MARGIN_BOTTOM_MM = 15
    CONTENT_MARGIN_LR_MM = 15

    CONTENT_PAGES = [
      RegionalPage, CategoriesPage, EmploymentStatusPage, MembershipTypesPage, NationalityGenderPage,
      WorkStatusAgePage
    ].freeze

    def self.call(...) = new(...).call

    def initialize(form:, comparison_service: Statistics::TotalMembersComparison)
      @form = form
      @comparison_service = comparison_service
    end

    def call
      margin = [ mm_to_pt(CONTENT_MARGIN_TOP_MM), mm_to_pt(CONTENT_MARGIN_LR_MM),
                mm_to_pt(CONTENT_MARGIN_BOTTOM_MM), mm_to_pt(CONTENT_MARGIN_LR_MM) ]
      Prawn::Document.new(page_size: "A4", page_layout: :landscape, margin: margin) do |pdf|
        register_fonts(pdf)
        pdf.canvas { CoverPage.draw(pdf, form: @form) }
        draw_legend(pdf)
        draw_content_pages(pdf, @form)
        draw_province_sections(pdf)
      end
    end

    private

    def draw_legend(pdf)
      return unless @form.legend

      pdf.start_new_page
      LegendPage.draw(pdf, form: @form)
    end

    def draw_content_pages(pdf, form)
      CONTENT_PAGES.each do |page_class|
        pdf.start_new_page
        page_class.draw(pdf, form: form, comparison_service: @comparison_service)
      end
    end

    # Quando l'azzonamento scelto è regionale, ripete l'intero set di pagine
    # per ciascun comprensorio (provincia), interponendo una pagina divisoria
    # con il nome dell'azzonamento e il periodo scelto.
    def draw_province_sections(pdf)
      return unless @form.zoning.regionale?

      Zoning.comprensori_di(@form.zoning).each do |zoning|
        pdf.start_new_page
        ZoningDividerPage.draw(pdf, zoning: zoning, mese: @form.mese, anno: @form.anno)
        draw_content_pages(pdf, province_form(zoning))
      end
    end

    def province_form(zoning)
      TotalMembersForm.new(zoning_id: zoning.id, anno: @form.anno, mese: @form.mese)
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
