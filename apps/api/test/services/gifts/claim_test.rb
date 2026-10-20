require "test_helper"

class Gifts::ClaimTest < ActiveSupport::TestCase
  setup { @clock = FixedClock.new(Time.utc(2026, 10, 21, 8, 0)) }

  def claim(user, token = "pending-gift-token")
    Gifts::Claim.new(clock: @clock).call(user: user, token: token)
  end

  test "makes the claimer the owner and activates the gift" do
    result = claim(users(:friend))
    wallet = result.value

    assert_predicate result, :success?
    assert_equal users(:friend), wallet.owner
    assert_predicate wallet, :active?
    assert_equal @clock.current, wallet.claimed_at
  end

  test "works only once" do
    claim(users(:friend))

    assert_equal :invalid_claim, claim(users(:stranger)).error
    assert_equal users(:friend), wallets(:pending_gift).reload.owner
  end

  test "rejects an unknown token without saying more" do
    assert_equal :invalid_claim, claim(users(:friend), "guess").error
  end

  test "rejects a claim after the claim window" do
    @clock.advance(3.days)

    assert_equal :invalid_claim, claim(users(:friend)).error
  end

  test "stops a funder claiming their own gift" do
    assert_equal :own_gift, claim(users(:parent)).error
    assert_predicate wallets(:pending_gift).reload, :pending?
  end
end
