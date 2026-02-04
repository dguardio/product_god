require "test_helper"

class DataSourcesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get data_sources_index_url
    assert_response :success
  end
end
