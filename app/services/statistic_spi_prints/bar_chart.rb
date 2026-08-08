module StatisticSpiPrints
  # Come StatisticPrints::BarChart ma con 4 serie (Iscritti/Deleghe x anno
  # precedente/corrente) raggruppate per comprensorio nello stesso grafico,
  # a specchio di spi_comparison_chart_controller.js lato schermo.
  class BarChart
    ISCRITTI_PREVIOUS = "28B62C"
    ISCRITTI_CURRENT = "FF851B"
    DELEGHE_PREVIOUS = "75CAEB"
    DELEGHE_CURRENT = "FF4136"
    SUCCESS = "28B62C"
    DANGER = "FF4136"
    AXIS_COLOR = "999999"
    LABEL_COLOR = "666666"
    LEGEND_HEIGHT = 16
    LEGEND_ITEM_GAP = 12
    LEGEND_ROW_GAP = 14
    LABEL_HEIGHT = 20
    LABEL_GAP = 4
    PERCENT_HEIGHT = 12
    MAX_GROUP_WIDTH = 220
    MAX_WIDTH_RATIO = 0.9
    BASELINE_HEIGHT = 2
    AXIS_OVERHANG = 5 * 72 / 25.4

    def self.draw(...) = new(...).draw

    def initialize(pdf, at:, width:, height:, labels:, iscritti_previous:, iscritti_current:, deleghe_previous:,
      deleghe_current:, iscritti_percentages:, deleghe_percentages:, previous_label:, current_label:)
      @pdf = pdf
      @width = width * MAX_WIDTH_RATIO
      @at = [ at[0] + ((width - @width) / 2), at[1] ]
      @height = height
      @labels = labels
      @iscritti_previous = iscritti_previous
      @iscritti_current = iscritti_current
      @deleghe_previous = deleghe_previous
      @deleghe_current = deleghe_current
      @iscritti_percentages = iscritti_percentages
      @deleghe_percentages = deleghe_percentages
      @previous_label = previous_label
      @current_label = current_label
    end

    def draw
      draw_legend
      @labels.each_index { |index| draw_group(index) }
      draw_axis_line
    end

    private

    def plot_top = @at[1] - (LEGEND_HEIGHT * 2) - LEGEND_ROW_GAP - PERCENT_HEIGHT
    def plot_bottom = @at[1] - @height + LABEL_HEIGHT
    def plot_height = plot_top - plot_bottom
    def content_width = [ @width, MAX_GROUP_WIDTH * @labels.size ].min
    def content_x = @at[0] + ((@width - content_width) / 2)
    def group_width = content_width / @labels.size
    def all_values = @iscritti_previous + @iscritti_current + @deleghe_previous + @deleghe_current
    def max_value = all_values.max.to_f * 1.15

    def draw_legend
      row1_y = @at[1]
      row2_y = @at[1] - LEGEND_ROW_GAP
      x = draw_legend_item(@at[0], ISCRITTI_PREVIOUS, "Iscritti #{@previous_label}", row1_y)
      draw_legend_item(x, ISCRITTI_CURRENT, "Iscritti #{@current_label}", row1_y)
      x = draw_legend_item(@at[0], DELEGHE_PREVIOUS, "Deleghe #{@previous_label}", row2_y)
      draw_legend_item(x, DELEGHE_CURRENT, "Deleghe #{@current_label}", row2_y)
    end

    def draw_legend_item(x, color, label, y)
      @pdf.fill_color color
      @pdf.fill_rectangle [ x, y ], 9, 9
      @pdf.fill_color "333333"
      label_width = 0
      @pdf.font("AsapCondensed", size: 8) do
        label_width = @pdf.width_of(label)
        @pdf.draw_text label, at: [ x + 12, y - 7 ]
      end
      x + 12 + label_width + LEGEND_ITEM_GAP
    end

    def draw_axis_line
      @pdf.stroke_color AXIS_COLOR
      @pdf.stroke_line [ content_x - AXIS_OVERHANG, plot_bottom ], [ content_x + content_width + AXIS_OVERHANG, plot_bottom ]
    end

    def draw_group(index)
      x = content_x + (index * group_width)
      bar_width = group_width * 0.19
      draw_bar(x + (group_width * 0.06), bar_width, @iscritti_previous[index], ISCRITTI_PREVIOUS)
      draw_bar(x + (group_width * 0.28), bar_width, @iscritti_current[index], ISCRITTI_CURRENT,
        percentage: @iscritti_percentages[index])
      draw_bar(x + (group_width * 0.53), bar_width, @deleghe_previous[index], DELEGHE_PREVIOUS)
      draw_bar(x + (group_width * 0.75), bar_width, @deleghe_current[index], DELEGHE_CURRENT,
        percentage: @deleghe_percentages[index])
      draw_label(index)
    end

    def draw_bar(x, width, value, color, percentage: nil)
      bar_height = max_value.zero? ? 0 : (value.to_f / max_value) * plot_height
      drawn_height = [ bar_height, BASELINE_HEIGHT ].max
      @pdf.fill_color color
      @pdf.fill_rectangle [ x, plot_bottom + drawn_height ], width, drawn_height
      draw_percentage(x, width, bar_height, percentage) if percentage
    end

    def draw_percentage(x, width, bar_height, percentage)
      color = percentage.negative? ? DANGER : SUCCESS
      sign = percentage.positive? ? "+" : ""
      @pdf.fill_color color
      @pdf.font("AsapCondensed", style: :bold, size: 7) do
        @pdf.text_box "#{sign}#{StatisticPrints::NumberFormatting.percent(percentage)}",
          at: [ x - 20, plot_bottom + bar_height + PERCENT_HEIGHT ], width: width + 40, align: :center
      end
    end

    def draw_label(index)
      x = content_x + (index * group_width)
      @pdf.fill_color LABEL_COLOR
      @pdf.font("AsapCondensed", style: :italic, size: 9) do
        @pdf.text_box @labels[index], at: [ x, plot_bottom - LABEL_GAP ], width: group_width, align: :center
      end
    end
  end
end
