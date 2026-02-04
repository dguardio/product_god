require "test_helper"

class AuthVerificationTest < ActionDispatch::IntegrationTest
  test "should access root publicly" do
    get root_path
    assert_response :success
  end

  test "should access search publicly" do
    get search_path
    assert_response :success
  end

  test "should access knowledge graph index publicly" do
    get knowledge_graph_index_path
    assert_response :success
  end

  test "should NOT access playbooks without login" do
    get playbooks_path
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "should NOT access board meetings without login" do
    get board_meeting_path(1) # Assuming ID 1 exists or route matches, actually new is safer
    # But wait, board_meetings only has :new, :create, :show
    get new_board_meeting_path
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end
end
