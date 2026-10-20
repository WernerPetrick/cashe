class User < ApplicationRecord
  enum :role, { adult: "adult", child: "child" }, validate: true

  has_many :owned_wallets, class_name: "Wallet", foreign_key: :owner_id, inverse_of: :owner,
    dependent: :restrict_with_exception
  has_many :funded_wallets, class_name: "Wallet", foreign_key: :funder_id, inverse_of: :funder,
    dependent: :restrict_with_exception

  # Uniqueness is enforced by the unique index so create_or_find_by! stays race-safe.
  validates :appwrite_user_id, presence: true
  validates :display_name, presence: true, length: { maximum: 100 }
end
