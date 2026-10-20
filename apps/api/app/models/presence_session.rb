class PresenceSession < ApplicationRecord
  belongs_to :wallet
  belongs_to :user
  has_one :unlock, dependent: :restrict_with_exception

  scope :open, -> { where(ended_at: nil) }
end
