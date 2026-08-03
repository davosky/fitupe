class ImportSpisController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_import_spi
  before_action :set_zonings, only: %i[new create]

  def index
    counts = ImportSpi.group(:azzonamento_di_riferimento_id, :anno_di_riferimento, :mese_di_riferimento).count
    zonings = Zoning.where(id: counts.keys.map(&:first)).index_by(&:id)
    @batches = counts.map { |(zoning_id, anno, mese), count| { zoning: zonings[zoning_id], anno:, mese:, count: } }
      .sort_by { |b| [ b[:zoning].descrizione_azzonamento, -b[:anno].to_i, -ImportSpiForm::MESI.index(b[:mese]) ] }
  end

  def new
    @import_spi_form = ImportSpiForm.new
  end

  def create
    @import_spi_form = ImportSpiForm.new(import_spi_params)
    return render_form_errors unless @import_spi_form.valid?
    return render_conflict if conflict? && @import_spi_form.resolution.blank?
    return cancel_import if @import_spi_form.resolution == "keep"

    redirect_to import_spi_path(enqueue_import)
  end

  def show
    @token = params[:id]
    @progress = Rails.cache.read("import_spi_progress_#{@token}") || { percent: 0 }
  end

  private

  def set_zonings
    @zonings = Zoning.order(:codice_azzonamento)
  end

  def authorize_import_spi
    authorize ImportSpi, :manage?
  end

  def import_spi_params
    params.fetch(:import_spi_form, {}).permit(:file, :stored_path, :zoning_id, :anno, :mese, :resolution)
  end

  def conflict?
    ImportSpi.where(azzonamento_di_riferimento_id: @import_spi_form.zoning_id, anno_di_riferimento: @import_spi_form.anno,
      mese_di_riferimento: @import_spi_form.mese).exists?
  end

  def render_form_errors
    render :new, status: :unprocessable_entity
  end

  def render_conflict
    @conflict = true
    @import_spi_form.resolved_path # persists the upload so it survives the confirmation round-trip
    render :new, status: :unprocessable_entity
  end

  def cancel_import
    path = @import_spi_form.stored_path
    File.delete(path) if path.present? && File.exist?(path)
    redirect_to new_import_spi_path, notice: "Importazione annullata: i dati esistenti sono stati mantenuti."
  end

  def enqueue_import
    token = SecureRandom.uuid
    ImportSpiCsvJob.perform_later(
      path: @import_spi_form.resolved_path, zoning_id: @import_spi_form.zoning_id, anno: @import_spi_form.anno,
      mese: @import_spi_form.mese, overwrite: @import_spi_form.resolution == "overwrite", token: token
    )
    token
  end
end
