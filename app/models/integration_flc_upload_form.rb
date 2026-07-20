class IntegrationFlcUploadForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :file
  attribute :zoning_id, :integer
  attribute :year, :string
  attribute :month, :string

  validates :zoning_id, :year, :month, presence: true
  validates :year, format: { with: /\A\d{4}\z/, message: "deve essere un anno a 4 cifre" }, allow_blank: true
  validates :month, inclusion: { in: ImportForm::MESI }, allow_blank: true
  validate :file_must_be_present_and_csv

  def zoning
    @zoning ||= Zoning.find_by(id: zoning_id)
  end

  private

  def file_must_be_present_and_csv
    if file.blank?
      errors.add(:file, "deve essere selezionato")
    elsif File.extname(file.original_filename.to_s).downcase != ".csv"
      errors.add(:file, "deve essere un file .csv")
    end
  end
end
