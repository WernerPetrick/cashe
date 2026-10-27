module Gifts
  # Refunds every gift that is due: unclaimed past its claim window, or past the
  # sender's expiry date. Each gift is expired under its own row lock.
  class ExpireDue
    def initialize(expire: nil, clock: Time)
      @clock = clock
      @expire = expire || Expire.new(clock: clock)
    end

    def call
      now = @clock.current
      expired = Wallet.unclaimed_past(now).or(Wallet.gift_expired_by(now)).find_each.count do |wallet|
        @expire.call(wallet: wallet).success?
      end
      Result.success(expired)
    end
  end
end
