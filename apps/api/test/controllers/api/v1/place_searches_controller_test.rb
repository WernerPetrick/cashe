require "test_helper"

class Api::V1::PlaceSearchesControllerTest < ActionDispatch::IntegrationTest
  SHOP = PlaceSearch::Hit.new(name: "Mike's Bikes", address: "12 Long Street, Cape Town",
                              latitude: -33.923, longitude: 18.419)

  setup { PlaceSearch.provider = FakePlaceSearch.new([ SHOP ]) }

  def search(q: "bikes", near: "-33.9249,18.4241", headers: as(users(:friend)))
    get api_v1_place_searches_path(q: q, near: near), headers: headers
  end

  test "finds real-world places near the map centre" do
    search

    assert_contract :ok
    assert_equal [ { "name" => "Mike's Bikes", "address" => "12 Long Street, Cape Town",
                     "latitude" => -33.923, "longitude" => 18.419 } ], json["results"]
  end

  test "requires a JWT" do
    search(headers: {})

    assert_contract :unauthorized
  end

  test "rejects a one-letter query" do
    search(q: "b")

    assert_contract :unprocessable_content
    assert_equal "invalid_query", error_code
  end

  test "rejects an unreadable centre" do
    search(near: "somewhere")

    assert_contract :unprocessable_content
    assert_equal "invalid_location", error_code
  end

  test "503 when the place search is down" do
    PlaceSearch.provider = FakePlaceSearch.new(unavailable: true)
    search

    assert_contract :service_unavailable
    assert_equal "place_search_unavailable", error_code
  end

  test "never logs the map centre" do
    log = Rails.root.join("log/test.log")
    before = log.size
    search(near: "-33.92491234,18.42411234")

    assert_no_match(/33\.9249|18\.4241/, log.read.byteslice(before..))
  end

  test "30 a minute per user, then 429" do
    headers = as(users(:friend))
    30.times { search(headers: headers) }
    assert_response :ok

    search(headers: headers)
    assert_contract :too_many_requests
    assert_equal "rate_limited", error_code
  end
end
