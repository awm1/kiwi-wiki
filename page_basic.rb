# --- New page ----------------------------------------------------------------
get '/pages/:parent_id/new' do |parent_id|
  @page_title = 'Vytvořit novou stránku'
  @parent_id = parent_id
  @error = ""
  erb :new_page_form
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
  redirect "/categories/#{params['parent_id']}"
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
