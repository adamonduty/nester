module Nester
  module TestCase
    module ClassMethods
      attr_reader :nester_options

      def nest(options = {})
        options[:under] = [*options[:under]]   # convert item to single item array
        @nester_options = options
      end 
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def setup
      options = self.class.nester_options
      options[:plural_name] = @controller.controller_name
      options[:singular_name] = @controller.controller_name.singularize

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

      super
    end
  end
end
