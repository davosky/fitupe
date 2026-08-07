module StatisticSpiPrints
  class LegendPage
    LIST_INDENT_MM = 5

    def self.draw(...) = new(...).draw

    def initialize(pdf, form:)
      @pdf = pdf
      @form = form
    end

    def draw
      @pdf.fill_color "000000"
      draw_heading
      draw_body
    end

    private

    def draw_heading
      @pdf.font("AsapCondensed", style: :bold, size: 16) { @pdf.text "Legenda" }
      @pdf.move_down 2
      @pdf.font("AsapCondensed", size: 10) { @pdf.text "Tesseramento #{@form.mese} #{@form.anno}", color: "666666" }
      @pdf.move_down 8
      @pdf.stroke_color "CCCCCC"
      @pdf.stroke_horizontal_rule
      @pdf.move_down 10
    end

    def draw_body
      @pdf.font("AsapCondensed", size: 11) do
        StatisticPrints::LegendContent.blocks(@form.legend_spi.description).each { |block| draw_block(block) }
      end
    end

    def draw_block(block)
      case block[:type]
      when :heading then draw_text(block[:text], size: 14, style: :bold)
      when :list_item then draw_list_item(block)
      when :quote then draw_quote(block)
      when :rule then draw_rule
      else draw_text(block[:text], align: block[:align] || :left)
      end
      @pdf.move_down 6
    end

    def draw_list_item(block)
      @pdf.indent(list_indent) { draw_text("#{block[:prefix]}  #{block[:text]}", align: block[:align] || :left) }
    end

    def draw_quote(block)
      @pdf.indent(list_indent) { draw_text(block[:text], style: :italic, color: "666666") }
    end

    def draw_rule
      @pdf.stroke_color "CCCCCC"
      @pdf.stroke_horizontal_rule
    end

    def draw_text(text, size: 11, style: :normal, color: "000000", align: :left)
      return if text.blank?

      @pdf.font("AsapCondensed", size: size, style: style) { @pdf.text text, inline_format: true, color: color, align: align }
    end

    def list_indent = LIST_INDENT_MM * 72 / 25.4
  end
end
