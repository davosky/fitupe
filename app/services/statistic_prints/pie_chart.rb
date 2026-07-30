module StatisticPrints
  class PieChart
    COLORS = %w[28B62C FF851B FF4136].freeze
    LEGEND_HEIGHT = 16
    ARC_STEP_DEGREES = 3
    SIZE_RATIO = 0.65

    def self.draw(...) = new(...).draw

    def initialize(pdf, at:, width:, height:, labels:, data:)
      @pdf = pdf
      @at = at
      @width = width
      @height = height
      @labels = labels
      @data = data
    end

    def draw
      draw_slices
      draw_legend
    end

    private

    def total = @data.sum.to_f
    def circle_area_height = @height - LEGEND_HEIGHT
    def diameter = [ @width, circle_area_height ].min * SIZE_RATIO
    def radius = diameter / 2.0
    def center = [ @at[0] + (@width / 2.0), @at[1] - (circle_area_height / 2.0) ]

    def draw_slices
      return if total.zero?

      angle = 90.0
      @data.each_index do |index|
        fraction = @data[index] / total
        sweep = fraction * 360.0
        draw_slice(angle, sweep, COLORS[index % COLORS.length])
        draw_label(angle, sweep, @data[index], fraction) if @data[index].positive?
        angle -= sweep
      end
    end

    def draw_slice(start_deg, sweep_deg, color)
      return if sweep_deg.zero?

      @pdf.fill_color color
      @pdf.fill_polygon(*([ center ] + arc_points(start_deg, sweep_deg)))
    end

    def arc_points(start_deg, sweep_deg)
      steps = [ (sweep_deg / ARC_STEP_DEGREES).ceil, 1 ].max
      (0..steps).map { |step| point_at(start_deg - (sweep_deg * step / steps)) }
    end

    def point_at(deg)
      rad = deg * Math::PI / 180
      [ center[0] + (radius * Math.cos(rad)), center[1] + (radius * Math.sin(rad)) ]
    end

    def draw_label(start_deg, sweep_deg, value, fraction)
      rad = (start_deg - (sweep_deg / 2.0)) * Math::PI / 180
      label_radius = radius * 0.6
      x = center[0] + (label_radius * Math.cos(rad))
      y = center[1] + (label_radius * Math.sin(rad))

      @pdf.fill_color "FFFFFF"
      @pdf.font("AsapCondensed", style: :bold, size: 8) do
        @pdf.text_box NumberFormatting.count(value), at: [ x - 30, y + 10 ], width: 60, align: :center
        @pdf.text_box "(#{NumberFormatting.percent(fraction * 100)})", at: [ x - 30, y - 2 ], width: 60, align: :center
      end
    end

    def draw_legend
      x = @at[0] + ((@width - legend_width) / 2)
      y = @at[1] - circle_area_height - 2
      @labels.each_index do |index|
        draw_legend_item(x, y, COLORS[index % COLORS.length], @labels[index])
        x += legend_item_width(index)
      end
    end

    def draw_legend_item(x, y, color, label)
      @pdf.fill_color color
      @pdf.fill_rectangle [ x, y ], 8, 8
      @pdf.fill_color "333333"
      @pdf.font("AsapCondensed", size: 8) { @pdf.draw_text label, at: [ x + 12, y - 6 ] }
    end

    def legend_item_width(index)
      label_width = nil
      @pdf.font("AsapCondensed", size: 8) { label_width = @pdf.width_of(@labels[index]) }
      12 + label_width + 14
    end

    def legend_width
      @labels.each_index.sum { |index| legend_item_width(index) } - 14
    end
  end
end
