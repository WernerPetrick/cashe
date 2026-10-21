require "test_helper"

class Wallets::CreateTest < ActiveSupport::TestCase
  setup { @clock = FixedClock.new(Time.utc(2026, 10, 21, 8, 0)) }

  def create(**attributes)
    defaults = { kind: "gift", name: "Recess money", place_id: places(:tuckshop).id, currency: "USD" }
    Wallets::Create.new(clock: @clock).call(funder: users(:parent), attributes: defaults.merge(attributes))
  end

  test "creates a pending gift with a one-time claim link" do
    created = create.value

    assert_predicate created.wallet, :pending?
    assert_nil created.wallet.owner
    assert_equal ClaimToken.digest(created.claim_token.value), created.wallet.claim_token_digest
    assert_equal @clock.current + 3.days, created.wallet.claim_expires_at
    assert_match %r{\Acashe://claim/[\w-]{40,}\z}, created.claim_token.url
  end

  test "creates a goal owned by its funder, with no claim link" do
    created = create(kind: "goal", place_id: places(:mikes_bikes).id, target_cents: 450_000).value

    assert_predicate created.wallet, :active?
    assert_equal users(:parent), created.wallet.owner
    assert_nil created.claim_token
  end

  test "saves time windows with the wallet" do
    windows = [ { days_of_week: [ 1, 2, 3, 4, 5 ], starts_at: "10:30", ends_at: "11:00", time_zone: "Africa/Johannesburg" } ]
    wallet = create(time_windows_attributes: windows).value.wallet

    assert_equal 1, wallet.time_windows.count
  end

  test "rejects an expiry in the past" do
    result = create(expires_at: @clock.current - 60)

    assert_equal :validation_failed, result.error
    assert_includes result.details, "Expires at must be in the future"
  end

  test "reports validation errors" do
    result = create(name: "", currency: "BTC")

    assert_equal :validation_failed, result.error
    assert_includes result.details, "Name can't be blank"
  end
end
