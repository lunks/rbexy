require "action_view"

module Rbexy
  class Component < ActionView::Base
    class LookupContext < ActionView::LookupContext
      attr_accessor :component_name_stack

      def self.details_hash(context)
        context.registered_details.each_with_object({}) do |key, details_hash|
          value = key == :locale ? [context.locale] : context.send(key)
          details_hash[key] = value
        end
      end

      # We override any calls to args_for_lookup and set partial=false so that
      # the lookup context doesn't automatically add a `_` prefix to the
      # template path, since we're using the Rails partial-rendering
      # functionality but don't want our templates prefixed with a `_`
      def args_for_lookup(name, prefixes, partial, keys, details_options)
        partial = false if component_name_stack.include?(name)
        super(name, prefixes, partial, keys, details_options)
      end
    end

    def initialize(view_context, **props)
      super(
        view_context.lookup_context,
        view_context.assigns,
        view_context.controller
      )

      @view_context = view_context

      setup(**props)
    end

    # Override in your subclass to handle props, setup your component, etc.
    # You can also implement `initialize` but you just need to remember to
    # call super(view_context).
    def setup(**props); end

    def render(&block)
      @content_block = block_given? ? block : nil
      call
    end

    def call
      replace_lookup_context
      view_renderer.render(self, partial: component_name, &nil)
    ensure
      restore_lookup_context
    end

    def content
      content_block ? view_context.capture(self, &content_block) : ""
    end

    def create_context(name, value)
      rbexy_context.last[name] = value
    end

    def use_context(name)
      index = rbexy_context.rindex { |c| c.has_key?(name) }
      index ?
        rbexy_context[index][name] :
        raise(ContextNotFound, "no parent context `#{name}`")
    end

    def view_renderer
      view_context.view_renderer
    end

    def component_name
      self.class.name.underscore
    end

    private

    attr_reader :view_context, :content_block, :old_lookup_context

    def replace_lookup_context
      unless view_renderer.lookup_context.is_a? Rbexy::Component::LookupContext
        @old_lookup_context = view_renderer.lookup_context
        view_renderer.lookup_context = build_lookup_context(old_lookup_context)
      end

      (view_renderer.lookup_context.component_name_stack ||= []) << component_name
    end

    def restore_lookup_context
      return unless old_lookup_context
      view_renderer.lookup_context = old_lookup_context
      @old_lookup_context = nil
    end

    def build_lookup_context(existing_context)
      paths = existing_context.view_paths.dup.unshift(
        *Rbexy.configuration.template_paths.map { |p| ActionView::OptimizedFileSystemResolver.new(p) }
      )

      LookupContext.new(paths, LookupContext.details_hash(existing_context))
    end

    def method_missing(meth, *args, &block)
      if view_context.respond_to?(meth)
        view_context.send(meth, *args, &block)
      else
        super
      end
    end
  end
end
