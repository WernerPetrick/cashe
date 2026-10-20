require "test_helper"

class Presence::RecordPingTest < ActiveSupport::TestCase
  INSIDE = Coordinates.new(latitude: -33.9249, longitude: 18.4241)    # tuckshop centre
  OUTSIDE = Coordinates.new(latitude: -33.9231, longitude: 18.4241)   # ~200 m north

  setup do
    @clock = FixedClock.new(Time.utc(2026, 10, 21, 8, 40)) # Wednesday 10:40 SAST, inside recess
    @wallet = wallets(:tuckshop_gift)
  end

  def ping(at: INSIDE, accuracy_m: 8, mocked: false, wallet: @wallet)
    ping = PresencePing.new(coordinates: at, accuracy_m: accuracy_m, mocked: mocked)
    Presence::RecordPing.new(clock: @clock).call(wallet: wallet, user: users(:friend), ping: ping).value
  end

  def ping_every(seconds, times)
    times.times.map { @clock.advance(seconds) && ping }.last
  end

  test "starts dwelling on the first ping inside the zone" do
    outcome = ping

    assert_equal :dwelling, outcome.status
    assert outcome.inside_zone
    assert outcome.in_time_window
    assert_equal 0, outcome.dwell_progress_seconds
    assert_equal 30, outcome.dwell_required_seconds
  end

  test "accumulates dwell time across pings" do
    ping

    assert_equal 20, ping_every(10, 2).dwell_progress_seconds
  end

  test "unlocks after the dwell time and opens a 10-minute spend window" do
    ping
    outcome = ping_every(10, 3)

    assert_equal :unlocked, outcome.status
    assert_equal @clock.current + 10.minutes, outcome.unlocked_until
    assert_equal 1, @wallet.unlocks.count
  end

  test "stays unlocked during the spend window without unlocking twice" do
    ping
    ping_every(10, 3)
    outcome = ping_every(10, 1)

    assert_equal :unlocked, outcome.status
    assert_equal 1, @wallet.unlocks.count
  end

  test "outside the zone ends the session" do
    ping
    @clock.advance(10)
    outcome = ping(at: OUTSIDE)

    assert_equal :outside_zone, outcome.status
    assert_not outcome.inside_zone
    assert_empty @wallet.presence_sessions.open
  end

  test "coming back after leaving starts the dwell again" do
    ping
    @clock.advance(20) && ping(at: OUTSIDE)
    @clock.advance(10) && ping

    assert_equal 10, ping_every(10, 1).dwell_progress_seconds
  end

  test "outside the time window does not dwell" do
    @clock = FixedClock.new(Time.utc(2026, 10, 21, 10, 0)) # 12:00 SAST

    outcome = ping

    assert_equal :outside_time_window, outcome.status
    assert outcome.inside_zone
    assert_not outcome.in_time_window
    assert_empty @wallet.presence_sessions
  end

  test "a gap in pings restarts the dwell" do
    ping
    @clock.advance(20) && ping
    @clock.advance(46) && ping

    assert_equal 10, ping_every(10, 1).dwell_progress_seconds
  end

  test "rejects a mock location and ends the session" do
    ping
    @clock.advance(10)
    outcome = ping(mocked: true)

    assert_equal :rejected, outcome.status
    assert_equal :mock_location, outcome.reason
    assert_empty @wallet.presence_sessions.open
  end

  test "rejects a poor-accuracy ping without counting it" do
    ping
    @clock.advance(10)
    outcome = ping(accuracy_m: 51)

    assert_equal :rejected, outcome.status
    assert_equal :low_accuracy, outcome.reason
    assert_equal @clock.current - 10, @wallet.presence_sessions.open.sole.last_ping_at
  end

  test "needs a fresh dwell after the spend window ends" do
    ping
    ping_every(10, 3)
    @clock.advance(10.minutes)

    assert_equal :dwelling, ping.status
  end

  test "refuses a wallet that isn't active" do
    ping_ = PresencePing.new(coordinates: INSIDE, accuracy_m: 5, mocked: false)
    result = Presence::RecordPing.new(clock: @clock).call(wallet: wallets(:pending_gift), user: users(:friend), ping: ping_)

    assert_equal :wallet_closed, result.error
  end
end
