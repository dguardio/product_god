require "test_helper"

class KnowledgeGraphControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get knowledge_graph_index_url
    assert_response :success
  end
end
