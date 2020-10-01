require "rbexy/version"

module Rbexy
  autoload :Lexer, "rbexy/lexer"
  autoload :Parser, "rbexy/parser"
  autoload :Nodes, "rbexy/nodes"
  autoload :Runtime, "rbexy/runtime"
  autoload :HashMash, "rbexy/hash_mash"
  autoload :OutputBuffer, "rbexy/output_buffer"
  autoload :ComponentTagBuilder, "rbexy/component_tag_builder"
  autoload :ViewHelper, "rbexy/view_helper"
  autoload :Configuration, "rbexy/configuration"

  ContextNotFound = Class.new(StandardError)
  TemplateNotFound = Class.new(StandardError)
  AmbiguousTemplate = Class.new(StandardError)

  class << self
    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def compile(template_string)
      tokens = Rbexy::Lexer.new(template_string).tokenize
      template = Rbexy::Parser.new(tokens).parse
      template.compile
    end

    def evaluate(template_string, runtime)
      runtime.evaluate compile(template_string)
    end
  end
end
