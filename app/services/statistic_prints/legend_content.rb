module StatisticPrints
  module LegendContent
    module_function

    def blocks(rich_text)
      fragment = Nokogiri::HTML::DocumentFragment.parse(rich_text.body.to_html)
      fragment.children.flat_map { |node| blocks_for(node) }
    end

    def blocks_for(node)
      case node.name
      when "div" then [ { type: :paragraph, text: inline(node) } ]
      when "p" then [ { type: :paragraph, text: inline(node), align: :justify } ]
      when "h1" then [ { type: :heading, text: inline(node) } ]
      when "ul", "ol" then list_blocks(node)
      when "blockquote" then [ { type: :quote, text: inline(node) } ]
      when "action-text-attachment" then attachment_blocks(node)
      when "text" then text_block(node)
      else []
      end
    end

    def attachment_blocks(node)
      node["content"].to_s.match?(%r{\A\s*<hr\s*/?>\s*\z}i) ? [ { type: :rule } ] : []
    end

    def list_blocks(node)
      ordered = node.name == "ol"
      node.css("> li").each_with_index.map { |li, i| list_item_block(li, ordered, i) }
    end

    def list_item_block(li, ordered, index)
      block = { type: :list_item, text: inline(li), prefix: ordered ? "#{index + 1}." : "•" }
      block[:align] = :justify if li.at_css("> p")
      block
    end

    def text_block(node)
      text = node.text.strip
      text.present? ? [ { type: :paragraph, text: CGI.escapeHTML(text) } ] : []
    end

    def inline(node)
      node.children.map { |child| inline_node(child) }.join
    end

    def inline_node(node)
      case node.name
      when "text" then CGI.escapeHTML(node.text)
      when "strong", "b" then "<b>#{inline(node)}</b>"
      when "em", "i" then "<i>#{inline(node)}</i>"
      when "u" then "<u>#{inline(node)}</u>"
      when "a" then link_node(node)
      when "br" then "\n"
      else inline(node)
      end
    end

    def link_node(node)
      href = CGI.escapeHTML(node["href"].to_s)
      "<color rgb=\"0d6efd\"><link href=\"#{href}\">#{inline(node)}</link></color>"
    end
  end
end
