require File.dirname(__FILE__) + '/test_helper.rb'

class DynamicAttributesTest < ActiveSupport::TestCase

  def setup
    create_model :UserAttributeWithNamedColumn do      
      with_columns do |t|
        t.string :name
        t.text :data
      end
      
      has_dynamic_attributes :column_name => :data
    end

    create_model :UserAttributeWithNamedField do
      with_columns do |t|
        t.string :name
        t.text :dynamic_attributes
      end

      has_dynamic_attributes :about, 'age', :middle_name
    end

    create_model :UserAttribute do
      with_columns do |t|
        t.string :name
        t.text :dynamic_attributes
      end

      has_dynamic_attributes
    end
  end

  test "return exception if database field does not exist" do
    assert_raises(DynamicAttributes::UndefinedTableColumn) do
      create_model(:UserAttributeWithoutDefaultColumn) { has_dynamic_attributes }
    end
  end
  
  test "dynamic_attributes is created with an empty array" do
    assert_equal [], UserAttribute.dynamic_attributes_fields
  end
  
  test "the default database column name should be dynamic_attributes" do
    assert_equal :dynamic_attributes, UserAttribute.dynamic_attributes_options[:column_name]
  end
  
  test "the database column name when passed as option" do
    assert_equal :data, UserAttributeWithNamedColumn.dynamic_attributes_options[:column_name]
  end
  
  test "dynamic_attributes is created with an array of allowed attributes" do
    assert_equal [:about, :age, :middle_name], UserAttributeWithNamedField.dynamic_attributes_fields
  end
  
  test "read dynamic attributes before being set" do
    user = UserAttribute.new :name => 'Joel Moss'
    assert_nil user.home_town
  end
  
  test "write dynamic attributes when fields are defined" do
    user = UserAttributeWithNamedField.new :name => 'Joel Moss'
    user.about = 'stuff about me'
    assert_equal('stuff about me', user.about)
    assert_raises(NoMethodError) do
      user.address = 'My address'
    end
  end
  
  test "create dynamic attributes via a hash" do
    UserAttribute.create :name => 'Joel Moss', :dynamic_attributes => { :age => 33, :home_town => 'Chorley' }
    assert_equal({ :age => 33, :home_town => 'Chorley' }, UserAttribute.first.dynamic_attributes)
  end
  
  test "create dynamic attributes via method names" do
    user = UserAttribute.new :name => 'Joel Moss'
    user.home_town = 'Chorley'
    assert_equal 'Chorley', user.home_town
    user.save
    assert_equal 'Chorley', UserAttribute.last.home_town
    assert_equal({:home_town => 'Chorley'}, UserAttribute.last.dynamic_attributes)
  end
  
  test "initialize dynamic attributes via hash" do
    user = UserAttribute.new :name => 'Joel Moss', :home_town => "Chorley"
    assert_equal user.home_town, 'Chorley'
    user.save
    user = UserAttribute.last
    assert_equal('Chorley', user.home_town)
    assert_equal({:home_town => 'Chorley'}, user.dynamic_attributes)
  end
  
end
