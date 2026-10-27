require "test_helper"

class CasheJobsTest < ActiveJob::TestCase
  test "the gift job refunds a gift past its claim window" do
    travel_to Time.utc(2026, 10, 24) do
      ExpireGiftsJob.perform_now
    end

    assert_predicate wallets(:pending_gift).reload, :expired?
  end

  test "the presence job ends a session that stopped pinging" do
    travel_to Time.utc(2026, 10, 21, 8, 40)
    stale = wallets(:tuckshop_gift).presence_sessions.create!(user: users(:friend), entered_at: 2.minutes.ago,
      last_ping_at: 1.minute.ago)
    EndStalePresenceSessionsJob.perform_now

    assert_not_nil stale.reload.ended_at
  end

  test "both jobs are scheduled in production" do
    schedule = Rails.application.config_for(:recurring, env: "production")

    assert_equal "ExpireGiftsJob", schedule.dig(:expire_gifts, :class)
    assert_equal "EndStalePresenceSessionsJob", schedule.dig(:end_stale_presence_sessions, :class)
  end
end
