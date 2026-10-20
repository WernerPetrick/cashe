# The response to creating a wallet. A gift's claim link is shown here and never again.
class CreatedWalletSerializer
  def initialize(created, viewer:)
    @created = created
    @viewer = viewer
  end

  def as_json(*)
    WalletDetailSerializer.new(@created.wallet, viewer: @viewer).as_json
      .merge(claim_url: @created.claim_token&.url)
  end
end
