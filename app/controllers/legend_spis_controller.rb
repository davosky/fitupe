class LegendSpisController < ApplicationController
  before_action :authenticate_user!
  before_action :set_legend_spi, only: %i[show edit update destroy confirm_destroy]
  before_action :set_zonings, only: %i[new create edit update]

  def index
    authorize LegendSpi
    @legend_spis = policy_scope(LegendSpi).includes(:zoning).order(year: :desc, month: :desc)
  end

  def show
  end

  def new
    @legend_spi = LegendSpi.new
    authorize @legend_spi
  end

  def create
    @legend_spi = LegendSpi.new(legend_spi_params)
    authorize @legend_spi

    if @legend_spi.save
      redirect_to legend_spis_path, notice: "Legenda SPI creata con successo."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @legend_spi.update(legend_spi_params)
      redirect_to legend_spis_path, notice: "Legenda SPI aggiornata con successo."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @legend_spi.destroy
    redirect_to legend_spis_path, notice: "Legenda SPI eliminata con successo."
  end

  def confirm_destroy
  end

  private

  def set_legend_spi
    @legend_spi = LegendSpi.find(params[:id])
    authorize @legend_spi
  end

  def set_zonings
    @zonings = Zoning.order(:codice_azzonamento)
  end

  def legend_spi_params
    params.require(:legend_spi).permit(:zoning_id, :year, :month, :description)
  end
end
