class ImportsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_import
  before_action :set_zonings, only: %i[new create]

  def index
    counts = Import.group(:azzonamento_di_riferimento_id, :anno_di_riferimento, :mese_di_riferimento).count
    zonings = Zoning.where(id: counts.keys.map(&:first)).index_by(&:id)
    @batches = counts.map { |(zoning_id, anno, mese), count| { zoning: zonings[zoning_id], anno:, mese:, count: } }
      .sort_by { |b| [ b[:zoning].descrizione_azzonamento, -b[:anno].to_i, -ImportForm::MESI.index(b[:mese]) ] }
  end

  def new
    @import_form = ImportForm.new
  end

  def create
    @import_form = ImportForm.new(import_params)
    return render_form_errors unless @import_form.valid?
    return render_conflict if conflict? && @import_form.resolution.blank?
    return cancel_import if @import_form.resolution == "keep"

    redirect_to import_path(enqueue_import)
  end

  def show
    @token = params[:id]
    @progress = Rails.cache.read("import_progress_#{@token}") || { percent: 0 }
  end

  private

  def set_zonings
    @zonings = Zoning.order(:codice_azzonamento)
  end

  def authorize_import
    authorize Import, :manage?
  end

  def import_params
    params.fetch(:import_form, {}).permit(:file, :stored_path, :zoning_id, :anno, :mese, :resolution)
  end

  def conflict?
    Import.where(azzonamento_di_riferimento_id: @import_form.zoning_id, anno_di_riferimento: @import_form.anno,
      mese_di_riferimento: @import_form.mese).exists?
  end

  def render_form_errors
    render :new, status: :unprocessable_entity
  end

  def render_conflict
    @conflict = true
    @import_form.resolved_path # persists the upload so it survives the confirmation round-trip
    render :new, status: :unprocessable_entity
  end

  def cancel_import
    path = @import_form.stored_path
    File.delete(path) if path.present? && File.exist?(path)
    redirect_to new_import_path, notice: "Importazione annullata: i dati esistenti sono stati mantenuti."
  end

  def enqueue_import
    token = SecureRandom.uuid
    ImportCsvJob.perform_later(
      path: @import_form.resolved_path, zoning_id: @import_form.zoning_id, anno: @import_form.anno,
      mese: @import_form.mese, overwrite: @import_form.resolution == "overwrite", token: token
    )
    token
  end
end
