require 'rubygems'
require 'sinatra'
require 'fileutils'
require 'bluecloth'
require 'data_mapper'

# --- Database storage ----------------------------------------------------------------

# Connect to the database
DataMapper.setup(:default, ENV['DATABASE_URL'] || 'mysql://kiwiwiki:kiwiwiki@db4free.net/kiwiwiki')

# Define tables
require 'db_schema.rb'

# --- Global functions ----------------------------------------------------------------

def recursive_category_names(parent_id) # creates a hypertext path to current category/page recursively
  if (parent_id.to_i <= 1)
    return ''
  else
    category = Categories.first(:id => parent_id)
    return recursive_category_names(category.parent) + '<a href="/categories/' + category.id.to_s + '">'+ category.name.to_s + '</a> − '
  end
end

# --- Homepage ----------------------------------------------------------------
get '/' do
  @page_title = 'Vítejte'
  @categories = Categories.all(:parent => 1, :deleted => false).collect
#  @pages = Pages.all(:parent => 1, :deleted => false).collect
  erb :homepage
end

# --- New category  ----------------------------------------------------------------
get '/new_category/:parent_id' do |parent_id|
  @page_title = 'Vytvořit novou kategorii'
  @parent_id = parent_id
  @error = ""
  erb :new_category_form
end

# --- New page ----------------------------------------------------------------
get '/new_page/:parent_id' do |parent_id|
  @page_title = 'Vytvořit novou stránku'
  @parent_id = parent_id
  @error = ""
  erb :new_page_form
end

# --- Create category -------------------------------------------------------------
post '/categories' do

  # Sanitize category name
  if (params['category_name'] != nil)
    category_name = params['category_name'].to_s.gsub(/\\/, '\&\&').gsub(/'/, "''")
  end

  # Empty title?
  if (category_name == nil || category_name == '')
    @page_title = 'Vytvořit novou kategorii'
    @parent_id = params['parent_id']
    @error = 'Jméno kategorie nesmí být prázdné!'
    return erb :new_category_form
  end

  # Create category
  new_category = Categories.new
  new_category.attributes = {
    :name => category_name,
    :parent => params['parent_id'],
    :deleted => false
  }

  new_category.save

  # Redirect to parent category of created category
  redirect "/categories/#{params['parent_id']}"
end

# --- Show category ---------------------------------------------------------------
get "/categories/:id" do |id|
  category = Categories.first(:id => id, :deleted => false)

  if (category != nil)
    @page_title = category.name
    @title = recursive_category_names(category.parent) + category.name
    @parent = category
    @categories = Categories.all(:parent => id, :deleted => false).collect
    @pages = Pages.all(:parent => id, :deleted => false).collect  
    erb :category
  else
    @page_title = "Category not found!"
    erb :category_not_found
  end
end

# --- Rename category form ---------------------------------------------------------------
get "/rename_category/:id" do |id|
  category = Categories.first(:id => id, :deleted => false)

  if (category != nil)
    @page_title = 'Přejmenovat kategorii'
    @id = category.id
    @current_name = category.name
    @error = ""
    erb :rename_category_form
  else
    @page_title = "Category not found!"
    erb :category_not_found
  end
end

# --- Rename category -------------------------------------------------------------
post '/rename_category' do

  # Sanitize category name
  if (params['category_name'] != nil)
    category_name = params['category_name'].to_s.gsub(/\\/, '\&\&').gsub(/'/, "''")
  end

  # Empty title?
  if (category_name == nil || category_name == '')
    @page_title = 'Přejmenovat kategorii'
    @id = params['id']
    @current_name = ''
    @error = 'Jméno kategorie nesmí být prázdné!'
    return erb :rename_category_form
  end

  # Rename category
  Categories.get(params['id']).update(:name => category_name)

  # Redirect to renamed category
  redirect "/categories/#{params['id']}"
end

# --- Create page -------------------------------------------------------------
post '/pages' do

  # Empty title?
  if params['title'].nil? || params['title'] == ''
    return erb :form
  end

  # Sanitize folder name (/, .)
  folder_name = params['title'].gsub( /(\\|\/)/, '' ).gsub(/\./, '_')

  puts "*** Creating page #{folder_name}"

  FileUtils.mkdir_p page_path(folder_name)

  File.open page_path(folder_name) + '/' + Time.now.to_i.to_s , 'w' do |file|
    file.write params['body']
  end

  redirect '/'
end

# --- Show page ---------------------------------------------------------------
get "/pages/:id" do |id|
  page = Pages.first(:id => id, :deleted => false)

  if (page != nil)
    @page_title = page.name
    @title = recursive_category_names(page.parent) + page.name
    @text = Page_revisions.first(:parent => page.id, :deleted => false, :order => [ :id.desc ]).text
    @revisions = Pages_revisions.all(:parent => page.id, :deleted => false).collect  
    erb :page
  else
    @page_title = "Page not found!"
    erb :page_not_found
  end
end

# --- Rename category form ---------------------------------------------------------------
get "/rename_category/:id" do |id|
  category = Categories.first(:id => id, :deleted => false)

  if (category != nil)
    @page_title = 'Přejmenovat kategorii'
    @id = category.id
    @current_name = category.name
    @error = ""
    erb :rename_category_form
  else
    @page_title = "Category not found!"
    erb :category_not_found
  end
end

# --- Rename category -------------------------------------------------------------
post '/rename_category' do

  # Sanitize category name
  if (params['category_name'] != nil)
    category_name = params['category_name'].to_s.gsub(/\\/, '\&\&').gsub(/'/, "''")
  end

  # Empty title?
  if (category_name == nil || category_name == '')
    @page_title = 'Přejmenovat kategorii'
    @id = params['id']
    @current_name = ''
    @error = 'Jméno kategorie nesmí být prázdné!'
    return erb :rename_category_form
  end

  # Rename category
  Categories.get(params['id']).update(:name => category_name)

  # Redirect to renamed category
  redirect "/categories/#{params['id']}"
end

# --- Edit page ---------------------------------------------------------------
get "/pages/edit/:title" do |title|
  @title = title
  @page_title = "Upravit stránku '#{@title}'"
  @body  = File.read page_path(title) + '/' + Dir.entries( page_path(title) ).last
  erb :form
end

# --- Show page revision ------------------------------------------------------
get "/pages/:title/revisions/:timestamp" do |title, timestamp|
  @title = title
  @page_title = "#{title} &mdash; revize z #{Time.at(timestamp.to_i).strftime('%d/%m/%Y %H:%M')}"
  content = File.read page_path(title) + '/' + timestamp
  @body = BlueCloth.new( content ).to_html
  @revisions = Dir.entries( page_path(title) ).reject { |file| file =~ /^\./ }
  erb :page
end

