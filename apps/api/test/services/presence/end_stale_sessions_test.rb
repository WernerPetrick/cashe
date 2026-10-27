require "test_helper"

class Presence::EndStaleSessionsTest < ActiveSupport::TestCase
  setup { @now = Time.utc(2026, 10, 21, 8, 40) }

  def session(last_ping_at, wallet: wallets(:tuckshop_gift))
    wallet.presence_sessions.create!(user: users(:friend), entered_at: last_ping_at - 20, last_ping_at: last_ping_at)
  end

  def end_stale = Presence::EndStaleSessions.new(clock: FixedClock.new(@now)).call

  test "ends a session whose pings stopped, at its last ping" do
    stale = session(@now - 46)

    assert_equal 1, end_stale.value
    assert_equal @now - 46, stale.reload.ended_at
  end

  test "keeps a session that is still pinging" do
    live = session(@now - 30)
    end_stale

    assert_nil live.reload.ended_at
  end

  test "leaves ended sessions as they were" do
    done = session(@now - 600).tap { |s| s.update!(ended_at: @now - 590) }
    end_stale

    assert_equal @now - 590, done.reload.ended_at
  end
end
