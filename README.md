DynamicAttributes
=================

Dynamic Attributes is a Rails plugin that lets you create dynamic attributes on
any ActiveRecord model, and saves them in a schema-less fashion within a single
table column.

Inspired by Friendly (http://friendlyorm.com/) and helped along with code from
http://github.com/browsermedia/browsercms/blob/master/lib/cms/behaviors/dynamic_attributes.rb


 - Grab the source code from Codaset at git://codaset.com/joelmoss/dynamic_attributes
 - Found a bug, or got a feature request? Create a ticket at http://codaset.com/joelmoss/dynamic_attributes/tickets
 - Or even better still, fork the source and commit it yourself, then ping me.


#### Get Started

So let's say that we have a model that we use to save data about our users. But
this data and the fields collected can change at any time, or are different
depending on the type of user.

Just tell your User model that it has dynamic attributes:

    User < ActiveRecord::Base
      has_dynamic_attributes
    end
  
Then create the migration for your User model (or simply add a new column):

    class CreateUsers < ActiveRecord::Migration
      def self.up
        create_table :users do |t|
          t.string :username
          t.text :dynamic_attributes
          t.timestamps!
        end
      end

      def self.down
        drop_table :users
      end
    end

So here we create a 'username' column which we will use as is for saving the users
username, and we have a column called 'dynamic_attributes'. This is where our
dynamic attributes will be saved in a nice little YAML structure.

Run the migration, and start up your Rails server.

Now we can create a new user record in the usual way:

    @user = User.new :username => 'joelmoss'
    @user.save
  
Nothing special there, but we can also create a new record with a bunch of
additional dynamic attributes.

    @user = User.new :username => 'joelmoss', :first_name => 'Joel', :last_name => 'Moss'
    @user.save

You can set as many dynamic attributes that you wish, and can call them anything
you want without the need to define them.

All of Rails usual ways of getting and setting model attributes are supported with
your dynamic attributes:

    @user = User.first
    @user.first_name
    => "Joel"
    @user.first_name = "Ashley"
    => "Ashley"
  
And if you want to see all your dynamic attributes, just call:

    @user.dynamic_attributes
    => { :first_name =>'Ashley', :last_name => 'Moss' }
  
Duh!


#### Secure your Dynamic Attributes

If you want to be really secure, then you can allow a set list of dynamic attributes,
and only those dynamic attributes will be allowed. Trying to set or get a dynamic
attribute that is not set, will raise the usual ActiveRecord exception.

    User < ActiveRecord::Base
      has_dynamic_attributes :first_name, :last_name
    end

If you don't specify a list of allowed dynamic attributes, then you can get and set
as many dynamic attributes as you wish.


#### Use a Different Table Column

Sometimes, you may not want to use the default column name 'dynamic_attributes'. For
example, you may want to use 'data' instead. So do this and your dynamic attributes
will be saved in the 'data' column:

    User < ActiveRecord::Base
      has_dynamic_attributes :column_name => :data
    end



Copyright (c) 2010 Joel Moss, released under the MIT license
