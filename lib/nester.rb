module Nester
  module TestCase
    module ClassMethods
      def nest(model, options = {})
        options[:under] = [*options[:under]]   # convert item to single item array
        options[:namespace] = [*options[:namespace]]
        options[:model] = model

        options[:singular_name] = options[:model].to_s
        options[:plural_name] = options[:singular_name].pluralize

        build_http_action_methods(options)
        build_named_route_methods(options)
        build_namespaced_controller_class(options)
      end 

private
      # Build replacement methods for HTTP verbs delete, get, head, post, put.
      # These include nested parameter id's in the parameters hash passed to
      # ActionController::TestCase::Behavior#method
      def build_http_action_methods(options = {})
        # Build parameters hash for eval
        keys_and_values_for_hash = []
        options[:under].size.times do |i|
          chain = options[:under].reverse[0..i]
          keys_and_values_for_hash << ":#{chain.last}_id => @#{options[:singular_name]}.#{chain.join('.')}.to_param"
        end

        # Build get, post, head, etc
        %w{delete get head post put}.each do |method|
          class_eval %Q{
            def #{method}(action, parameters = {}, session = nil, flash = nil)
              parameters.merge!({#{keys_and_values_for_hash.join(',')}})
              super(action, parameters, session, flash)
            end
          }
        end
      end

      # Build replacements for named routes. Assume nested resources in
      # routes.rb:
      #
      # resources :authors do
      #   resources :posts do
      #     resources :comments
      #   end
      # end
      #
      # This method takes a named route like posts_path and turns it into author_posts_path
      def build_named_route_methods(options)
        # Build assigned instance vars
        assigned_vars = options[:under].map {|u| "assigns(:#{u})"}
        assigned_vars_with_assigned = assigned_vars.dup << 'assigned'

        # Build named route methods
        class_eval %Q{
          def #{options[:plural_name]}_path
            #{(options[:namespace] + options[:under]).join('_')}_#{options[:plural_name]}_path(#{assigned_vars.join(',')})
          end

          def #{options[:singular_name]}_path(assigned)
            #{(options[:namespace] + options[:under]).join('_')}_#{options[:singular_name]}_path(#{assigned_vars_with_assigned.join(',')})
          end
        }
      end

      # Build a namespaced controller class that ensures
      # ActionController::TestCase#get and similar methods generate
      # namespaced routes
      def build_namespaced_controller_class(options)
        # subclass the existing controller
        class_name = options[:namespace].map{|namespace| namespace.to_s.capitalize.constantize}.push(controller_class).join('::')
        class_eval %Q{
          class #{class_name} < #{controller_class}; end
        }

        tests class_name.constantize
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end

  module Helper
    module ClassMethods
      def nest(model, options = {})
        options[:under] = [*options[:under]]   # convert item to single item array
        options[:namespace] = [*options[:namespace]]
        options[:model] = model

        options[:singular_name] = options[:model].to_s
        options[:plural_name] = options[:singular_name].pluralize

        build_named_route_methods(options)
      end 

private
      def build_named_route_methods(options = {})
        namespace_chain = options[:namespace].map {|namespace| ":#{namespace}"}

        # Build method chains anchored off argument to _path methods
        method_chain = []
        options[:under].size.times do |i|
          chain = options[:under].reverse[0..i]
          method_chain.unshift "#{options[:singular_name]}.#{chain.join('.')}"
        end
        method_chain = namespace_chain + method_chain

        # Build method chains anchored off assumed instance variable
        method_chain_with_anchor = []
        anchor = "@#{options[:under].last}"
        options[:under].size.times do |i|
          chain = options[:under].reverse[1..i]
          method_chain_with_anchor.unshift (anchor + chain.map{|c| ".#{c}"}.join)
        end
        method_chain_with_anchor = namespace_chain + method_chain_with_anchor

        # Build named routes
        class_eval %Q{ 
          def edit_#{options[:singular_name]}_path(#{options[:singular_name]}, options = {})
            edit_polymorphic_path([#{method_chain.join(', ')}, #{options[:singular_name]}], options)
          end

          def #{options[:singular_name]}_path(#{options[:singular_name]}, options = {})
            polymorphic_path([#{method_chain.join(', ')}, #{options[:singular_name]}], options)
          end

          def new_#{options[:singular_name]}_path(options = {})
            new_polymorphic_path([#{method_chain_with_anchor.join(', ')}, :#{options[:singular_name]}], options)
          end

          def #{options[:plural_name]}_path(options = {})
            polymorphic_path([#{method_chain_with_anchor.join(', ')}, :#{options[:plural_name]}], options)
          end
        }
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
