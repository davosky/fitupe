module IntegrationFlcHelper
  def form_submit_label_integration_flc
    case action_name
    when "new", "create"  then "Crea Integrazione"
    when "edit", "update" then "Aggiorna Integrazione"
    else                       "Salva"
    end
  end
end
