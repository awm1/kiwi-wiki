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

# --- Homepage ----------------------------------------------------------------
get '/' do
  @page_title = 'Vítejte'
  @categories = Categories.all(:parent => 1, :deleted => false).collect
#  @pages = Pages.all(:parent => 1, :deleted => false).collect
  erb :homepage
end

# --- New category  ----------------------------------------------------------------
get '/categories/:parent_id/new' do |parent_id|
  @page_title = 'Vytvořit novou kategorii'
  @parent_id = parent_id
  @error = ""
  erb :new_category_form
end

# --- New page ----------------------------------------------------------------
get '/pages/:parent_id/new' do |parent_id|
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

  if (category != nil && category.id.to_i > 1)
    @page_title = category.name
    @title = recursive_category_names(category.parent) + category.name
    @parent = category
    @categories = Categories.all(:parent => id, :deleted => false).collect
    @pages = Pages.all(:parent => id, :deleted => false).collect  
    erb :category
  else
    @page_title = "Kategorie nenalezena!"
    erb :category_not_found
  end
end

# --- Rename category form ---------------------------------------------------------------
get "/category/:id/rename" do |id|
  category = Categories.first(:id => id, :deleted => false)

  if (category != nil)
    @page_title = 'Přejmenovat kategorii'
    @id = category.id
    @current_name = category.name
    @error = ""
    erb :rename_category_form
  else
    @page_title = "Kategorie nenalezena!"
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

  # Sanitize page name
  if (params['page_name'] != nil)
    page_name = params['page_name'].to_s.gsub(/\\/, '\&\&').gsub(/'/, "''")
  end

  # Empty title?
  if (page_name == nil || page_name == '')
    @page_title = 'Vytvořit novou stránku'
    @parent_id = params['parent_id']
    @error = 'Jméno stránky nesmí být prázdné!'
    return erb :new_page_form
  end

  # Create page
  new_page = Pages.new
  new_page.attributes = {
    :name => page_name,
    :parent => params['parent_id'],
    :deleted => false,
    :current_revision => 0
  }

  new_page.save

  # Sanitize given text
  if (params['text'] != nil)
    new_text = params['text'].to_s.gsub(/\\/, '\&\&').gsub(/[^']'[^']/, "''")
  end

  if (params['comment'] != nil)
    given_comment = params['comment'].to_s.gsub(/\\/, '\&\&').gsub(/[^']'[^']/, "''")
  end

  # Create first revision of created page

  new_page_revision = Page_revisions.new
  new_page_revision.attributes = {
    :parent => new_page.id,
    :create_time => DateTime.now,
    :text => new_text,
    :comment => given_comment
  }

  new_page_revision.save

  # Connect this revision to the page
  Pages.first( :id => new_page_revision.parent).update( :current_revision => new_page_revision.id )

  # Redirect to parent category of created category
  redirect "/pages/#{params['parent_id']}"
end


# --- Show page ---------------------------------------------------------------
get "/pages/:id" do |id|
  page = Pages.first(:id => id, :deleted => false)

  if (page != nil)
    @page_title = page.name
    @title = recursive_category_names(page.parent)
    @page_name = page.name
    @page = page
    @current_revision = page.current_revision.to_i
    @text = wiki_syntax_to_html(Page_revisions.first(:id => page.current_revision.to_i).text)
    erb :page
  else
    @page_title = "Stránka nenalezena!"
    erb :page_not_found
  end
end

# --- Rename page form ---------------------------------------------------------------
get "/pages/:id/rename" do |id|
  page = Pages.first(:id => id, :deleted => false)

  if (page != nil)
    @page_title = 'Přejmenovat stránku'
    @id = page.id
    @current_name = page.name
    @error = ""
    erb :rename_page_form
  else
    @page_title = "Stránka nenalezena!"
    erb :page_not_found
  end
end

# --- Rename page -------------------------------------------------------------
post '/rename_page' do

  # Sanitize page name
  if (params['page_name'] != nil)
    page_name = params['page_name'].to_s.gsub(/\\/, '\&\&').gsub(/'/, "''")
  end

  # Empty title?
  if (page_name == nil || page_name == '')
    @page_title = 'Přejmenovat kategorii'
    @id = params['id']
    @current_name = ''
    @error = 'Jméno stránky nesmí být prázdné!'
    return erb :rename_page_form
  end

  # Rename page
  Pages.get(params['id']).update(:name => page_name)

  # Redirect to renamed page
  redirect "/pages/#{params['id']}"
end

# --- Edit page form ---------------------------------------------------------------
get "/pages/:id/edit" do |id|
  page = Pages.first(:id => id, :deleted => false)

  if (page != nil)
    @page_title = 'Upravit stránku | ' + page.name
    @id = page.id
    @page_name = page.name
    @old_text = Page_revisions.first( :id => page.current_revision).text
    erb :edit_page_form
  else
    @page_title = "Stránka nenalezena!"
    erb :page_not_found
  end
end

# --- Edit page ---------------------------------------------------------------
post "/edit_page" do

  # Sanitize given text
  if (params['text'] != nil)
    new_text = params['text'].to_s.gsub(/\\/, '\&\&').gsub(/[^']'[^']/, "''")
  end

  if (params['comment'] != nil)
    given_comment = params['comment'].to_s.gsub(/\\/, '\&\&').gsub(/[^']'[^']/, "''")
  end

  # Create new revision of page
  new_page_revision = Page_revisions.new
  new_page_revision.attributes = {
    :parent => params['id'].to_i,
    :create_time => DateTime.now,
    :text => new_text,
    :comment => given_comment
  }

  new_page_revision.save

  # Connect this revision to the page
  Pages.first( :id => params['id'].to_i).update( :current_revision => new_page_revision.id )

  # Redirect to renamed page
  redirect "/pages/#{params['id']}"

end

# --- Show history of page revisions ------------------------------------------------------
get "/pages/:id/history" do |id|

  page = Pages.first(:id => id, :deleted => false)

  if (page != nil)
    @page_title = page.name
    @title = recursive_category_names(page.parent)
    @page_name = page.name
    @id = id
    @current_revision = page.current_revision.to_i
    @revisions = Page_revisions.all(:parent => page.id, :order => [ :id.desc ]).collect
    erb :show_page_history
  else
    @page_title = "Stránka nenalezena!"
    erb :page_not_found
  end

end

# --- Compare two page revisions form ------------------------------------------------------
get "/pages/:id/history/compare" do |id|

  page = Pages.first(:id => id, :deleted => false)

  if (page != nil)
    @page_title = page.name
    @title = recursive_category_names(page.parent)
    @page_name = page.name
    @id = id
    @current_revision = page.current_revision.to_i
    @revisions = Page_revisions.all(:parent => page.id, :order => [ :id.desc ]).collect
    erb :compare_page_revisions_form
  else
    @page_title = "Stránka nenalezena!"
    erb :page_not_found
  end

end

# --- Compare two page revisions form ------------------------------------------------------
post "/compare_page_revisions" do

  page = Pages.first(:id => params['id'], :deleted => false)

  if (page != nil)
    @page_title = page.name
    @title = recursive_category_names(page.parent)
    @page_name = page.name
    @id = id
    first_revision = Page_revisions.first(:id => params['first'].to_i).text
    @first_revision = first_revision
    second_revision = Page_revisions.first(:id => params['second'].to_i).text
    @second_revision = second_revision
    @diff = Diffy::Diff.new(first_revision, second_revision)
    erb :compare_page_revisions
  else
    @page_title = "Stránka nenalezena!"
    erb :page_not_found
  end

end

# --- Show revision of a page ---------------------------------------------------------------
get "/pages/:id/revision/:revision" do |id,revision|
  page = Pages.first(:id => id, :deleted => false)

  if (page != nil)
    @page_title = page.name
    @title = recursive_category_names(page.parent)
    @page_name = page.name
    @id = id
    @revision = revision

    if (page.current_revision.to_i == revision.to_i)
    	@is_current = true
    else
    	@is_current = false
    end

    @text = wiki_syntax_to_html(Page_revisions.first(:id => revision.to_i).text)
    erb :show_page_revision
  else
    @page_title = "Stránka nenalezena!"
    erb :page_not_found
  end
end

# --- Show author comment to revision of a page ---------------------------------------------------------------
get "/pages/:id/revision/:revision/comment" do |id,revision|
  page = Pages.first(:id => id, :deleted => false)

  if (page != nil)
    @page_title = page.name
    @title = recursive_category_names(page.parent)
    @page_name = page.name
    @id = id

    @text = wiki_syntax_to_html(Page_revisions.first(:id => revision.to_i).comment)
    erb :show_page_revision_comment
  else
    @page_title = "Stránka nenalezena!"
    erb :page_not_found
  end
end

# --- Mark page as current ---------------------------------------------------------------
post "/pages/revision" do

  # Select given revision as current
  Pages.first( :id => params['id'].to_i).update( :current_revision => params['revision'].to_i )

  # Redirect to revided page
  redirect "/pages/#{params['id']}"

end

# Discussion about page support
require 'page_discussion.rb'
