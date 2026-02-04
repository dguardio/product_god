require "test_helper"

class BoardMeetingsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get board_meetings_new_url
    assert_response :success
  end

  test "should get create" do
    get board_meetings_create_url
    assert_response :success
  end

  test "should get show" do
    get board_meetings_show_url
    assert_response :success
  end
end
