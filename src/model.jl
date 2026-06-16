# @rmq il ne faut pas trier les articles mais seulement les news => voir dans processingdata.jl
"""
    gethome(baseurl::String="")

Get data for the home page.

This function returns the data needed to build the home page.
If a single page with slug `__index` exists, it is returned as `:indexpage` in the content.
The 5 most recent articles are returned as news.
Metadata, and all articles and orphans (article not associated with a corpus) are also returned.

# Argument
- `baseurl`: Base URL for links (default "" for root (`/`) deployment)

# Return
A Dict with the following keys :
- `:meta`
- `:content` (includes `:news`, `:orphans`, `:articles`, and optionally `:indexpage`)
"""
function gethome(baseurl::String="")
  narticles = length(articles())
  news = narticles >= 5 ? articles()[1:5] : articles()

  metadata = meta()

  # Check if an __index single page exists
  pages = singlepages()
  indexidx = findfirst(p -> p[:label] == "__index", pages)

  content = Dict(
    :news => news,
    :article => ""
  )

  if !isnothing(indexidx)
    indexpage = pages[indexidx]
    content[:article] = indexpage
  end

  data = Dict(
    :meta => metadata,
    :content => content
  )

  return data
end

"""
    getcorpus(corpusname::String, baseurl::String="")

Get data for a specific corpus page.

This function returns the data needed for a given corpus page.
A `:breadcrumb` is added to the `:meta` for navigation.
In the `:content`, the corpus `:id`, `:name`, `:description` and the list of `:articles` are returned.

# Arguments
- `corpusname::String`: name of the corpus
- `baseurl`: Base URL for links (default "" for root deployment)

# Return
A `Dict()` with the following keys :
- `:meta`
- `:content`
"""
function getcorpus(corpusname::String, baseurl::String="")
  allcorpuses = corpuses()
  corpuspath = joinpath(baseurl, corpusname)
  matches = filter(c -> c[:path] == corpuspath, allcorpuses)

  if isempty(matches)
    metadata = meta()
    return Dict(
      :error => true,
      :message => "Corpus introuvable"
    )
  end

  corpus = matches[1]

  metadata = meta()
  metadata[:corpus] = Dict()
  metadata[:corpus][:path] = corpus[:path]
  metadata[:corpus][:name] = corpus[:name]

  metadata[:breadcrumb] = [
    Dict(:name => corpus[:name], :path => corpus[:path])
  ]

  data = Dict(
    :meta => metadata,
    :content => Dict(
      :id => corpus[:_id],
      :name => corpus[:name],
      :description => corpus[:description],
      :articles => corpus[:articles]
      #:articles => filter(a -> a[:corpus][:path] == corpuspath, articles())
    )
  )

  return data
end

# @rmq revoir les messages d'erreur, s'aligner sur ce qui est attendu
"""
    getarticlebyid(articleid::String, baseurl::String="")

Get data for a specific article.

This function returns the data for a given article (by its id) page.

# Arguments
- `articleid::String`: Article identifier
- `baseurl`: Base URL for links (default "" for root deployment)

# Return
A `Dict()` with the following keys :
- `:meta`
- `:content`
"""
function getarticlebyid(articleid::String, baseurl::String="")
  articles = workspace()[:articles]

  articleidx = findfirst(a -> a[:_id] == articleid, articles)

  if articleidx === nothing
    metadata = meta()
    return Dict(
      :error => true,
      :message => "Article introuvable"
    )
  end

  article = articles[articleidx]
  metadata = meta()
  breadcrumb = Dict( :name => article[:title], :path => article[:path] )
  metadata[:breadcrumb] = breadcrumb


  data = Dict(
    :meta => metadata,
    :content => article
  )

  return data
end

"""
    getarticle(corpusname::String, article::String, baseurl::String="")

Get data for a specific article.

This function returns the data for a given article (within a corpus) page.
The corpus metadatas are fetched and the breadcrumb trail is enriched with the article informations.

# Arguments
- `corpusname::String`: name of the corpus
- `article::String`: Article slug/identifier
- `baseurl`: Base URL for links (default "" for root deployment)

# Return
A `Dict()` with the following keys :
- `:meta`
- `:content`
"""
function getarticle(corpusname::String, article::String, baseurl::String="")
  corpus = getcorpus(corpusname, baseurl)

  list = articles()
  articleidx = findfirst(a -> a[:path] == joinpath(baseurl, corpusname, URIs.escapepath(article)), list)

  if articleidx === nothing
    metadata = meta()

    return Dict(
      :error => true,
      :message => "Article introuvable"
    )
  end

  article = list[articleidx]
  metadata = corpus[:meta]
  breadcrumb = Dict(:name => article[:title], :path => article[:path] )
  push!(metadata[:breadcrumb], breadcrumb)

  data = Dict(
    :meta => metadata,
    :content => article
  )

  return data
end

"""
    getsinglepage(slug::String, baseurl::String="")

Get data for a single page by its slug.

Single pages are special articles identified by a title starting with `__`.
They are not associated with any corpus but appear in the navigation menu.

# Arguments
- `slug::String`: Slug of the single page (e.g., "__bibliographie")
- `baseurl`: Base URL for links (default "" for root deployment)

# Return
A `Dict()` with the following keys :
- `:meta`
- `:content`
"""
function getsinglepage(slug::String, baseurl::String="")
  pages = singlepages()
  pageidx = findfirst(p -> p[:slug] == slug, pages)

  if pageidx === nothing
    metadata = meta()

    return Dict(
      :error => true,
      :message => "Page introuvable"
    )
  end

  page = pages[pageidx]
  metadata = meta()

  data = Dict(
    :meta => metadata,
    :content => page
  )

  return data
end

"""
    searchindex()

Generate a search index for Lunr.

This function builds a search index for all articles.
For each article, it extracts the essential fields (`:_id`, `:title`, `:corpus`,
markdown content (`:md`) and `:path`) needed for the Lunr search engine.

# Return
A `Dict()` with the following keys :
- `:_id`
- `:title`
- `:corpus`
- `:md`
- `:path`
"""
function searchindex()
  indexedarticles = []
  for article in articles()
    a = Dict(
      :_id => article[:_id],
      :title => article[:title],
      :corpus => article[:corpus],
      :md => article[:md],
      :path => article[:path]
    )

    push!(indexedarticles, a)
  end

  return indexedarticles
end

