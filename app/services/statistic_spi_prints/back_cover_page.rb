module StatisticSpiPrints
  class BackCoverPage
    BACKGROUND_IMAGE = Rails.root.join("app/assets/images/statistic_prints/backcover_background_spi.png")

    def self.draw(pdf)
      pdf.image BACKGROUND_IMAGE.to_s, at: [ 0, pdf.bounds.top ], width: pdf.bounds.width, height: pdf.bounds.height
    end
  end
end
