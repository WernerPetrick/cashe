require "test_helper"

class Api::V1::PlacesControllerTest < ActionDispatch::IntegrationTest
  test "lists places near a point with their distance" do
    get api_v1_places_path(near: "-33.9250,18.4241"), headers: as(users(:friend))

    assert_contract :ok
    assert_equal [ "School Tuckshop" ], json["places"].pluck("name") # Mike's Bikes is ~5.7 km away
    assert_operator json["places"].first["distance_m"], :<, 20
  end

  test "orders places nearest first" do
    get api_v1_places_path(near: "-33.9400,18.4450"), headers: as(users(:friend)) # between the two

    assert_contract :ok
    assert_equal [ "School Tuckshop", "Mike's Bikes" ], json["places"].pluck("name")
  end

  test "leaves out places more than 5 km away" do
    get api_v1_places_path(near: "-26.2041,28.0473"), headers: as(users(:friend)) # Johannesburg

    assert_contract :ok
    assert_empty json["places"]
  end

  test "never logs the search point" do
    log = Rails.root.join("log/test.log")
    before = log.size
    get api_v1_places_path(near: "-33.92501234,18.42411234"), headers: as(users(:friend))

    assert_no_match(/33\.9250|18\.4241/, log.read.byteslice(before..))
  end

  test "rejects an unreadable point" do
    get api_v1_places_path(near: "somewhere"), headers: as(users(:friend))

    assert_contract :unprocessable_content
    assert_equal "invalid_location", error_code
  end

  test "adds a place" do
    body = { name: "Corner Café", latitude: -33.93, longitude: 18.42, radius_m: 40, dwell_seconds: 60 }
    post api_v1_places_path, params: body, headers: as(users(:friend)), as: :json

    assert_contract :created
    assert_equal users(:friend), Place.find(json["id"]).created_by
  end

  test "reports invalid place details" do
    post api_v1_places_path, params: { name: "", latitude: 95, longitude: 18, radius_m: 5, dwell_seconds: 60 },
      headers: as(users(:friend)), as: :json

    assert_contract :unprocessable_content
    assert_includes json.dig("error", "details"), "Radius m must be in 10..1000"
  end

  test "children can't add places" do
    post api_v1_places_path, params: { name: "Arcade", latitude: -33.93, longitude: 18.42, radius_m: 40, dwell_seconds: 60 },
      headers: as(users(:kid)), as: :json

    assert_contract :forbidden
  end
end
