module ZoningHelper
  def form_submit_label_zoning
    case action_name
    when "new", "create"  then "Crea Azzonamento"
    when "edit", "update" then "Aggiorna Azzonamento"
    else                       "Salva"
    end
  end
end
