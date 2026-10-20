# The secret in a gift's claim link. Only its digest is stored, and it never prints.
class ClaimToken
  attr_reader :value

  def self.generate
    new(SecureRandom.urlsafe_base64(32))
  end

  def self.digest(value)
    Digest::SHA256.hexdigest(value.to_s)
  end

  def initialize(value)
    @value = value
  end

  def digest
    self.class.digest(value)
  end

  def url
    Rails.configuration.x.cashe.claim_url_base + value
  end

  def inspect
    "#<ClaimToken [redacted]>"
  end
  alias to_s inspect
end
