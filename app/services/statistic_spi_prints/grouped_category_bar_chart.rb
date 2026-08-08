module StatisticSpiPrints
  # Grafico a barre raggruppate per comprensorio, una serie colorata per
  # tipologia di delega (stessa palette di CategoryBarChart), a specchio di
  # grouped_bar_chart_controller.js lato schermo. A differenza di CategoryBarChart
  # (una sola serie) qui serve anche la legenda per distinguere le tipologie.
  class GroupedCategoryBarChart
    COLORS = CategoryBarChart::COLORS
    AXIS_COLOR = "999999"
    LABEL_COLOR = "666666"
    LEGEND_ROW_HEIGHT = 12
    LEGEND_ITEM_GAP = 10
    LABEL_HEIGHT = 18
    LABEL_GAP = 4
    PERCENT_HEIGHT = 10
    BASELINE_HEIGHT = 1
    BAR_WIDTH_RATIO = 0.15
    AXIS_OVERHANG = 4 * 72 / 25.4

    def self.draw(...) = new(...).draw

    def initialize(pdf, at:, width:, height:, labels:, series_labels:, series_values:)
      @pdf = pdf
      @at = at
      @width = width
      @height = height
      @labels = labels
      @series_labels = series_labels
      @series_values = series_values
    end

    def draw
      legend_rows = pack_legend_rows
      draw_legend(legend_rows)
      @labels.each_index { |index| draw_group(index, legend_rows.size) }
      draw_axis_line
    end

    private

    def plot_top(legend_row_count) = @at[1] - (legend_row_count * LEGEND_ROW_HEIGHT) - PERCENT_HEIGHT
    def plot_bottom = @at[1] - @height + LABEL_HEIGHT
    def plot_height(legend_row_count) = plot_top(legend_row_count) - plot_bottom
    def group_width = @width / @labels.size
    def max_value = [ @series_values.flatten.max.to_f, 1 ].max * 1.15

    def pack_legend_rows
      rows = [ [] ]
      x = 0
      @series_labels.each_index do |index|
        item_width = legend_item_width(index)
        if x + item_width > @width && rows.last.any?
          rows << []
          x = 0
        end
        rows.last << index
        x += item_width + LEGEND_ITEM_GAP
      end
      rows
    end

    def legend_item_width(index)
      label_width = nil
      @pdf.font("AsapCondensed", size: 8) { label_width = @pdf.width_of(@series_labels[index]) }
      10 + label_width + 6
    end

    def draw_legend(rows)
      rows.each_index do |row_index|
        x = @at[0]
        y = @at[1] - (row_index * LEGEND_ROW_HEIGHT)
        rows[row_index].each do |index|
          x = draw_legend_item(x, y, index)
        end
      end
    end

    def draw_legend_item(x, y, index)
      @pdf.fill_color COLORS[index % COLORS.length]
      @pdf.fill_rectangle [ x, y ], 8, 8
      @pdf.fill_color "333333"
      label_width = 0
      @pdf.font("AsapCondensed", size: 8) do
        label_width = @pdf.width_of(@series_labels[index])
        @pdf.draw_text @series_labels[index], at: [ x + 10, y - 6 ]
      end
      x + 10 + label_width + 6 + LEGEND_ITEM_GAP
    end

    def draw_axis_line
      @pdf.stroke_color AXIS_COLOR
      @pdf.stroke_line [ @at[0] - AXIS_OVERHANG, plot_bottom ], [ @at[0] + @width + AXIS_OVERHANG, plot_bottom ]
    end

    def draw_group(index, legend_row_count)
      x = @at[0] + (index * group_width)
      bar_width = group_width * BAR_WIDTH_RATIO
      slot_width = group_width / @series_labels.size
      @series_labels.each_index { |series_index| draw_bar(x, slot_width, series_index, index, bar_width, legend_row_count) }
      draw_label(x, index)
    end

    def draw_bar(group_x, slot_width, series_index, group_index, bar_width, legend_row_count)
      value = @series_values[series_index][group_index]
      x = group_x + (series_index * slot_width) + ((slot_width - bar_width) / 2)
      bar_height = max_value.zero? ? 0 : (value.to_f / max_value) * plot_height(legend_row_count)
      drawn_height = value.to_f.positive? ? [ bar_height, BASELINE_HEIGHT ].max : 0

      @pdf.fill_color COLORS[series_index % COLORS.length]
      @pdf.fill_rectangle [ x, plot_bottom + drawn_height ], bar_width, drawn_height
      draw_percentage(x, bar_width, drawn_height, value)
    end

    def draw_percentage(x, width, bar_height, value)
      return unless value.to_f.positive?

      @pdf.fill_color "333333"
      @pdf.font("AsapCondensed", style: :bold, size: 6) do
        @pdf.text_box StatisticPrints::NumberFormatting.percent(value),
          at: [ x - 10, plot_bottom + bar_height + PERCENT_HEIGHT ], width: width + 20, align: :center
      end
    end

    def draw_label(x, index)
      @pdf.fill_color LABEL_COLOR
      @pdf.font("AsapCondensed", style: :italic, size: 8) do
        @pdf.text_box @labels[index], at: [ x, plot_bottom - LABEL_GAP ], width: group_width, align: :center
      end
    end
  end
end
