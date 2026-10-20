require "committee"

# Checks request-test responses against packages/api_contract/openapi.yaml.
module ApiContract
  include Committee::Test::Methods

  SPEC = Rails.root.join("../../packages/api_contract/openapi.yaml").to_s
  SCHEMA = Committee::Drivers.load_from_file(SPEC, parser_options: { strict_reference_validation: true })

  def committee_options
    { schema: SCHEMA, prefix: "/api/v1", parse_response_by_content_type: true }
  end

  def request_object = request
  def response_data = [ response.status, response.headers, response.body ]

  # Asserts the status and that the body matches the spec for it.
  def assert_contract(status)
    assert_response status
    assert_response_schema_confirm(Rack::Utils.status_code(status))
  end
end
