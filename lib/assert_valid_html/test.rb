class ActionController::TestCase
  def assert_valid_html
    return unless @response.headers['Content-Type'].match(/html/)

    validator = AssertValidHtml::Validator.new(@response.body)
    assert_block(validator.message){ validator.valid? }
  end

  alias_method :assert_valid_markup, :assert_valid_html
end
