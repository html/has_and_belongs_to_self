require 'test_helper'

class HasAndBelongsToSelfTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  context "ActiveRecord::Base" do
    should "have has_and_belongs_to_self method" do
      assert_respond_to ActiveRecord::Base, :has_and_belongs_to_self
    end

    should "have has_and_belongs_to_its" do
      assert_respond_to ActiveRecord::Base, :has_and_belongs_to_its
    end
    
    context "::has_and_belongs_to_self" do
      class TestTableX < ActiveRecord::Base; end

      should "accept hash_attributes" do
        assert_nothing_raised do 
          TestTableX.has_and_belongs_to_self :join_table => "test"
        end
      end

      should "accept association_id" do
        assert_nothing_raised do
          TestTableX.has_and_belongs_to_self :test
        end
      end

      should "accept association_id and hash_attributes" do
        assert_nothing_raised do
          TestTableX.has_and_belongs_to_self :test, :join_table => "test"
        end
      end
    end

    context "::has_and_belongs_to_its" do
      class TestTableY < ActiveRecord::Base; end

      should "error when association_id not specified" do
        assert_raise ArgumentError do
          TestTableY.has_and_belongs_to_its
        end
      end

      should "error when specified hash instead of association_id" do
        assert_raise TypeError do
          TestTableY.has_and_belongs_to_its :join_table => "test"
        end
      end

      should "not error when association_id specified" do
        assert_nothing_raised do
          TestTableY.has_and_belongs_to_its :friends
        end
      end
    end
  end

  context "Self-linking table" do

    context "relation table name" do
      should "consist of '<table_name>_relations' by default" do
        class TestTable2 < ActiveRecord::Base
          set_table_name 'test_table2'
        end

        assert_table_name_equal TestTable2, "test_table2_relations" do
          TestTable2.has_and_belongs_to_self
        end
      end

      should "consist of '<table_name>_<association_id>'" do
        class TestTable3 < ActiveRecord::Base
          set_table_name 'test_table3'
        end

        assert_table_name_equal TestTable3, "test_table3_friends" do
          TestTable3.has_and_belongs_to_self :friends
        end
      end

      should "be as set by :join_table parameter" do
        class TestTable4 < ActiveRecord::Base
          set_table_name 'test_table4'
        end

        assert_table_name_equal TestTable4, "test" do
          TestTable4.has_and_belongs_to_self :join_table => "test"
        end
      end
    end

    context "instance" do
      setup do
        @instance = TestTable.create!
        @instance2 = TestTable.create!
        @instance3 = TestTable.create!
      end

      should "have relations methods" do
        assert_respond_to @instance, :relations_x
        assert_respond_to @instance, :relations_y
        assert_respond_to @instance, :relations
      end

      should "have 1 relation" do
        @instance2 = TestTable.create!(:title => 'test')
        assert @instance.relations_x.empty?
        @instance.relations_x.push(@instance2)
        assert_equal 1, @instance.relations_x.size
        assert_equal @instance.relations_x.first, @instance2
        assert_equal @instance2.relations_y.first, @instance
      end

      should "have equal relations count and size" do
        @instance.relations << @instance2

        assert_equal 1, @instance.relations.count
        assert_equal @instance.relations.count, @instance.relations.size

        @instance.relations << @instance3

        assert_equal 2, @instance.relations.count
        assert_equal @instance.relations.count, @instance.relations.size
      end

      should "have 2 different relations" do
        #x relation to instance1
        @instance.relations << @instance2
        #y relation to instance1
        @instance3.relations << @instance

        assert_equal [@instance], @instance2.relations_y
        assert_equal [@instance], @instance3.relations_x
        assert_equal [@instance2, @instance3], @instance.relations
        assert !@instance2.relations.include?(@instance3)
        assert !@instance3.relations.include?(@instance2)
      end
    end

  end
end
