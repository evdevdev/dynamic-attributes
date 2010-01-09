module DynamicAttributes

  class UndefinedTableColumn < StandardError; end

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

    def has_dynamic_attributes(*attrs)
      include InstanceMethods
      
      cattr_accessor :dynamic_attributes_options, :dynamic_attributes_fields
      
      self.dynamic_attributes_options = attrs.extract_options!
      self.dynamic_attributes_options[:column_name] ||= :dynamic_attributes
      self.dynamic_attributes_options[:column_name].to_sym

      raise UndefinedTableColumn unless column_names.include? self.dynamic_attributes_options[:column_name].to_s
      
      self.dynamic_attributes_fields = attrs.map { |attr| attr.to_sym }
      
      define_method(self.dynamic_attributes_options[:column_name]) {
        attrs = read_attribute_without_dynamic_attributes self.dynamic_attributes_options[:column_name]
        attrs.nil? ? nil : YAML.load(attrs).symbolize_keys!
      }
      
      class_eval do
        unless method_defined? :method_missing_without_dynamic_attributes
          # Carry out delayed actions before save
          before_save :build_dynamic_attributes
        
          # Make attributes seem real
          alias_method_chain :method_missing, :dynamic_attributes
              
          private
              
          alias_method_chain :read_attribute, :dynamic_attributes
          alias_method_chain :write_attribute, :dynamic_attributes
        end
      end
    end
    
  end

  module InstanceMethods
          
    # Determines if the given attribute is a dynamic attribute.
    def is_dynamic_attribute?(attr)
      return dynamic_attributes_fields.include?(attr.to_sym) unless dynamic_attributes_fields.empty?
      return false if self.class.column_names.include?(attr.to_s)
      true
    end
    
    # This overrides the attributes= defined in ActiveRecord::Base
    # The only difference is that this doesn't check to see if the
    # model responds_to the method before sending it
    def attributes=(new_attributes, guard_protected_attributes = true)
      return if new_attributes.nil?
      attributes = new_attributes.dup
      attributes.stringify_keys!

      multi_parameter_attributes = []
      attributes = remove_attributes_protected_from_mass_assignment(attributes) if guard_protected_attributes

      attributes.each do |k, v|
        if k.include?("(")
          multi_parameter_attributes << [ k, v ]
        else
          send(:"#{k}=", v)
        end
      end

      assign_multiparameter_attributes(multi_parameter_attributes)
    end

    private
    
      # We override this so we can include our defined dynamic attributes
      def attributes_from_column_definition
        unless dynamic_attributes_fields.empty?
          attributes = dynamic_attributes_fields.inject({}) do |attributes, column|
            attributes[column.to_s] = nil
            attributes
          end
        end

        self.class.columns.inject(attributes || {}) do |attributes, column|
          attributes[column.name] = column.default unless column.name == self.class.primary_key
          attributes
        end
      end
    
      # Called after validation on update so that dynamic attributes behave
      # like normal attributes in the fact that the database is not touched
      # until save is called.
      def build_dynamic_attributes
        return if @save_dynamic_attr.nil?
        write_attribute_without_dynamic_attributes dynamic_attributes_options[:column_name], @save_dynamic_attr
        @save_dynamic_attr = {}
        true
      end
    
      # Implements dynamic-attributes as if real getter/setter methods
      # were defined.
      def method_missing_with_dynamic_attributes(method_id, *args, &block)
        begin
          method_missing_without_dynamic_attributes method_id, *args, &block
        rescue NoMethodError => e
          attr_name = method_id.to_s.sub(/\=$/, '')
          if is_dynamic_attribute?(attr_name)
            if method_id.to_s =~ /\=$/
              return write_attribute_with_dynamic_attributes(attr_name, args[0])
            else
              return read_attribute_with_dynamic_attributes(attr_name)
            end
          end
          raise e
        end
      end

      # Overrides ActiveRecord::Base#read_attribute
      def read_attribute_with_dynamic_attributes(attr_name)
        attr_name = attr_name.to_s
        if is_dynamic_attribute?(attr_name)
          if !@save_dynamic_attr.blank? and @save_dynamic_attr[attr_name]
            return @save_dynamic_attr[attr_name]
          else
            attrs = read_attribute_without_dynamic_attributes(dynamic_attributes_options[:column_name].to_s)
            attrs = attrs.nil? ? nil : YAML.load(attrs).symbolize_keys! unless attrs.is_a? Hash
            return nil if attrs.blank?
            return attrs[attr_name.to_sym]
          end
        end
        
        read_attribute_without_dynamic_attributes(attr_name)
      end

      # Overrides ActiveRecord::Base#write_attribute
      def write_attribute_with_dynamic_attributes(attr_name, value)
        if is_dynamic_attribute?(attr_name)
          attr_name = attr_name.to_s
          @save_dynamic_attr ||= {}
          return @save_dynamic_attr[attr_name] = value
        end
        
        write_attribute_without_dynamic_attributes(attr_name, value)
      end
    
  end

end

ActiveRecord::Base.send :include, DynamicAttributes