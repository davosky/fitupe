class ZoningsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_zoning, only: %i[show edit update destroy confirm_destroy]

  def index
    authorize Zoning
    @zonings = policy_scope(Zoning).order(:codice_azzonamento)
  end

  def show
  end

  def new
    @zoning = Zoning.new
    authorize @zoning
  end

  def create
    @zoning = Zoning.new(zoning_params)
    authorize @zoning

    if @zoning.save
      redirect_to zonings_path, notice: "Azzonamento creato con successo."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @zoning.update(zoning_params)
      redirect_to zonings_path, notice: "Azzonamento aggiornato con successo."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @zoning.destroy
    redirect_to zonings_path, notice: "Azzonamento eliminato con successo."
  end

  def confirm_destroy
  end

  private

  def set_zoning
    @zoning = Zoning.find(params[:id])
    authorize @zoning
  end

  def zoning_params
    params.require(:zoning).permit(:codice_azzonamento, :descrizione_azzonamento)
  end
end
