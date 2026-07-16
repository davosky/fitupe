class User < ApplicationRecord
  GENDERS = %w[M F].freeze

  # Include default devise modules. Others available are:
  # :registerable, :recoverable, :confirmable, :timeoutable and :omniauthable
  devise :database_authenticatable, :rememberable, :trackable, :lockable

  validates :username, presence: true, uniqueness: { case_sensitive: false },
    length: { minimum: 3, maximum: 30 }, format: { with: /\A[a-zA-Z0-9_.]+\z/ }
  validates :password, presence: true, confirmation: true,
    length: { minimum: Devise.password_length.min, maximum: Devise.password_length.max },
    if: :password_required?

  scope :admins, -> { where(admin: true) }
  scope :managers, -> { where(manager: true) }
  scope :regulars, -> { where(regular: true) }

  def full_name
    [ first_name, last_name ].compact_blank.join(" ")
  end

  private

  def password_required?
    !persisted? || password.present? || password_confirmation.present?
  end
end
