# One location report from the unlock screen. Lives only for the request.
PresencePing = Data.define(:coordinates, :accuracy_m, :mocked) do
  # Builds a ping from request params, or nil if they can't be read.
  def self.from_params(params)
    new(coordinates: Coordinates.new(latitude: params[:latitude], longitude: params[:longitude]),
      accuracy_m: Float(params[:accuracy_m]), mocked: ActiveModel::Type::Boolean.new.cast(params[:is_mocked]) || false)
  rescue ArgumentError, TypeError
    nil
  end

  def inspect = "#<PresencePing [redacted]>"
  alias_method :to_s, :inspect
end
