class Wallet < ApplicationRecord
  enum :kind, { goal: "goal", gift: "gift" }, validate: true
  enum :status, { pending: "pending", active: "active", cancelled: "cancelled", expired: "expired" }, validate: true

  belongs_to :owner, class_name: "User", optional: true
  belongs_to :funder, class_name: "User"
  belongs_to :place
  has_many :time_windows, dependent: :destroy
  has_many :ledger_entries, dependent: :restrict_with_exception
  has_many :presence_sessions, dependent: :restrict_with_exception
  has_many :unlocks, dependent: :restrict_with_exception

  accepts_nested_attributes_for :time_windows

  validates :name, presence: true, length: { maximum: 100 }
  validates :currency, inclusion: { in: ->(_) { Money.currencies } }
  validates :target_cents, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :expires_at, absence: true, if: :goal?

  scope :visible_to, ->(user) { where(owner: user).or(where(funder: user)) }
  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
  scope :unclaimed_past, ->(time) { pending.where(claim_expires_at: ..time) }
  scope :gift_expired_by, ->(time) { gift.active.where(expires_at: ..time) }

  def schedule
    Schedule.new(time_windows.map(&:weekly_window))
  end
end
