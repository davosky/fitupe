module StatisticPrints
  class BarChart
    SUCCESS = "28B62C"
    WARNING = "FF851B"
    DANGER = "FF4136"
    LEGEND_HEIGHT = 16
    LABEL_HEIGHT = 16
    PERCENT_HEIGHT = 14
    MAX_GROUP_WIDTH = 200

    def self.draw(...) = new(...).draw

    def initialize(pdf, at:, width:, height:, labels:, previous_data:, current_data:, percentages:,
      previous_label:, current_label:)
      @pdf = pdf
      @at = at
      @width = width
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
      draw_legend_item(0, SUCCESS, @previous_label)
      draw_legend_item(1, WARNING, @current_label)
    end

    def draw_legend_item(index, color, label)
      x = @at[0] + (index * 160)
      @pdf.fill_color color
      @pdf.fill_rectangle [ x, @at[1] ], 10, 10
      @pdf.fill_color "333333"
      @pdf.font("AsapCondensed", size: 9) { @pdf.draw_text label, at: [ x + 14, @at[1] - 8 ] }
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
      @pdf.fill_color color
      @pdf.fill_rectangle [ x, plot_bottom + bar_height ], width, bar_height
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
      @pdf.fill_color "333333"
      @pdf.font("AsapCondensed", size: 9) do
        @pdf.text_box @labels[index], at: [ x, plot_bottom ], width: group_width, align: :center
      end
    end
  end
end
