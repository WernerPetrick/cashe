module Presence
  # Closes presence sessions whose pings stopped (the unlock screen was closed or
  # the phone went quiet), ending them when they were last seen.
  class EndStaleSessions
    def initialize(clock: Time, config: Rails.configuration.x.cashe)
      @clock = clock
      @config = config
    end

    def call
      cutoff = @clock.current - @config.ping_gap_seconds
      ended = PresenceSession.open.where(last_ping_at: ...cutoff)
        .update_all([ "ended_at = last_ping_at, updated_at = ?", @clock.current ])
      Result.success(ended)
    end
  end
end
