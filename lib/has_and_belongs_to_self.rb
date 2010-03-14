# @author Olexiy Zamkoviy

require 'active_record'

ActiveRecord::Base.class_eval do

  def self.has_and_belongs_to_self(association_id_or_options = nil, options = {})
    if association_id_or_options.is_a?(Hash)
      options = association_id_or_options
      association_id = nil
    else
      association_id = association_id_or_options
    end

    association_id = association_id || 'relations'
    has_and_belongs_to_its(association_id, options)
  end

  def self.has_and_belongs_to_its(association_id , options = {})
    raise ArgumentError, "Association id not specified" unless association_id
    join_table = options[:join_table] || "#{self.table_name}_#{association_id}"

    has_and_belongs_to_many :relations_x,
      :class_name => to_s, 
      :foreign_key => :x_id, 
      :association_foreign_key => :y_id,
      :join_table => join_table
    has_and_belongs_to_many :relations_y,
      :class_name => to_s, 
      :foreign_key => :y_id, 
      :association_foreign_key => :x_id,
      :join_table => join_table

    options = {
      :class_name => to_s,
      :foreign_key => :x_id, 
      :association_foreign_key => :y_id,
      :join_table => join_table
    }

    reflection = ActiveRecord::Reflection::AssociationReflection.new(:has_and_belongs_to_self, association_id, options, self)
    write_inheritable_hash :reflections, association_id => reflection
    collection_accessor_methods(reflection, HasAndBelongsToSelfAssociation)
    add_association_callbacks(reflection.name, options)
  end

  class HasAndBelongsToSelfAssociation < ActiveRecord::Associations::HasAndBelongsToManyAssociation
    def construct_sql
      if @reflection.options[:finder_sql]
        @finder_sql = interpolate_sql(@reflection.options[:finder_sql])
      else
        @finder_sql = "#{@owner.connection.quote_table_name @reflection.options[:join_table]}.#{@reflection.primary_key_name} = #{owner_quoted_id} OR #{@owner.connection.quote_table_name @reflection.options[:join_table]}.#{@reflection.association_foreign_key} = #{owner_quoted_id}"
        @finder_sql << " AND (#{conditions})" if conditions
      end

      @join_sql = "INNER JOIN #{@owner.connection.quote_table_name @reflection.options[:join_table]} ON (#{@reflection.quoted_table_name}.#{@reflection.klass.primary_key} = #{@owner.connection.quote_table_name @reflection.options[:join_table]}.#{@reflection.association_foreign_key} OR  #{@reflection.quoted_table_name}.#{@reflection.klass.primary_key} = #{@owner.connection.quote_table_name @reflection.options[:join_table]}.#{@reflection.options[:foreign_key]}) AND #{@reflection.quoted_table_name}.#{@reflection.klass.primary_key} != #{owner_quoted_id}"

      if @reflection.options[:counter_sql]
        @counter_sql = interpolate_sql(@reflection.options[:counter_sql])
      elsif @reflection.options[:finder_sql]
        # replace the SELECT clause with COUNT(*), preserving any hints within /* ... */
        @reflection.options[:counter_sql] = @reflection.options[:finder_sql].sub(/SELECT (\/\*.*?\*\/ )?(.*)\bFROM\b/im) { "SELECT #{$1}COUNT(*) FROM" }
        @counter_sql = interpolate_sql(@reflection.options[:counter_sql])
      else
        @counter_sql = @finder_sql
      end
    end
  end
end
