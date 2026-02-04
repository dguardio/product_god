require "test_helper"

class PlaybooksControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get playbooks_index_url
    assert_response :success
  end

  test "should get new" do
    get playbooks_new_url
    assert_response :success
  end

  test "should get show" do
    get playbooks_show_url
    assert_response :success
  end
end
