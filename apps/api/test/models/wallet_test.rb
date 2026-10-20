require "test_helper"

class WalletTest < ActiveSupport::TestCase
  def gift(**attributes)
    Wallet.new(kind: :gift, name: "Gift", funder: users(:parent), place: places(:tuckshop), currency: "USD",
      status: :pending, claim_token_digest: SecureRandom.hex, claim_expires_at: 3.days.from_now, **attributes)
  end

  test "lists wallets a user owns or funded" do
    assert_equal [ wallets(:tuckshop_gift) ], Wallet.visible_to(users(:friend)).to_a
    assert_includes Wallet.visible_to(users(:parent)), wallets(:pending_gift)
    assert_empty Wallet.visible_to(users(:stranger))
  end

  test "rejects a currency outside the allow-list" do
    assert_not gift(currency: "BTC").valid?
  end

  test "a goal cannot expire" do
    goal = wallets(:bike_goal)
    goal.expires_at = 1.day.from_now

    assert_not goal.valid?
  end

  test "builds its schedule from its time windows" do
    assert wallets(:tuckshop_gift).schedule.open_at?(Time.zone.parse("2026-10-21 08:45 UTC"))
    assert wallets(:bike_goal).schedule.open_at?(Time.zone.parse("2026-10-24 03:00 UTC"))
  end

  test "the database requires a goal to be owned by its funder" do
    assert_raises(ActiveRecord::StatementInvalid) { wallets(:bike_goal).update_column(:owner_id, users(:friend).id) }
  end

  test "the database requires a pending gift to have no owner" do
    assert_raises(ActiveRecord::StatementInvalid) { wallets(:pending_gift).update_column(:owner_id, users(:friend).id) }
  end

  test "the database stops a funder owning their own gift" do
    assert_raises(ActiveRecord::StatementInvalid) do
      wallets(:tuckshop_gift).update_columns(owner_id: users(:parent).id)
    end
  end

  test "the database keeps claim tokens unique" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      gift(claim_token_digest: wallets(:pending_gift).claim_token_digest).save!
    end
  end
end
