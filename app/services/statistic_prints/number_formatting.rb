module StatisticPrints
  module NumberFormatting
    extend ActionView::Helpers::NumberHelper

    def self.count(value) = number_with_delimiter(value, locale: :it)

    def self.percent(value)
      return nil if value.nil?

      number_to_percentage(value, precision: 2, locale: :it)
    end
  end
end
