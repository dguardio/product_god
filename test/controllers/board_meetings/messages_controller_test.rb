require "test_helper"

class BoardMeetings::MessagesControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get board_meetings_messages_create_url
    assert_response :success
  end
end
