class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = "Non sei autorizzato a compiere questa azione."
    redirect_back fallback_location: root_path
  end
end
