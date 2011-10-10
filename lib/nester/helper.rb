module Nester
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
