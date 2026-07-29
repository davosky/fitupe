module LegendHelper
  def form_submit_label_legend
    case action_name
    when "new", "create"  then "Crea Legenda"
    when "edit", "update" then "Aggiorna Legenda"
    else                       "Salva"
    end
  end
end
