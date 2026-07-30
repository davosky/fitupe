class StatisticWithIntegrationsPrintsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_zonings

  def index
    @total_members_form = TotalMembersForm.new(total_members_params)

    respond_to do |format|
      format.html
      format.pdf { render_pdf }
    end
  end

  private

  def set_zonings
    @zonings = Zoning.order(:codice_azzonamento)
  end

  def total_members_params
    params.fetch(:total_members_form, {}).permit(:zoning_id, :anno, :mese)
  end

  def render_pdf
    unless @total_members_form.valid?
      return redirect_to statistic_with_integrations_prints_path, alert: "Compila azzonamento, anno e mese"
    end

    pdf = StatisticPrints::ReportPdf.call(form: @total_members_form,
      comparison_service: StatisticWithIntegrations::TotalMembersComparison)
    send_data pdf.render, filename: pdf_filename, type: "application/pdf", disposition: "inline"
  end

  def pdf_filename
    form = @total_members_form
    slug = "#{form.zoning.codice_azzonamento}-#{form.anno}-#{form.mese}".parameterize
    "statistiche-integrazioni-#{slug}.pdf"
  end
end
