class TotalMembersForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :zoning_id, :integer
  attribute :anno, :string
  attribute :mese, :string

  validates :zoning_id, :anno, :mese, presence: true
  validates :anno, format: { with: /\A\d{4}\z/, message: "deve essere un anno a 4 cifre" }, allow_blank: true
  validates :mese, inclusion: { in: ImportForm::MESI }, allow_blank: true

  def zoning
    @zoning ||= Zoning.find_by(id: zoning_id)
  end

  def legend
    @legend ||= Legend.find_by(zoning_id: zoning_id, year: anno, month: mese)
  end

  def legend_spi
    @legend_spi ||= LegendSpi.find_by(zoning_id: zoning_id, year: anno, month: mese)
  end
end
