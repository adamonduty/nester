module Nester
  module TestCase
    module ClassMethods
      attr_reader :nester_options

      def nest(model, options = {})
        options[:under] = [*options[:under]]   # convert item to single item array
        options[:model] = model
        @nester_options = options
      end 
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def setup
      options = self.class.nester_options
      options[:singular_name] = options[:model].to_s
      options[:plural_name] = options[:singular_name].pluralize

      build_http_action_methods(options)
      build_named_route_methods(options)
      super
    end

private

    def build_http_action_methods(options = {})
      # Build parameters hash for eval
      keys_and_values_for_hash = []
      options[:under].size.times do |i|
        chain = options[:under].reverse[0..i]
        keys_and_values_for_hash << ":#{chain.last}_id => @#{options[:singular_name]}.#{chain.join('.')}.to_param"
      end

      # Build get, post, head, etc
      ['delete', 'get', 'head', 'post', 'put'].each do |method|
        class_eval %Q{
          def #{method}(action, parameters = {}, session = nil, flash = nil)
            parameters.merge!({#{keys_and_values_for_hash.join(',')}})
            super(action, parameters, session, flash)
          end
        }
      end
    end

    def build_named_route_methods(options)
      # Build assigned instance vars
      assigned_vars = options[:under].map {|u| "assigns(:#{u})"}

      # Build named route methods
      class_eval %Q{
        def #{options[:plural_name]}_path
          #{options[:under].join('_')}_#{options[:plural_name]}_path(#{assigned_vars.join(',')})
        end

        def #{options[:singular_name]}_path(assigned)
          #{options[:under].join('_')}_#{options[:singular_name]}_path(#{assigned_vars.join(',')}, assigned)
        end
      }
    end
  end
end
