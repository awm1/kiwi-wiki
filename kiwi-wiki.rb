require 'rubygems'
require 'sinatra'
require 'fileutils'
require 'bluecloth'
require 'data_mapper'
require 'wikicloth'
require 'diffy'

# --- Database storage ----------------------------------------------------------------

# Connect to the database
# TODO - put back
#DataMapper.setup(:default, ENV['DATABASE_URL'] || 'mysql://kiwiwiki:kiwiwiki@db4free.net/kiwiwiki')
DataMapper.setup(:default, 'mysql://root:nemo451s@localhost/kiwiwiki')

# Define tables
require 'db_schema.rb'

# Include useful functions
require 'kiwi_utils.rb'

# Include authentification utils
require 'authentification.rb'

# Include basic category tool (add, show, rename, etc.)
require 'category_basic.rb'

# Include basic page tool (add, show, rename, etc.)
require 'page_basic.rb'

# Include additional page tool (show page history, compare two revisions of a page, etc.)
require 'page_utils.rb'

# Discussion about page support
require 'page_discussion.rb'

# --- Homepage ----------------------------------------------------------------
get '/' do
  @page_title = 'Vítejte'
  @categories = Categories.all(:parent => 1, :deleted => false).collect
#  @pages = Pages.all(:parent => 1, :deleted => false).collect
  erb :homepage
end
