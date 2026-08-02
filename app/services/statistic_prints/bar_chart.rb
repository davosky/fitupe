module StatisticPrints
  class BarChart
    SUCCESS = "28B62C"
    WARNING = "FF851B"
    DANGER = "FF4136"
    AXIS_COLOR = "999999"
    LABEL_COLOR = "666666"
    LEGEND_HEIGHT = 16
    LEGEND_ITEM_GAP = 16
    LABEL_HEIGHT = 20
    LABEL_GAP = 4
    PERCENT_HEIGHT = 14
    MAX_GROUP_WIDTH = 200
    MAX_WIDTH_RATIO = 0.7
    BASELINE_HEIGHT = 2
    AXIS_OVERHANG = 5 * 72 / 25.4

    def self.draw(...) = new(...).draw

    def initialize(pdf, at:, width:, height:, labels:, previous_data:, current_data:, percentages:,
      previous_label:, current_label:)
      @pdf = pdf
      @width = width * MAX_WIDTH_RATIO
      @at = [ at[0] + ((width - @width) / 2), at[1] ]
      @height = height
      @labels = labels
      @previous_data = previous_data
      @current_data = current_data
      @percentages = percentages
      @previous_label = previous_label
      @current_label = current_label
    end

    def draw
      draw_legend
      @labels.each_index { |index| draw_group(index) }
      draw_axis_line
    end

    private

    def plot_top = @at[1] - LEGEND_HEIGHT - PERCENT_HEIGHT
    def plot_bottom = @at[1] - @height + LABEL_HEIGHT
    def plot_height = plot_top - plot_bottom
    def content_width = [ @width, MAX_GROUP_WIDTH * @labels.size ].min
    def content_x = @at[0] + ((@width - content_width) / 2)
    def group_width = content_width / @labels.size
    def max_value = [ @previous_data.max, @current_data.max ].max.to_f * 1.15

    def draw_legend
      x = draw_legend_item(@at[0], SUCCESS, @previous_label)
      draw_legend_item(x, WARNING, @current_label)
    end

    def draw_legend_item(x, color, label)
      @pdf.fill_color color
      @pdf.fill_rectangle [ x, @at[1] ], 10, 10
      @pdf.fill_color "333333"
      label_width = 0
      @pdf.font("AsapCondensed", size: 9) do
        label_width = @pdf.width_of(label)
        @pdf.draw_text label, at: [ x + 14, @at[1] - 8 ]
      end
      x + 14 + label_width + LEGEND_ITEM_GAP
    end

    def draw_axis_line
      @pdf.stroke_color AXIS_COLOR
      @pdf.stroke_line [ content_x - AXIS_OVERHANG, plot_bottom ], [ content_x + content_width + AXIS_OVERHANG, plot_bottom ]
    end

    def draw_group(index)
      x = content_x + (index * group_width)
      bar_width = group_width * 0.32
      draw_bar(x + (group_width * 0.12), bar_width, @previous_data[index], SUCCESS)
      draw_bar(x + (group_width * 0.52), bar_width, @current_data[index], WARNING, percentage: @percentages[index])
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
      @pdf.font("AsapCondensed", style: :bold, size: 9) do
        @pdf.text_box "#{sign}#{NumberFormatting.percent(percentage)}",
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
