require "net/http"
require "openssl"

module PlaceSearch
  # Searches OpenStreetMap with komoot's Photon, biased toward a map centre. Only the
  # query and that centre are sent, never a person's location.
  class Photon
    HEADERS = { "User-Agent" => "Cashe/1.0 (hackathon prototype)", "Accept" => "application/json" }.freeze
    TIMEOUTS = { open_timeout: 3, read_timeout: 5 }.freeze
    # Nearby results first while still finding places further away; streets left
    # out, since a whole street is no centre for a zone (ADR 0006).
    TUNING = { zoom: 10, location_bias_scale: 0.1, osm_tag: "!highway", lang: "en" }.freeze
    FAILURES = [ Timeout::Error, SocketError, SystemCallError, IOError, OpenSSL::SSL::SSLError,
                 Net::HTTPBadResponse, JSON::ParserError ].freeze

    def initialize(url: Rails.configuration.x.cashe.place_search_url, fetch: method(:http_get))
      @url = url
      @fetch = fetch
    end

    def search(query, near:, limit:)
      features(query, near, limit).filter_map { |feature| hit(feature) }.uniq
    rescue *FAILURES => e
      raise Unavailable, "Photon search failed (#{e.class})"
    end

    private

    def features(query, near, limit)
      JSON.parse(@fetch.call(uri(query, near, limit))).fetch("features", [])
    end

    def uri(query, near, limit)
      URI(@url).tap do |uri|
        uri.query = URI.encode_www_form(q: query, lat: near.latitude, lon: near.longitude, limit: limit, **TUNING)
      end
    end

    # Unnamed results (a bare address) are named after their street.
    def hit(feature)
      properties = feature.fetch("properties", {})
      longitude, latitude = feature.dig("geometry", "coordinates")
      name = properties["name"] || street(properties)
      Hit.new(name: name, address: address(properties, name), latitude: latitude, longitude: longitude) if name && latitude
    end

    def street(properties)
      [ properties["housenumber"], properties["street"] ].compact.join(" ").presence
    end

    def address(properties, name)
      parts = [ street(properties), properties["district"] || properties["locality"], properties["city"] ]
      parts.compact.uniq.without(name).join(", ")
    end

    def http_get(uri)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", **TIMEOUTS) { |http| http.get(uri.request_uri, HEADERS) }
      raise Unavailable, "Photon answered #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      response.body
    end
  end
end
