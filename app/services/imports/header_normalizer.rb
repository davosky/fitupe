module Imports
  class HeaderNormalizer
    def self.call(header)
      I18n.transliterate(header.to_s).downcase
        .gsub(/[^a-z0-9]+/, "_")
        .gsub(/\A_+|_+\z/, "")
    end
  end
end
