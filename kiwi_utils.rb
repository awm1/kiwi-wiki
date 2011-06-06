# --- Global functions ----------------------------------------------------------------

def recursive_category_names(parent_id) # creates a hypertext path to current category/page recursively
  if (parent_id.to_i <= 1)
    return ''
  else
    category = Categories.first(:id => parent_id)
    return recursive_category_names(category.parent) + '<a href="/categories/' + category.id.to_s + '">'+ category.name.to_s + '</a> − '
  end
end

def wiki_syntax_to_html(source) # converts given source string in WikiMedia syntax to HTML
  wiki = WikiCloth::Parser.new({
    :data => source,
    :params => { }
  })
  return wiki.to_html( :noedit => true )
end
