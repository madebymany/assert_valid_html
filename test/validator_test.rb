lib = File.expand_path("../../lib", __FILE__)
$:.unshift lib unless $:.include?(lib)
require "test/unit"
require "assert_valid_html"

class ValidatorTest < Test::Unit::TestCase

SAMPLE = lambda{ |extras| <<-END
<!DOCTYPE html>
<html #{extras[:html_options]}>
  <head>
    <title>Title</title>
  </head>
  <body>
#{extras[:content]}
  </body>
</html>
END
}

  def test_should_find_valid_sample_valid
    html = SAMPLE.call(:content => "")
    validator = AssertValidHtml::Validator.new(html)
    assert validator.valid?
  end

  def test_should_find_unclosed_element_invalid
    html = SAMPLE.call(:content => "<h1>Heading")
    validator = AssertValidHtml::Validator.new(html)
    assert !validator.valid?
    assert_equal 1, validator.errors.length
    assert_match %r{</h1>}, validator.errors.first.message
  end

  def test_should_find_unknown_attribute_invalid
    html = SAMPLE.call(:content => "<img blarg='flup' src='a' alt='a' />")
    validator = AssertValidHtml::Validator.new(html)
    assert !validator.valid?
    assert_equal 1, validator.errors.length
    assert_match /blarg/, validator.errors.first.message
  end

  def test_should_allow_facebook_junk
    html = SAMPLE.call(:html_options => 'xmlns:fb="http://www.facebook.com/2008/fbml"',
                       :content      => "<fb:comments></fb:comments>")
    validator = AssertValidHtml::Validator.new(html)
    assert validator.valid?
  end

  def test_should_allow_new_patterns_to_be_ignored
    AssertValidHtml::Validator.ignore %r{</?blarg\b}
    html = SAMPLE.call(:content => "<blarg class='a'>blah</blarg>")
    validator = AssertValidHtml::Validator.new(html)
    assert validator.valid?
  end

  def test_should_allow_html5_elements
    html = SAMPLE.call(:content => <<-END)
      <header>
        <nav>
        </nav>
      </header>
      <section>
        <article>
        </article>
      </section>
      <footer>
      </footer>
    END
    validator = AssertValidHtml::Validator.new(html)
    assert validator.valid?
  end

  def test_should_allow_html5_attributes
    html = SAMPLE.call(:content => <<-END)
      <form accept-charset="UTF-8" action="/search" class="form" method="get">
        <input id="q" name="q" placeholder="by keyword" type="text" />
      </form>
    END
    validator = AssertValidHtml::Validator.new(html)
    assert validator.valid?
  end

  def test_should_allow_arbitrary_html5_attributes
    html = SAMPLE.call(:content => <<-END)
      <p data-foo-bar="thing" aria-whatever-it-is="blah">
        Hello
      </p>
    END
    validator = AssertValidHtml::Validator.new(html)
    assert validator.valid?
  end

  def test_should_allow_class_as_an_attribute_on_html_tag_for_html5
    html = SAMPLE.call(:html_options => 'class="wibble"',
                       :content      => "")
    validator = AssertValidHtml::Validator.new(html)
    assert validator.valid?
  end

  def test_should_show_five_lines_of_context_on_each_side_of_error
    lines = ["1", "2", "3", "4", "5", "6 &illegal", "7", "8", "9", "10", "11"]
    html = SAMPLE.call(:content => lines.join("\n"))
    validator = AssertValidHtml::Validator.new(html)
    assert !validator.valid?
    expected = <<-END.rstrip
    7 | 1
    8 | 2
    9 | 3
   10 | 4
   11 | 5
*  12 | 6 &illegal
   13 | 7
   14 | 8
   15 | 9
   16 | 10
   17 | 11
    END
    assert_equal expected, validator.errors.first.context
  end

  def test_should_show_as_much_context_as_available_around_error
    html = "&illegal"
    validator = AssertValidHtml::Validator.new(html)
    assert !validator.valid?
    expected = "*   1 | &illegal"
    assert_equal expected, validator.errors.first.context
  end

  def test_should_consider_empty_document_invalid_at_line_1
    html = ""
    validator = AssertValidHtml::Validator.new(html)
    assert !validator.valid?
    expected = "*   1 | "
    assert_equal 1, validator.errors.first.line
    assert_equal expected, validator.errors.first.context
  end

  def test_should_return_all_error_messages_with_prefix
    html = SAMPLE.call(:content => "<h1>Heading\n&illegal")
    validator = AssertValidHtml::Validator.new(html)
    assert_equal 2, validator.errors.length
    assert_match /HTML is invalid/, validator.message
    assert validator.message.include?(validator.errors[0].message)
    assert validator.message.include?(validator.errors[1].message)
  end

  def test_should_return_a_success_message
    html = SAMPLE.call(:content => "")
    validator = AssertValidHtml::Validator.new(html)
    assert_match /HTML is valid/, validator.message
  end
end
