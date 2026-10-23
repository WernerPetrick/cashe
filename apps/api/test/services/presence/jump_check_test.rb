require "test_helper"

class Presence::JumpCheckTest < ActiveSupport::TestCase
  INSIDE = Coordinates.new(latitude: -33.9249, longitude: 18.4241)   # tuckshop centre
  NEARBY = Coordinates.new(latitude: -33.9231, longitude: 18.4241)   # ~200 m north
  FAR = Coordinates.new(latitude: -33.8799, longitude: 18.4241)      # ~5 km north

  setup do
    @cache = ActiveSupport::Cache::MemoryStore.new
    @clock = FixedClock.new(Time.utc(2026, 10, 21, 8, 40))
  end

  def jumped?(at, accuracy_m: 8, user: users(:friend))
    ping = PresencePing.new(coordinates: at, accuracy_m: accuracy_m, mocked: false)
    Presence::JumpCheck.new(cache: @cache).jumped?(wallet: wallets(:tuckshop_gift), user: user, ping: ping, now: @clock.current)
  end

  test "the first ping has nothing to compare with" do
    assert_not jumped?(FAR)
  end

  test "walking in from nearby is fine" do
    jumped?(NEARBY)
    @clock.advance(12)

    assert_not jumped?(INSIDE)
  end

  test "arriving from 5 km away in 12 seconds is a jump" do
    jumped?(FAR)
    @clock.advance(12)

    assert jumped?(INSIDE)
  end

  test "leaving that fast is a jump too" do
    jumped?(INSIDE)
    @clock.advance(12)

    assert jumped?(FAR)
  end

  test "allows for both pings' accuracy" do
    jumped?(NEARBY, accuracy_m: 50)
    @clock.advance(2)
    assert_not jumped?(INSIDE, accuracy_m: 50), "200 m in 2 s is within 140 m + 100 m of slack"

    jumped?(NEARBY)
    @clock.advance(2)
    assert jumped?(INSIDE), "200 m in 2 s is beyond 140 m + 16 m of slack"
  end

  test "a ping after a gap isn't compared" do
    jumped?(FAR)
    @clock.advance(46)

    assert_not jumped?(INSIDE)
  end

  test "keeps each person's last ping apart" do
    jumped?(FAR, user: users(:parent))
    @clock.advance(12)

    assert_not jumped?(INSIDE)
  end

  test "keeps only a distance, never coordinates" do
    jumped?(NEARBY)

    entry = @cache.read("presence/last_fix/#{wallets(:tuckshop_gift).id}/#{users(:friend).id}")
    assert_equal %i[accuracy_m at distance_m], entry.keys.sort
    assert_no_match(/33\.92|18\.42/, entry.inspect)
  end
end
