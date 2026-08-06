module LegendSpiHelper
  def form_submit_label_legend_spi
    case action_name
    when "new", "create"  then "Crea Legenda SPI"
    when "edit", "update" then "Aggiorna Legenda SPI"
    else                       "Salva"
    end
  end
end
