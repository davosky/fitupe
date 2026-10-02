# `StatisticSpiPrints::ZoningDividerPage`

**File:** `app/services/statistic_spi_prints/zoning_divider_page.rb`

## Codice completo

```ruby
module StatisticSpiPrints
  # Come StatisticPrints::ZoningDividerPage ma con il logo CGIL+SPI e
  # l'etichetta "Sindacato Pensionati Italiani" al posto della dicitura
  # confederale generica.
  class ZoningDividerPage < StatisticPrints::ZoningDividerPage
    LOGO = IMAGES_DIR.join("logo-cgil-spi.png")
    FOOTER_LABEL = "Sindacato Pensionati Italiani".freeze
  end
end
```

## Sezioni commentate

### Sottoclasse della versione Attivi

```ruby
module StatisticSpiPrints
  # Come StatisticPrints::ZoningDividerPage ma con il logo CGIL+SPI e
  # l'etichetta "Sindacato Pensionati Italiani" al posto della dicitura
  # confederale generica.
  class ZoningDividerPage < StatisticPrints::ZoningDividerPage
    LOGO = IMAGES_DIR.join("logo-cgil-spi.png")
    FOOTER_LABEL = "Sindacato Pensionati Italiani".freeze
  end
end
```

> **IT:** Fino al 2026-10-02 questa classe era una copia identica di `StatisticPrints::ZoningDividerPage` (79 righe), con due sole differenze: il logo CGIL+SPI e la dicitura "Sindacato Pensionati Italiani". La precedente versione di questa scheda già la indicava come candidata a diventare una classe con logo ed etichetta come parametri; l'audit di fine sessione l'ha resa una sottoclasse che ridefinisce solo le costanti `LOGO` e `FOOTER_LABEL`. La classe base le legge con `self.class::` proprio per permetterlo (vedi `CodeGuide/StatisticPrints/zoning_divider_page.md`): layout, geometria, reset di `fill_color` e firma di `initialize` (`zoning:`, `mese:`, `anno:` separati, per il ciclo sui comprensori di `ReportPdf`) sono documentati lì. Uno spec controlla che a runtime vengano davvero disegnati il logo e la dicitura SPI.
>
> *EN: Until 2026-10-02 this class was an identical copy of `StatisticPrints::ZoningDividerPage` (79 lines), differing only in the CGIL+SPI logo and the "Sindacato Pensionati Italiani" label. The previous version of this page already flagged it as a candidate for a class parameterized on logo and label; the end-of-session audit turned it into a subclass redefining only the `LOGO` and `FOOTER_LABEL` constants. The base class reads them via `self.class::` precisely to allow this (see `CodeGuide/StatisticPrints/zoning_divider_page.md`): layout, geometry, the `fill_color` reset and the `initialize` signature (separate `zoning:`, `mese:`, `anno:`, for `ReportPdf`'s comprensorio loop) are documented there. A spec checks that the SPI logo and label are actually drawn at runtime.*
