module StatisticPrints
  class PieChart
    COLORS = %w[28B62C FF851B FF4136].freeze
    LEGEND_HEIGHT = 16
    ARC_STEP_DEGREES = 3
    SIZE_RATIO = 0.65
    # Sotto questa ampiezza la fetta e' troppo stretta per contenere
    # l'etichetta al suo interno: esce fuori dal cerchio, collegata da una
    # linea (a specchio delle "callout label" dei grafici a torta).
    SMALL_SLICE_THRESHOLD_DEGREES = 20
    EXTERNAL_LABEL_WIDTH = 70
    EXTERNAL_LABEL_TEXT_COLOR = "333333"
    EXTERNAL_LABEL_LINE_COLOR = "999999"
    LEADER_LENGTH = 12
    # Fette piccole consecutive (tipico caso: piu' comprensori con percentuali
    # minime) avrebbero altrimenti le etichette esterne tutte alla stessa
    # distanza dal cerchio, sovrapposte fra loro: ogni etichetta esterna in
    # piu' si allontana un po' di piu' dalla precedente.
    LEADER_STAGGER_STEP = 11

    def self.draw(...) = new(...).draw

    def initialize(pdf, at:, width:, height:, labels:, data:, colors: COLORS, label_formatter: nil)
      @pdf = pdf
      @at = at
      @width = width
      @height = height
      @labels = labels
      @data = data
      @colors = colors
      @label_formatter = label_formatter || method(:default_label)
      @external_label_count = 0
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
        draw_slice(angle, sweep, @colors[index % @colors.length])
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
      if sweep_deg < SMALL_SLICE_THRESHOLD_DEGREES
        draw_external_label(start_deg, sweep_deg, value, fraction)
      else
        draw_internal_label(start_deg, sweep_deg, value, fraction)
      end
    end

    def draw_internal_label(start_deg, sweep_deg, value, fraction)
      rad = (start_deg - (sweep_deg / 2.0)) * Math::PI / 180
      label_radius = radius * 0.6
      x = center[0] + (label_radius * Math.cos(rad))
      y = center[1] + (label_radius * Math.sin(rad))

      draw_label_lines(@label_formatter.call(value, fraction), x - 30, y, "FFFFFF")
    end

    def draw_external_label(start_deg, sweep_deg, value, fraction)
      mid_rad = (start_deg - (sweep_deg / 2.0)) * Math::PI / 180
      cos = Math.cos(mid_rad)
      sin = Math.sin(mid_rad)
      edge = [ center[0] + (radius * cos), center[1] + (radius * sin) ]
      leader_radius = radius + LEADER_LENGTH + (@external_label_count * LEADER_STAGGER_STEP)
      tip = [ center[0] + (leader_radius * cos), center[1] + (leader_radius * sin) ]
      @external_label_count += 1

      @pdf.stroke_color EXTERNAL_LABEL_LINE_COLOR
      @pdf.line_width 0.5
      @pdf.stroke_line edge, tip

      right_side = cos >= 0
      text_x = right_side ? tip[0] + 2 : tip[0] - 2 - EXTERNAL_LABEL_WIDTH
      draw_label_lines(@label_formatter.call(value, fraction), text_x, tip[1], EXTERNAL_LABEL_TEXT_COLOR,
        align: right_side ? :left : :right, width: EXTERNAL_LABEL_WIDTH)
    end

    def draw_label_lines(lines, x, y, color, align: :center, width: 60)
      @pdf.fill_color color
      @pdf.font("AsapCondensed", style: :bold, size: 8) do
        if lines.size > 1
          @pdf.text_box lines[0], at: [ x, y + 10 ], width: width, align: align
          @pdf.text_box lines[1], at: [ x, y - 2 ], width: width, align: align
        else
          @pdf.text_box lines[0], at: [ x, y + 4 ], width: width, align: align
        end
      end
    end

    def default_label(value, fraction)
      [ NumberFormatting.count(value), "(#{NumberFormatting.percent(fraction * 100)})" ]
    end

    def draw_legend
      x = @at[0] + ((@width - legend_width) / 2)
      y = @at[1] - circle_area_height - 2
      @labels.each_index do |index|
        draw_legend_item(x, y, @colors[index % @colors.length], @labels[index])
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
