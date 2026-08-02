module StatisticPrints
  class SingleSeriesBarChart
    WARNING = "FF851B"
    DANGER = "FF4136"
    SUCCESS = "28B62C"
    PRIMARY = "158CBA"
    INFO = "75CAEB"
    DARK = "555555"
    PALETTE = [ WARNING, DANGER, SUCCESS, PRIMARY, INFO, DARK ].freeze
    AXIS_COLOR = "999999"
    LABEL_COLOR = "666666"
    LABEL_HEIGHT = 20
    LABEL_GAP = 4
    VALUE_HEIGHT = 12
    MAX_GROUP_WIDTH = 90
    BASELINE_HEIGHT = 2
    AXIS_OVERHANG = 5 * 72 / 25.4

    def self.draw(...) = new(...).draw

    def initialize(pdf, at:, width:, height:, labels:, data:, percentages: nil)
      @pdf = pdf
      @at = at
      @width = width
      @height = height
      @labels = labels
      @data = data
      @percentages = percentages
    end

    def draw
      @labels.each_index { |index| draw_group(index) }
      draw_axis_line
    end

    private

    def plot_top = @at[1] - VALUE_HEIGHT
    def plot_bottom = @at[1] - @height + LABEL_HEIGHT
    def plot_height = plot_top - plot_bottom
    def content_width = [ @width, MAX_GROUP_WIDTH * @labels.size ].min
    def content_x = @at[0] + ((@width - content_width) / 2)
    def group_width = content_width / @labels.size
    def max_value = @data.max.to_f * 1.15

    def draw_group(index)
      x = content_x + (index * group_width)
      bar_width = group_width * 0.6
      draw_bar(x + (group_width * 0.2), bar_width, @data[index], PALETTE[index % PALETTE.length], index)
      draw_label(index)
    end

    def draw_bar(x, width, value, color, index)
      bar_height = max_value.zero? ? 0 : (value.to_f / max_value) * plot_height
      drawn_height = [ bar_height, BASELINE_HEIGHT ].max
      @pdf.fill_color color
      @pdf.fill_rectangle [ x, plot_bottom + drawn_height ], width, drawn_height
      draw_value(x, width, bar_height, index)
    end

    def draw_value(x, width, bar_height, index)
      @pdf.fill_color "333333"
      @pdf.font("AsapCondensed", style: :bold, size: 8) do
        @pdf.text_box value_label(index), at: [ x - 20, plot_bottom + bar_height + VALUE_HEIGHT ], width: width + 40,
          align: :center
      end
    end

    def value_label(index)
      return NumberFormatting.percent(@percentages[index]) if @percentages

      NumberFormatting.count(@data[index])
    end

    def draw_label(index)
      x = content_x + (index * group_width)
      @pdf.fill_color LABEL_COLOR
      @pdf.font("AsapCondensed", style: :italic, size: 7) do
        @pdf.text_box @labels[index], at: [ x, plot_bottom - LABEL_GAP ], width: group_width, align: :center,
          overflow: :shrink_to_fit, min_font_size: 5, single_line: true
      end
    end

    def draw_axis_line
      @pdf.stroke_color AXIS_COLOR
      @pdf.stroke_line [ content_x - AXIS_OVERHANG, plot_bottom ], [ content_x + content_width + AXIS_OVERHANG, plot_bottom ]
    end
  end
end
