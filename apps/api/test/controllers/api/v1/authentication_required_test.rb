require "test_helper"

# Every endpoint refuses a request without a valid JWT.
class Api::V1::AuthenticationRequiredTest < ActionDispatch::IntegrationTest
  ENDPOINTS = [
    [ :post, "/api/v1/session" ], [ :get, "/api/v1/me" ],
    [ :get, "/api/v1/places?near=-33.9,18.4" ], [ :post, "/api/v1/places" ],
    [ :get, "/api/v1/wallets" ], [ :post, "/api/v1/wallets" ], [ :get, "/api/v1/wallets/1" ],
    [ :post, "/api/v1/wallets/1/deposits" ], [ :post, "/api/v1/wallets/1/presence_pings" ],
    [ :post, "/api/v1/wallets/1/spends" ], [ :get, "/api/v1/wallets/1/ledger_entries" ],
    [ :post, "/api/v1/wallets/1/cancellation" ], [ :post, "/api/v1/gift_claims" ]
  ].freeze

  ENDPOINTS.each do |verb, path|
    test "#{verb.upcase} #{path} needs a valid token" do
      public_send(verb, path, headers: { "Authorization" => "Bearer forged" }, as: :json)

      assert_contract :unauthorized
      assert_equal "unauthorized", error_code
    end
  end
end
