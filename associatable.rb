require_relative 'searchable'
require 'active_support/inflector'

class AssocOptions 
   attr_accessor(
      :foreign_key,
      :class_name,
      :primary_key
   )

   def model_class 
      @class_name.constantize
   end 

   def table_name 
      model_class.table_name
   end 

end 

class BelongsToOptions < AssocOptions 
   def initialize(name, options = {})

      defaults = {
         :foreign_key => "#{name}_id".to_sym,
         :class_name => name.to_s.camelcase,
         :primary_key => :id
      }

      defaults.keys.each do |key| 
         self.send("#{key}=", options[key] || defaults[key])
      end  
   end 

end 

class HasManyOptions < AssocOptions 
   def initialize(name, self_class_name, options = {})
      defaults = {
         :foreign_key => "#{self_class_name.underscore}_id".to_sym,
         :class_name => name.to_s.singularize.camelcase,
         :primary_key => :id
      }

      defaults.keys.each do |key|
         self.send("#{key}=", options[key] || defaults[key])
      end 
   end 
end 

module Associatable 
   
   def belongs_to(name, options = {})
      self.assoc_options[name] = BelongsToOptions.new(name, options)

      define_method(name) do 
         options = self.class.assoc_options[name]
         value = self.send(options.foreign_key)
         options.model_class.where(options.primary_key => value).first
      end
   end
   
   def has_many(name, options = {})
      self.assoc_options[name] = HasManyOptions.new(name, self.name, options)

      define_method(name) do 
         options = self.class.assoc_options[name]
         value = self.send(options.primary_key)
         options.model_class.where(options.foreign_key => value)
      end
   end

   def assoc_options 
      @assoc_options ||= {}
      @assoc_options 
   end

end


class SQLObject
   extend Associatable
end 

module Associatable
   def has_one_through(name, through_name, source_name)
      define_method(name) do 
         through_options = self.class.assoc_options[through_name]
         source_options = 
            through_options.model_class.assoc_options[source_name]
         
         through_table = through_options.table_name 
         through_prim_key = through_options.primary_key
         through_for_key = through_options.foreign_key

         source_table = source_options.table_name



