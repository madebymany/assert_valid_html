assert_valid_html
=================

Check the validity of your HTML.

Usage (in Rails 3)
------------------

Add to your Gemfile:

    group :test do
      gem "assert_valid_html",
          :git => "git://github.com/madebymany/assert_valid_html.git"
    end

Add to your functional tests:

    assert_valid_html

Usage (in Ruby)
---------------

You can also use the validator on its own:

    validator = AssertValidHtml::Validator.new(html)

Check validity

    validator.valid?

Look at individual problems

    validator.errors.each do |e|
      puts e.line    # Line number
      puts e.message # What tidy says
      puts e.context # The offending line of HTML, with a few lines above and below
    end

Get a report message containing all problems:

    validator.message

Which generates something like:

    HTML is invalid

    Warning: <img> proprietary attribute "blarg" at line 7 column 1
        2 | <html >
        3 |   <head>
        4 |     <title>Title</title>
        5 |   </head>
        6 |   <body>
    *   7 | <img blarg='flup' src='a' alt='a' />
        8 |   </body>
        9 | </html>

What it does
------------

It uses `tidy` to check that the HTML is valid UTF-8 XHTML. It ignores some
warning to allow the use of HTML5 (although you will still need to close all
elements). It's more of a bozo filter than a strict validator, but it should
help to catch most mistakes.
