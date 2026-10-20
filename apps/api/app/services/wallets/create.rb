module Wallets
  # Creates a goal (owned by its funder) or a gift (unowned until claimed, with a claim link).
  class Create
    def initialize(clock: Time, config: Rails.configuration.x.cashe)
      @clock = clock
      @config = config
    end

    def call(funder:, attributes:)
      wallet = Wallet.new(attributes.merge(funder: funder))
      token = wallet.gift? ? prepare_gift(wallet) : prepare_goal(wallet)
      return invalid(wallet) unless valid?(wallet) && wallet.save

      Result.success(CreatedWallet.new(wallet: wallet, claim_token: token))
    end

    private

    def prepare_goal(wallet)
      wallet.assign_attributes(owner: wallet.funder, status: :active)
      nil
    end

    def prepare_gift(wallet)
      ClaimToken.generate.tap do |token|
        wallet.assign_attributes(status: :pending, claim_token_digest: token.digest,
          claim_expires_at: @clock.current + @config.claim_window_seconds)
      end
    end

    def valid?(wallet)
      wallet.valid?
      wallet.errors.add(:expires_at, "must be in the future") if wallet.expires_at&.<=(@clock.current)
      wallet.errors.empty?
    end

    def invalid(wallet)
      Result.failure(:validation_failed, wallet.errors.full_messages)
    end
  end
end
