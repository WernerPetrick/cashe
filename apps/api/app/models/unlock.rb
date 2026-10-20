class Unlock < ApplicationRecord
  belongs_to :wallet
  belongs_to :presence_session
  has_many :ledger_entries, dependent: :restrict_with_exception

  scope :active_at, ->(time) { where("unlocked_until > ?", time) }
end
