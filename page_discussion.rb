# --- Show discussion about page ------------------------------------------------------
get "/pages/:id/discussion" do |id|

  page = Pages.first(:id => id, :deleted => false)

  if (page != nil)
    @page_title = page.name
    @title = recursive_category_names(page.parent)
    @page_name = page.name
    @id = id
    @threads = Page_comments.all(:parent => id, :root => true, :deleted => false, :order => [ :id.desc ]).collect
    erb :show_page_discussion
  else
    @page_title = "Stránka nenalezena!"
    erb :page_not_found
  end

end

# --- Add new thread to discussion form ------------------------------------------------------
get "/pages/:id/discussion/new_thread" do |id|

  page = Pages.first(:id => id, :deleted => false)

  if (page != nil)
    @page_id = id
    erb :new_page_discussion_thread_form
  else
    @page_title = "Stránka nenalezena!"
    erb :page_not_found
  end

end

# --- Add new thread to discussion ------------------------------------------------------
post "/add_new_thread_to_page_discussion" do

  page = Pages.first(:id => params['page_id'], :deleted => false)

  if (page != nil)

    # Sanitize given comment

    if (params['comment'] != nil)
      given_comment = params['comment'].to_s.gsub(/\\/, '\&\&').gsub(/[^']'[^']/, "''")
    end

    # Empty comment?
    if (given_comment == nil || given_comment == '')
      @page_id = params['page_id']
      @error = 'Komentář nesmí být prázdný!'
      return erb :new_page_discussion_thread_form
    end

    # Create comment

    new_comment = Page_comments.new
    new_comment.attributes = {
      :parent => params['page_id'],
      :root => true,
      :author => 0, #TODO - repair
      :create_time => DateTime.now,
      :text => given_comment,
      :deleted => false
    }

    new_comment.save

    # Redirect to parent category of created category
    redirect "/pages/#{params['page_id']}"

  else
    @page_title = "Stránka nenalezena!"
    erb :page_not_found
  end

end
