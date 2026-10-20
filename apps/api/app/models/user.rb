class User < ApplicationRecord
  enum :role, { adult: "adult", child: "child" }, validate: true

  # Uniqueness is enforced by the unique index so create_or_find_by! stays race-safe.
  validates :appwrite_user_id, presence: true
  validates :display_name, presence: true, length: { maximum: 100 }
end
