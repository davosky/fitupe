class IntegrationFilleasController < ApplicationController
  before_action :authenticate_user!
  before_action :set_integration_fillea, only: %i[show edit update destroy confirm_destroy]
  before_action :set_zonings, only: %i[new create edit update]

  def index
    authorize IntegrationFillea
    @integration_filleas = policy_scope(IntegrationFillea).includes(:zoning).order(year: :desc)
  end

  def show
  end

  def new
    @integration_fillea = IntegrationFillea.new
    authorize @integration_fillea
  end

  def create
    @integration_fillea = IntegrationFillea.new(integration_fillea_params)
    authorize @integration_fillea

    if @integration_fillea.save
      redirect_to integration_filleas_path, notice: "Integrazione FILLEA creata con successo."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @integration_fillea.update(integration_fillea_params)
      redirect_to integration_filleas_path, notice: "Integrazione FILLEA aggiornata con successo."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @integration_fillea.destroy
    redirect_to integration_filleas_path, notice: "Integrazione FILLEA eliminata con successo."
  end

  def confirm_destroy
  end

  private

  def set_integration_fillea
    @integration_fillea = IntegrationFillea.find(params[:id])
    authorize @integration_fillea
  end

  def set_zonings
    @zonings = Zoning.order(:codice_azzonamento)
  end

  def integration_fillea_params
    params.require(:integration_fillea).permit(:zoning_id, :year, :subscribers_ce)
  end
end
