module StatisticPrints
  # Ultima pagina di contenuto: "Genere Per Categoria" e "Nazionalità Per
  # Categoria" affiancate, solo tabelle (anno corrente), senza grafici.
  class CategoryGenderNationalityPage
    include PageLayout

    SECTION_GAP_MM = 6
    IMAGES_DIR = Rails.root.join("app/assets/images/statistic_prints")
    COLUMN_GAP_MM = 10

    def self.draw(...) = new(...).draw

    def initialize(pdf, form:, comparison_service: Statistics::TotalMembersComparison)
      @pdf = pdf
      @form = form
      @comparison_service = comparison_service
    end

    def draw
      result = @comparison_service.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
      @pdf.fill_color "000000"
      draw_heading(result)
      return draw_message(result.error, "DC3545") unless result.success?

      top = @pdf.cursor
      draw_table("Genere per Categoria", "sesso.png", result.sesso_per_categoria, @pdf.bounds.left, top)
      draw_table("Nazionalità per Categoria", "nazionalita.png", result.nazionalita_per_categoria,
        @pdf.bounds.left + column_width + column_gap, top)
    end

    private

    def draw_heading(result)
      draw_page_heading("Per Categoria: Genere e Nazionalità - #{result.zoning.descrizione_azzonamento} - " \
                        "#{result.mese} #{result.anno}")
    end

    def draw_table(title, icon, rows, x, top)
      @pdf.bounding_box([ x, top ], width: column_width, height: top) do
        if rows.blank?
          draw_message("Nessun dato di #{title} presente per il periodo selezionato.", "666666")
        else
          CategoryCrossTable.draw(@pdf, rows: rows, title: title, icon: IMAGES_DIR.join(icon))
        end
      end
    end

    def column_width = (@pdf.bounds.width - column_gap) / 2.0
  end
end
