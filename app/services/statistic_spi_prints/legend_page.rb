module StatisticSpiPrints
  # Come StatisticPrints::LegendPage, ma con la legenda SPI del periodo.
  class LegendPage < StatisticPrints::LegendPage
    private

    def description = @form.legend_spi.description
  end
end
