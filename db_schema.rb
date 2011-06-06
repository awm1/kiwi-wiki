# Define tables

class Categories
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :required => true
  property :parent, Integer, :required => true
  property :deleted, Boolean, :default  => false
end


class Pages
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :required => true
  property :parent, Integer, :required => true
  property :deleted, Boolean, :default  => false
  property :current_revision, Integer, :required => true
end

class Page_revisions
  include DataMapper::Resource

  property :id, Serial
  property :parent, Integer, :required => true
  property :create_time, DateTime, :required => true
  property :text, Text
  property :comment, Text
end

class Page_comments
  include DataMapper::Resource

  property :id, Serial
  property :parent, Integer, :required => true
  property :root, Boolean, :default  => false
  property :author, Integer, :required => true
  property :create_time, DateTime, :required => true
  property :text, Text
  property :deleted, Boolean, :default  => false
end

class Users
  include DataMapper::Resource

  property :id, Serial
  property :username, String, :required => true
  property :password, String, :required => true
  property :real_name, String, :required => true
  property :email, String, :required => true
  property :www, String
end
