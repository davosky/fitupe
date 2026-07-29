class LegendsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_legend, only: %i[show edit update destroy confirm_destroy]
  before_action :set_zonings, only: %i[new create edit update]

  def index
    authorize Legend
    @legends = policy_scope(Legend).includes(:zoning).order(year: :desc, month: :desc)
  end

  def show
  end

  def new
    @legend = Legend.new
    authorize @legend
  end

  def create
    @legend = Legend.new(legend_params)
    authorize @legend

    if @legend.save
      redirect_to legends_path, notice: "Legenda creata con successo."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @legend.update(legend_params)
      redirect_to legends_path, notice: "Legenda aggiornata con successo."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @legend.destroy
    redirect_to legends_path, notice: "Legenda eliminata con successo."
  end

  def confirm_destroy
  end

  private

  def set_legend
    @legend = Legend.find(params[:id])
    authorize @legend
  end

  def set_zonings
    @zonings = Zoning.order(:codice_azzonamento)
  end

  def legend_params
    params.require(:legend).permit(:zoning_id, :year, :month, :description)
  end
end
