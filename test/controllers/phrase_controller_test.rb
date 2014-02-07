require 'test_helper'

class PhraseControllerTest < ActionController::TestCase
  test "should get next" do
    get :next
    assert_response :success
  end

end
