# Adapter between Cashe and the outside place search (ADR 0006). Everything
# provider-specific lives here.
module PlaceSearch
  class << self
    attr_writer :provider

    def provider
      @provider ||= Photon.new
    end
  end
end
