module Presence
  # One person's presence at one wallet's place: opens, extends and ends their
  # session, and grants an unlock once they've stayed long enough.
  class Tracker
    def initialize(wallet:, user:, now:, config:)
      @wallet = wallet
      @user = user
      @now = now
      @config = config
    end

    def place = @wallet.place
    def in_window? = @wallet.schedule.open_at?(@now)

    def track(checks)
      return outcome(:unlocked, checks, progress: full_progress, unlocked_until: active_unlock.unlocked_until) if active_unlock
      return leave(:outside_zone, checks) unless checks.inside_zone
      return leave(:outside_time_window, checks) unless checks.in_time_window

      dwell(checks)
    end

    # A spoofed location ends any session; an inaccurate one is simply not counted.
    def reject(reason)
      end_session if reason == :mock_location
      PingOutcome.build(:rejected, reason: reason)
    end

    private

    def leave(status, checks)
      end_session
      outcome(status, checks)
    end

    def dwell(checks)
      session = current_session
      progress = progress_for(session)
      return outcome(:dwelling, checks, progress: progress) unless progress.complete?

      outcome(:unlocked, checks, progress: progress, unlocked_until: grant(session).unlocked_until)
    end

    def current_session
      retire_stale_session
      session = open_session
      session ? session.tap { |open| open.update!(last_ping_at: @now) } : start_session
    end

    # A gap in pings, or a session whose unlock has already run out, starts over.
    def retire_stale_session
      session = open_session
      end_session if session && (session.unlocked_at? || @now - session.last_ping_at > @config.ping_gap_seconds)
    end

    def open_session
      return @open_session if defined?(@open_session)

      @open_session = @wallet.presence_sessions.open.find_by(user: @user)
    end

    def start_session
      @open_session = @wallet.presence_sessions.create!(user: @user, entered_at: @now, last_ping_at: @now)
    end

    def end_session
      open_session&.update!(ended_at: @now)
      @open_session = nil
    end

    def grant(session)
      session.update!(unlocked_at: @now)
      Unlock.create!(wallet: @wallet, presence_session: session, unlocked_until: @now + @config.spend_window_seconds)
    end

    def active_unlock
      @active_unlock ||= @wallet.unlocks.active_at(@now).order(:unlocked_until).last
    end

    def progress_for(session)
      DwellProgress.new(entered_at: session.entered_at, now: @now, required_seconds: place.dwell_seconds)
    end

    def full_progress
      DwellProgress.new(entered_at: @now - place.dwell_seconds, now: @now, required_seconds: place.dwell_seconds)
    end

    def outcome(status, checks, progress: nil, unlocked_until: nil)
      PingOutcome.build(status, inside_zone: checks.inside_zone, in_time_window: checks.in_time_window,
        dwell_progress_seconds: progress&.elapsed_seconds || 0, dwell_required_seconds: place.dwell_seconds,
        unlocked_until: unlocked_until)
    end
  end
end
