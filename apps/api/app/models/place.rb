class Place < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  has_many :wallets, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 120 }
  validates :location, presence: true
  validates :radius_m, numericality: { only_integer: true, in: 10..1000 }
  validates :dwell_seconds, numericality: { only_integer: true, in: 10..3600 }

  def latitude = location&.y
  def longitude = location&.x
end
