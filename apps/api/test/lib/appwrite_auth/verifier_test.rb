require "test_helper"

class AppwriteAuth::VerifierTest < ActiveSupport::TestCase
  class CountingGateway
    attr_reader :calls

    def initialize(identity)
      @identity = identity
      @calls = 0
    end

    def identity_for(_token)
      @calls += 1
      @identity
    end
  end

  setup do
    @identity = AppwriteAuth::Identity.new(appwrite_user_id: "u1", name: "Pat")
    @gateway = CountingGateway.new(@identity)
    @verifier = AppwriteAuth::Verifier.new(gateway: @gateway, cache: ActiveSupport::Cache::MemoryStore.new, ttl: 60)
  end

  test "returns the identity Appwrite reports" do
    assert_equal @identity, @verifier.call("jwt")
  end

  test "caches the answer per token" do
    2.times { @verifier.call("jwt") }
    @verifier.call("other-jwt")

    assert_equal 2, @gateway.calls
  end

  test "skips Appwrite for a blank token" do
    assert_nil @verifier.call(nil)
    assert_nil @verifier.call("")
    assert_equal 0, @gateway.calls
  end
end
