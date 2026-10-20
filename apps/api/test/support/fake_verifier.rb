# Stands in for AppwriteAuth::Verifier: knows a fixed set of tokens.
class FakeVerifier
  def initialize(identities = {}, unavailable: false)
    @identities = identities
    @unavailable = unavailable
  end

  def call(token)
    raise AppwriteAuth::Unavailable, "down" if @unavailable

    @identities[token]
  end
end
