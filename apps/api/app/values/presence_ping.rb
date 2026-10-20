# One location report from the unlock screen. Lives only for the request.
PresencePing = Data.define(:coordinates, :accuracy_m, :mocked) do
  def inspect = "#<PresencePing [redacted]>"
  alias_method :to_s, :inspect
end
