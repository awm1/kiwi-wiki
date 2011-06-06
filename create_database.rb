require 'rubygems'
require 'data_mapper'

# Connect to the database
# TODO - put back
#DataMapper.setup(:default, ENV['DATABASE_URL'] || 'mysql://kiwiwiki:kiwiwiki@db4free.net/kiwiwiki')
DataMapper.setup(:default, 'mysql://root:nemo451s@localhost/kiwiwiki')

# Define tables
require 'db_schema.rb'

# Automatically create the tables if they don't exist
DataMapper.auto_migrate!

# Define root category...
root = Categories.new
root.attributes = {
  :id => 1,
  :name => 'ROOT',
  :parent => 0,
  :deleted => false
}

# ...and save it to the database
root.save

#TODO - remove

# Define some test categories...
category1 = Categories.new
category1.attributes = {
  :id => 2,
  :name => 'Test',
  :parent => 1,
  :deleted => false
}

# ...and save it to the database
category1.save

# Define some test pages...
page1 = Pages.new
page1.attributes = {
  :id => 1,
  :name => 'TestPage',
  :parent => 2,
  :deleted => false,
  :current_revision => 1
}

# ...and save it to the database
page1.save

# Define some test page revisions...
pagerev1 = Page_revisions.new
pagerev1.attributes = {
  :id => 1,
  :parent => 1,
  :create_time => DateTime.now,
  :text => "test text"
}

# ...and save it to the database
pagerev1.save
