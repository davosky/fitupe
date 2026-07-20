class IntegrationFlcUploadsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_upload
  before_action :set_zonings, only: %i[new create]

  def new
    @integration_flc_upload_form = IntegrationFlcUploadForm.new
  end

  def create
    @integration_flc_upload_form = IntegrationFlcUploadForm.new(upload_params)
    return render_form_errors unless @integration_flc_upload_form.valid?

    result = IntegrationFlcs::ComparisonService.call(
      file: @integration_flc_upload_form.file,
      zoning_id: @integration_flc_upload_form.zoning_id,
      year: @integration_flc_upload_form.year,
      month: @integration_flc_upload_form.month
    )

    if result.success?
      redirect_to integration_flc_path(result.integration_flc),
        notice: "Confronto completato: #{result.integration_flc.subscribers_af} codici fiscali mancanti in SinCGIL."
    else
      @integration_flc_upload_form.errors.add(:base, result.error)
      render_form_errors
    end
  end

  private

  def set_zonings
    @zonings = Zoning.order(:codice_azzonamento)
  end

  def authorize_upload
    authorize IntegrationFlc, :create?
  end

  def upload_params
    params.fetch(:integration_flc_upload_form, {}).permit(:file, :zoning_id, :year, :month)
  end

  def render_form_errors
    render :new, status: :unprocessable_entity
  end
end
