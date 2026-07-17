module ZoningHelper
  def form_label_class_zoning
    case action_name
    when "new", "create"  then "form-label text-success"
    when "edit", "update" then "form-label text-warning"
    else                       "form-label"
    end
  end

  def form_input_group_class_zoning
    case action_name
    when "new", "create"  then "input-group-text input-group-text-fixed bg-success text-white"
    when "edit", "update" then "input-group-text input-group-text-fixed bg-warning text-white"
    else                       "input-group-text input-group-text-fixed bg-primary text-white"
    end
  end

  def form_button_class_zoning
    case action_name
    when "new", "create"  then "btn btn-success shadow"
    when "edit", "update" then "btn btn-warning shadow"
    else                       "btn btn-primary shadow"
    end
  end

  def form_submit_label_zoning
    case action_name
    when "new", "create"  then "Crea Azzonamento"
    when "edit", "update" then "Aggiorna Azzonamento"
    else                       "Salva"
    end
  end
end
