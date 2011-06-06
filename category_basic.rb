# --- New category  ----------------------------------------------------------------
get '/categories/:parent_id/new' do |parent_id|
  @page_title = 'Vytvořit novou kategorii'
  @parent_id = parent_id
  @error = ""
  erb :new_category_form
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
get "/categories/:id/rename" do |id|
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
