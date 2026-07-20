class IntegrationFlcsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_integration_flc, only: %i[show edit update destroy confirm_destroy]
  before_action :set_zonings, only: %i[new create edit update]

  def index
    authorize IntegrationFlc
    @integration_flcs = policy_scope(IntegrationFlc).includes(:zoning).order(year: :desc, month: :desc)
  end

  def show
  end

  def new
    @integration_flc = IntegrationFlc.new
    authorize @integration_flc
  end

  def create
    @integration_flc = IntegrationFlc.new(integration_flc_params)
    authorize @integration_flc

    if @integration_flc.save
      redirect_to integration_flcs_path, notice: "Integrazione FLC creata con successo."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @integration_flc.update(integration_flc_params)
      redirect_to integration_flcs_path, notice: "Integrazione FLC aggiornata con successo."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @integration_flc.destroy
    redirect_to integration_flcs_path, notice: "Integrazione FLC eliminata con successo."
  end

  def confirm_destroy
  end

  private

  def set_integration_flc
    @integration_flc = IntegrationFlc.find(params[:id])
    authorize @integration_flc
  end

  def set_zonings
    @zonings = Zoning.order(:codice_azzonamento)
  end

  def integration_flc_params
    params.require(:integration_flc).permit(:zoning_id, :year, :month, :subscribers_af)
  end
end
