module StatisticSpiPrints
  # Come StatisticPrints::ZoningDividerPage ma con il logo CGIL+SPI e
  # l'etichetta "Sindacato Pensionati Italiani" al posto della dicitura
  # confederale generica.
  class ZoningDividerPage < StatisticPrints::ZoningDividerPage
    LOGO = IMAGES_DIR.join("logo-cgil-spi.png")
    FOOTER_LABEL = "Sindacato Pensionati Italiani".freeze
  end
end
