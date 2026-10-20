# Append-only: once saved an entry is read-only here, and a database trigger
# refuses UPDATE and DELETE. Corrections are new entries.
class LedgerEntry < ApplicationRecord
  enum :kind, { deposit: "deposit", spend: "spend", refund: "refund" }, validate: true

  belongs_to :wallet
  belongs_to :unlock, optional: true

  validates :amount_cents, numericality: { only_integer: true, other_than: 0 }
  validates :idempotency_key, presence: true

  scope :newest_first, -> { order(id: :desc) }

  def readonly?
    persisted? || super
  end
end
