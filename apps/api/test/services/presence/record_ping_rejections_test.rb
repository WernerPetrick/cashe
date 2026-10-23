require "test_helper"

# The unlock engine's answers to pings it can't trust: spoofed, jumping or inaccurate.
class Presence::RecordPingRejectionsTest < ActiveSupport::TestCase
  INSIDE = Coordinates.new(latitude: -33.9249, longitude: 18.4241)   # tuckshop centre
  FAR = Coordinates.new(latitude: -33.8799, longitude: 18.4241)      # ~5 km north

  setup do
    @clock = FixedClock.new(Time.utc(2026, 10, 21, 8, 40)) # Wednesday 10:40 SAST, inside recess
    @wallet = wallets(:tuckshop_gift)
    @jumps = Presence::JumpCheck.new(cache: ActiveSupport::Cache::MemoryStore.new)
  end

  def ping(at: INSIDE, accuracy_m: 8, mocked: false)
    ping = PresencePing.new(coordinates: at, accuracy_m: accuracy_m, mocked: mocked)
    Presence::RecordPing.new(clock: @clock, jumps: @jumps).call(wallet: @wallet, user: users(:friend), ping: ping).value
  end

  def ping_every(seconds, times)
    times.times.map { @clock.advance(seconds) && ping }.last
  end

  test "rejects a mock location and ends the session" do
    ping
    @clock.advance(10)
    outcome = ping(mocked: true)

    assert_equal :rejected, outcome.status
    assert_equal :mock_location, outcome.reason
    assert_empty @wallet.presence_sessions.open
  end

  test "rejects an impossible jump and ends the session" do
    ping(at: FAR)
    @clock.advance(12) && ping
    @clock.advance(12)
    outcome = ping(at: FAR)

    assert_equal :rejected, outcome.status
    assert_equal :impossible_jump, outcome.reason
    assert_empty @wallet.presence_sessions.open
  end

  test "a jump into the zone doesn't start dwelling" do
    ping(at: FAR)
    @clock.advance(12)

    assert_equal :impossible_jump, ping.reason
    assert_empty @wallet.presence_sessions
  end

  test "a spoofed ping ends an open unlock" do
    ping
    ping_every(10, 3)
    @clock.advance(10)
    ping(mocked: true)

    assert_empty @wallet.unlocks.active_at(@clock.current)
    assert_equal :dwelling, ping_every(10, 1).status
  end

  test "rejects a poor-accuracy ping without counting it" do
    ping
    @clock.advance(10)
    outcome = ping(accuracy_m: 51)

    assert_equal :rejected, outcome.status
    assert_equal :low_accuracy, outcome.reason
    assert_equal @clock.current - 10, @wallet.presence_sessions.open.sole.last_ping_at
  end
end
