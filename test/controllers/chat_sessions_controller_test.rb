require "test_helper"

class ChatSessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get chat_sessions_index_url
    assert_response :success
  end

  test "should get show" do
    get chat_sessions_show_url
    assert_response :success
  end

  test "should get create" do
    get chat_sessions_create_url
    assert_response :success
  end

  test "should get update" do
    get chat_sessions_update_url
    assert_response :success
  end
end
