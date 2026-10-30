require "test_helper"

class PlaceSearch::PhotonTest < ActiveSupport::TestCase
  CENTRE = Coordinates.new(latitude: -33.9249, longitude: 18.4241)

  def feature(properties, coordinates = [ 18.4241, -33.9249 ])
    { "type" => "Feature", "properties" => properties, "geometry" => { "type" => "Point", "coordinates" => coordinates } }
  end

  def photon(features: [], body: nil, seen: [])
    fetch = ->(uri) { seen << uri && (body || { "type" => "FeatureCollection", "features" => features }.to_json) }
    PlaceSearch::Photon.new(url: "https://photon.test/api/", fetch: fetch)
  end

  test "asks for the query near the centre" do
    seen = []
    photon(seen: seen).search("tuckshop", near: CENTRE, limit: 8)

    params = URI.decode_www_form(seen.first.query).to_h
    assert_equal "photon.test", seen.first.host
    assert_equal({ "q" => "tuckshop", "lat" => "-33.9249", "lon" => "18.4241", "limit" => "8", "zoom" => "10",
                   "location_bias_scale" => "0.1", "osm_tag" => "!highway", "lang" => "en" }, params)
  end

  test "turns features into hits with a short address" do
    shop = feature({ "name" => "Mike's Bikes", "housenumber" => "12", "street" => "Long Street",
                     "district" => "City Centre", "city" => "Cape Town" }, [ 18.4190, -33.9230 ])

    hit = photon(features: [ shop ]).search("bikes", near: CENTRE, limit: 8).sole

    assert_equal PlaceSearch::Hit.new(name: "Mike's Bikes", address: "12 Long Street, City Centre, Cape Town",
                                      latitude: -33.9230, longitude: 18.4190), hit
  end

  test "names a bare address after its street, without repeating it" do
    address = feature({ "housenumber" => "5", "street" => "Kloof Street", "city" => "Cape Town" })

    hit = photon(features: [ address ]).search("kloof", near: CENTRE, limit: 8).sole

    assert_equal "5 Kloof Street", hit.name
    assert_equal "Cape Town", hit.address
  end

  test "skips features with no name or no point, and duplicates" do
    cafe = feature({ "name" => "Good Coffee" })
    features = [ feature({ "city" => "Cape Town" }), { "properties" => { "name" => "Nowhere" } }, cafe, cafe ]

    assert_equal [ "Good Coffee" ], photon(features: features).search("coffee", near: CENTRE, limit: 8).map(&:name)
  end

  test "raises Unavailable on an unreadable answer" do
    assert_raises(PlaceSearch::Unavailable) { photon(body: "<html>").search("coffee", near: CENTRE, limit: 8) }
  end

  test "raises Unavailable when Photon can't be reached, without the centre in the message" do
    timeout = PlaceSearch::Photon.new(url: "https://photon.test/api/", fetch: ->(_uri) { raise Net::OpenTimeout })

    error = assert_raises(PlaceSearch::Unavailable) { timeout.search("coffee", near: CENTRE, limit: 8) }
    assert_no_match(/33\.92|18\.42/, error.message)
  end
end
