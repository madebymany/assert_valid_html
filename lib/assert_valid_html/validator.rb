require "open3"

module AssertValidHtml
  class Validator
    ValidationError = Struct.new(:message, :line, :context)

    ALLOWED_ATTRIBUTES = %w[
      media hreflang rel target value charset autofocus placeholder form
      required disabled autocomplete min max multiple pattern step list
      novalidate formaction formenctype formmethod formnovalidate formtarget
      type label contextmenu scoped async manifest sizes reversed sandbox
      seamless srcdoc contenteditable draggable hidden role data-\\S* aria-\\S*
      spellcheck
    ]

    ALLOWED_ELEMENTS = %w[
      section article aside hgroup header footer nav figure figcaption video
      audio source embed progress meter time ruby rt rp wbr canvas command
      details datalist keygen output
    ]

    IGNORED = [
      /Warning: trimming empty/,
      /lacks "summary" attribute/,
      /<meta> lacks "content" attribute/, # HTML5
      /proprietary attribute "xmlns:fb"/, # Facebook
      /<\/?fb:/                           #    //
    ]

    def self.ignore(regexp)
      ignored << regexp
    end

    def self.ignored
      @ignored ||= IGNORED.dup
    end

    def self.ignored_regexp
      Regexp.new((ignored + [
        %r{proprietary attribute "(?:#{ALLOWED_ATTRIBUTES.join("|")})"},
        %r{discarding unexpected </?(?:#{ALLOWED_ELEMENTS.join("|")})>}
      ]).join("|"))
    end

    def initialize(html)
      @html  = html
      @lines = html.split(/\n/)
    end

    def valid?
      errors.empty?
    end

    def errors
      @errors ||= (
        ignored = self.class.ignored_regexp
        tidy(@html).split(/\n/).select {|w| w =~ /Warning/ && w !~ ignored }
      ).inject([]){ |array, error|
        line, message = parse_tidy_message(error)
        array << ValidationError.new(message, line, context(line))
      }
    end

    def context(line)
      top    = [0, line - 6].max
      bottom = [[@lines.length - 1, 0].max, line + 4].min
      (top..bottom).to_a.zip(@lines[top..bottom]).map{ |number, text|
        "%s %3d | %s" % [number + 1 == line ? "*" : " ", number + 1, text]
      }.join("\n")
    end

    def message
      if valid?
        "HTML is valid"
      else
        (["HTML is invalid"] + errors.map{ |e| e.message + "\n" + e.context }).join("\n\n")
      end
    end

  private
    def parse_tidy_message(error)
      m = error.match(/^line (\d+) column (\d+) - (.*)/)
      return m[1].to_i, "#{m[3]} at line #{m[1]} column #{m[2]}"
    end

    def tidy(html)
      stdin, stdout, stderr = Open3.popen3("tidy -q -e -utf8")
      stdin << html
      stdin.close
      stderr.read
    end
  end
end
