module Presence
  # The unlock engine. A wallet unlocks when the owner is inside the place's
  # geofence, inside an allowed time window, and has stayed for the place's
  # dwell time. Coordinates are used for the checks and then discarded; a
  # spoofed or impossible location is rejected.
  class RecordPing
    def initialize(geofence: Geofence.new, clock: Time, config: Rails.configuration.x.cashe, jumps: JumpCheck.new)
      @geofence = geofence
      @clock = clock
      @config = config
      @jumps = jumps
    end

    def call(wallet:, user:, ping:)
      return Result.failure(:wallet_closed) unless wallet.active?

      wallet.with_lock { Result.success(evaluate(wallet, user, ping)) }
    end

    private

    def evaluate(wallet, user, ping)
      tracker = Tracker.new(wallet: wallet, user: user, now: @clock.current, config: @config)
      reason = rejection(wallet, user, ping)
      return tracker.reject(reason) if reason

      tracker.track(checks(tracker, ping))
    end

    def checks(tracker, ping)
      Checks.new(inside_zone: @geofence.contains?(tracker.place, ping.coordinates), in_time_window: tracker.in_window?)
    end

    def rejection(wallet, user, ping)
      return :mock_location if ping.mocked && !@config.allow_mock_locations
      return :low_accuracy if ping.accuracy_m > @config.max_accuracy_m

      :impossible_jump if @jumps.jumped?(wallet: wallet, user: user, ping: ping, now: @clock.current)
    end
  end
end
