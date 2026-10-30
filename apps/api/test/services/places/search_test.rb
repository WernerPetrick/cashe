require "test_helper"

class Places::SearchTest < ActiveSupport::TestCase
  CENTRE = Coordinates.new(latitude: -33.9249, longitude: 18.4241)
  SHOP = PlaceSearch::Hit.new(name: "Mike's Bikes", address: "Cape Town", latitude: -33.923, longitude: 18.419)

  setup do
    @provider = FakePlaceSearch.new([ SHOP ])
    @search = Places::Search.new(provider: @provider)
  end

  test "returns the provider's hits for a tidied query" do
    result = @search.call(query: "  mike's   bikes ", near: CENTRE)

    assert result.success?
    assert_equal [ SHOP ], result.value
    assert_equal [ { query: "mike's bikes", near: CENTRE, limit: 8 } ], @provider.searches
  end

  test "refuses a query that's too short or too long without searching" do
    assert_equal :invalid_query, @search.call(query: " a ", near: CENTRE).error
    assert_equal :invalid_query, @search.call(query: nil, near: CENTRE).error
    assert_equal :invalid_query, @search.call(query: "x" * 101, near: CENTRE).error
    assert_empty @provider.searches
  end

  test "needs a centre" do
    assert_equal :invalid_location, @search.call(query: "bikes", near: nil).error
  end
end
