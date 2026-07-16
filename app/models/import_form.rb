class ImportForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  MESI = %w[
    Gennaio Febbraio Marzo Aprile Maggio Giugno
    Luglio Agosto Settembre Ottobre Novembre Dicembre
  ].freeze

  UPLOADS_DIR = Rails.root.join("tmp/imports")

  # `file` holds the freshly uploaded CSV (only present on the first submit).
  # `stored_path` carries forward the already-persisted upload across the
  # keep/overwrite confirmation step, where the file input can't be resubmitted.
  attribute :file
  attribute :stored_path, :string
  attribute :zoning_id, :integer
  attribute :anno, :string
  attribute :mese, :string
  attribute :resolution, :string

  validates :zoning_id, :anno, :mese, presence: true
  validates :anno, format: { with: /\A\d{4}\z/, message: "deve essere un anno a 4 cifre" }, allow_blank: true
  validates :mese, inclusion: { in: MESI }, allow_blank: true
  validates :resolution, inclusion: { in: %w[keep overwrite] }, allow_blank: true
  validate :file_must_be_present_and_csv

  def zoning
    @zoning ||= Zoning.find_by(id: zoning_id)
  end

  # Path to a CSV file on disk ready for the importer: the already-persisted
  # upload if we're past the conflict step, otherwise persists it now.
  def resolved_path
    stored_path.presence || persist_upload!
  end

  private

  def file_must_be_present_and_csv
    return if stored_path.present?

    if file.blank?
      errors.add(:file, "deve essere selezionato")
    elsif File.extname(file.original_filename.to_s).downcase != ".csv"
      errors.add(:file, "deve essere un file .csv")
    end
  end

  def persist_upload!
    return nil if file.blank?

    FileUtils.mkdir_p(UPLOADS_DIR)
    target = UPLOADS_DIR.join("#{SecureRandom.uuid}.csv")
    File.binwrite(target, file.read)
    self.stored_path = target.to_s
  end
end
