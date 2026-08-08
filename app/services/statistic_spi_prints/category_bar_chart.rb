module StatisticSpiPrints
  # Grafico a barre a singola serie per tipologia di delega, colori fissi per
  # categoria a specchio della palette Bootstrap usata in bar_chart_controller.js
  # (warning/danger/success/primary/info), in ordine con
  # StatisticSpi::TipologieDelegaBreakdown::ETICHETTE.
  class CategoryBarChart
    COLORS = %w[FF851B FF4136 28B62C 158CBA 75CAEB].freeze
    AXIS_COLOR = "999999"
    LABEL_COLOR = "666666"
    LABEL_HEIGHT = 24
    LABEL_GAP = 4
    PERCENT_HEIGHT = 12
    BASELINE_HEIGHT = 2
    BAR_WIDTH_RATIO = 0.5
    AXIS_OVERHANG = 5 * 72 / 25.4

    def self.draw(...) = new(...).draw

    def initialize(pdf, at:, width:, height:, labels:, values:, percentages:)
      @pdf = pdf
      @at = at
      @width = width
      @height = height
      @labels = labels
      @values = values
      @percentages = percentages
    end

    def draw
      @labels.each_index { |index| draw_bar(index) }
      draw_axis_line
    end

    private

    def plot_top = @at[1] - PERCENT_HEIGHT
    def plot_bottom = @at[1] - @height + LABEL_HEIGHT
    def plot_height = plot_top - plot_bottom
    def group_width = @width / @labels.size
    def max_value = [ @values.max.to_f, 1 ].max * 1.15

    def draw_axis_line
      @pdf.stroke_color AXIS_COLOR
      @pdf.stroke_line [ @at[0] - AXIS_OVERHANG, plot_bottom ], [ @at[0] + @width + AXIS_OVERHANG, plot_bottom ]
    end

    def draw_bar(index)
      x = @at[0] + (index * group_width)
      bar_width = group_width * BAR_WIDTH_RATIO
      bar_x = x + ((group_width - bar_width) / 2)
      bar_height = max_value.zero? ? 0 : (@values[index].to_f / max_value) * plot_height
      drawn_height = [ bar_height, BASELINE_HEIGHT ].max

      @pdf.fill_color COLORS[index % COLORS.length]
      @pdf.fill_rectangle [ bar_x, plot_bottom + drawn_height ], bar_width, drawn_height
      draw_percentage(bar_x, bar_width, drawn_height, @percentages[index])
      draw_label(x, index)
    end

    def draw_percentage(x, width, bar_height, percentage)
      return if percentage.nil?

      @pdf.fill_color "333333"
      @pdf.font("AsapCondensed", style: :bold, size: 8) do
        @pdf.text_box StatisticPrints::NumberFormatting.percent(percentage),
          at: [ x - 15, plot_bottom + bar_height + PERCENT_HEIGHT ], width: width + 30, align: :center
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
