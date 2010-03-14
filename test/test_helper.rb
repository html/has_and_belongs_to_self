require 'rubygems'
require 'active_support'
require 'active_support/test_case'
require 'test/unit'
require 'shoulda'
require 'ruby-debug'
require 'rr'
require File.dirname(__FILE__) + '/../init.rb'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
old = $stdout
$stdout = StringIO.new

ActiveRecord::Base.logger
ActiveRecord::Schema.define(:version => 1) do
  create_table :test_table do |t|
    t.column :title, :string
  end

  create_table :test_table_relations, :id => false do |t|
    t.column :x_id, :integer
    t.column :y_id, :integer
  end
end


$stdout = old

class TestTable < ActiveRecord::Base
  set_table_name 'test_table'
  has_and_belongs_to_self
end

#class TestTableRelation < ActiveRecord::Base; end


class Test::Unit::TestCase
  include RR::Adapters::TestUnit

  def assert_table_name_equal(table, expected, &block)
    options_with_correct_table_name = satisfy {|arg| 
      expected.to_s == arg[:join_table].to_s
    }
    mock(table).has_and_belongs_to_many(anything, options_with_correct_table_name).twice
    stub.proxy(ActiveRecord::Reflection::AssociationReflection).new(anything, anything, options_with_correct_table_name, anything)
    mock(table).add_association_callbacks(anything, options_with_correct_table_name)
    block.call
  end
end
