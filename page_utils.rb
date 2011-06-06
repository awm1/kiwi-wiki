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
