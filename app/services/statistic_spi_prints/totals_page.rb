module StatisticSpiPrints
  # Pagina "Totali Iscritti-Deleghe": specchia app/views/statistic_spi/_totale_card
  # e _comprensori_section, ma con le due metriche affiancate in colonne (anziche'
  # impilate come a schermo) per stare in una singola pagina landscape.
  class TotalsPage
    include StatisticPrints::PageLayout

    MAX_CHART_HEIGHT_MM = 75
    SECTION_GAP_MM = 8
    COLUMN_GAP_MM = 10
    METRIC_COLOR = "FF4136"

    def self.draw(...) = new(...).draw

    def initialize(pdf, form:, comparison_service: StatisticSpi::TotalMembersComparison)
      @pdf = pdf
      @form = form
      @comparison_service = comparison_service
    end

    def draw
      result = @comparison_service.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
      @pdf.fill_color "000000"
      draw_heading(result)
      return draw_message(result.error, "DC3545") unless result.success?

      draw_columns(result)
    end

    private

    def draw_heading(result) = draw_page_heading(heading_title(result.zoning), subtitle: period_subtitle)

    def heading_title(zoning)
      return "CGIL Totale Iscritti e Deleghe SPI – Regionale e Comprensori" if zoning.regionale?

      "CGIL Totale Iscritti e Deleghe SPI – Comprensorio di #{zoning.descrizione_azzonamento}"
    end

    def draw_columns(result)
      top = @pdf.cursor
      left = @pdf.bounds.left

      iscritti_bottom = draw_column(left, top, "Iscritti", result, :iscritti_totale, :iscritti_comprensori, "iscritti")
      deleghe_bottom = draw_column(left + column_width + column_gap, top, "Deleghe", result, :deleghe_totale,
        :deleghe_comprensori, "deleghe")

      draw_chart(result, [ iscritti_bottom, deleghe_bottom ].min)
    end

    def draw_column(x, top, title, result, totale_key, comprensori_key, metric_label)
      cursor_after = nil
      @pdf.bounding_box([ x, top ], width: column_width, height: top) do
        draw_metric_title(title)
        totale_row = result.public_send(totale_key)
        StatisticPrints::ComparisonTable.draw(
          @pdf, title: totale_row.zoning.descrizione_azzonamento, mese: result.mese, anno: result.anno,
          anno_precedente: result.anno_precedente, rows: [ row_for(totale_row) ], metric_label: metric_label
        )
        comprensori_rows = result.public_send(comprensori_key)
        draw_comprensori_table(comprensori_rows, result, metric_label) if comprensori_rows.present?
        cursor_after = @pdf.cursor
      end
      cursor_after
    end

    def draw_comprensori_table(rows, result, metric_label)
      @pdf.move_down 8
      StatisticPrints::ComparisonTable.draw(
        @pdf, title: "Comprensori", mese: result.mese, anno: result.anno, anno_precedente: result.anno_precedente,
        rows: rows.map { |row| row_for(row) }, metric_label: metric_label
      )
    end

    def draw_metric_title(title)
      @pdf.font("AsapCondensed", style: :bold, size: 13) { @pdf.text title, color: METRIC_COLOR }
      @pdf.move_down 4
    end

    def row_for(row)
      { label: row.zoning.descrizione_azzonamento, count_precedente: row.count_precedente, count_anno: row.count_anno,
        diff: row.diff, diff_percent: row.diff_percent }
    end

    def draw_chart(result, columns_bottom)
      chart_top = columns_bottom - section_gap
      height = [ chart_top - 6, mm(MAX_CHART_HEIGHT_MM) ].min
      entries = chart_entries(result)

      BarChart.draw(
        @pdf, at: [ @pdf.bounds.left, chart_top ], width: @pdf.bounds.width, height: height,
        labels: entries.map { |iscritti, _| iscritti.zoning.descrizione_azzonamento },
        iscritti_previous: entries.map { |iscritti, _| iscritti.count_precedente },
        iscritti_current: entries.map { |iscritti, _| iscritti.count_anno },
        deleghe_previous: entries.map { |_, deleghe| deleghe.count_precedente },
        deleghe_current: entries.map { |_, deleghe| deleghe.count_anno },
        iscritti_percentages: entries.map { |iscritti, _| iscritti.diff_percent },
        deleghe_percentages: entries.map { |_, deleghe| deleghe.diff_percent },
        previous_label: "#{result.mese} #{result.anno_precedente}", current_label: "#{result.mese} #{result.anno}"
      )
    end

    def chart_entries(result)
      return result.iscritti_comprensori.zip(result.deleghe_comprensori) if result.iscritti_comprensori.present?

      [ [ result.iscritti_totale, result.deleghe_totale ] ]
    end

    def column_width = (@pdf.bounds.width - column_gap) / 2
  end
end
