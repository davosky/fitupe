class StatisticsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_zonings

  def index
    @total_members_form = TotalMembersForm.new(total_members_params)
    @total_members_result = compute_total_members_result
  end

  private

  def set_zonings
    @zonings = Zoning.order(:codice_azzonamento)
  end

  def total_members_params
    params.fetch(:total_members_form, {}).permit(:zoning_id, :anno, :mese)
  end

  def compute_total_members_result
    return nil unless @total_members_form.valid?

    Statistics::TotalMembersComparison.call(
      zoning: @total_members_form.zoning, anno: @total_members_form.anno, mese: @total_members_form.mese
    )
  end
end
