class StatisticsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_zonings

  def index
    @total_members_form = TotalMembersForm.new(total_members_params)
    @total_members_result = compute_total_members_result
  end

  def progression
    @progression_form = AnnualProgressionForm.new(progression_params)
    @progression_result = compute_progression_result
  end

  private

  def set_zonings
    @zonings = Zoning.order(:codice_azzonamento)
  end

  def total_members_params
    params.fetch(:total_members_form, {}).permit(:zoning_id, :anno, :mese)
  end

  def progression_params
    params.fetch(:annual_progression_form, {}).permit(:zoning_id, :anno)
  end

  def compute_progression_result
    return nil unless @progression_form.valid?

    Statistics::AnnualProgression.call(zoning: @progression_form.zoning, anno: @progression_form.anno)
  end

  def compute_total_members_result
    return nil unless @total_members_form.valid?

    Statistics::TotalMembersComparison.call(
      zoning: @total_members_form.zoning, anno: @total_members_form.anno, mese: @total_members_form.mese
    )
  end
end
