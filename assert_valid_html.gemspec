lib = File.expand_path("../lib/", __FILE__)
$:.unshift lib unless $:.include?(lib)

require "assert_valid_html/version"

spec = Gem::Specification.new do |s|
  s.name             = "assert_valid_html"
  s.version          = AssertValidHtml::VERSION::STRING
  s.author           = "Paul Battley"
  s.email            = "pbattley@gmail.com"
  s.summary          = "Check HTML validity without using an external web service"
  s.files            = Dir["lib/**/*.rb"]
  s.require_path     = "lib"
end
