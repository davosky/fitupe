module StatisticPrints
  class ReportPdf
    ASAP_DIR = Rails.root.join("app/assets/fonts")
    CONTENT_MARGIN_TOP_MM = 15
    CONTENT_MARGIN_BOTTOM_MM = 15
    CONTENT_MARGIN_LR_MM = 15

    CONTENT_PAGES = [
      RegionalPage, CategoriesPage, EmploymentStatusPage, MembershipTypesPage, ProvisionalRevocationsPage,
      NationalityGenderPage, WorkStatusAgePage
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
        draw_zoning_section(pdf, @form.zoning, @form)
        draw_province_sections(pdf)
        draw_back_cover(pdf)
      end
    end

    private

    def draw_legend(pdf)
      return unless @form.legend

      pdf.start_new_page
      LegendPage.draw(pdf, form: @form)
    end

    # Una pagina divisoria con il nome dell'azzonamento, seguita dal set
    # completo di pagine di contenuto per quell'azzonamento.
    def draw_zoning_section(pdf, zoning, form)
      pdf.start_new_page
      ZoningDividerPage.draw(pdf, zoning: zoning, mese: @form.mese, anno: @form.anno)
      draw_content_pages(pdf, form)
    end

    def draw_content_pages(pdf, form)
      CONTENT_PAGES.each do |page_class|
        pdf.start_new_page
        page_class.draw(pdf, form: form, comparison_service: @comparison_service)
      end
    end

    # Quando l'azzonamento scelto è regionale, ripete l'intera sezione
    # (pagina divisoria + set di pagine di contenuto) per ciascun comprensorio.
    def draw_province_sections(pdf)
      return unless @form.zoning.regionale?

      Zoning.comprensori_di(@form.zoning).each do |zoning|
        draw_zoning_section(pdf, zoning, province_form(zoning))
      end
    end

    # Chiude il fascicolo con la controcopertina. Se il numero di pagine fin
    # qui è dispari, inserisce prima una pagina bianca: così l'interno del
    # fascicolo (esclusa la controcopertina) ha un numero di pagine pari,
    # pronto per la stampa fisica fronte/retro.
    def draw_back_cover(pdf)
      pdf.start_new_page if pdf.page_count.odd?
      pdf.start_new_page
      pdf.canvas { BackCoverPage.draw(pdf) }
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
