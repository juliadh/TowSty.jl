# @rmq il ne faut pas trier les articles mais seulement les news => voir dans processingdata.jl
"""
    gethome(baseurl::String="")

Get data for the home page.

# Argument
- `baseurl`: Base URL for links (default "" for root (`/`) deployment)

# Return
A Dict with the following keys :
- `:meta`
- `:content`
"""
function gethome(baseurl::String="")
  narticles = length(articles())
  news = narticles >= 5 ? articles()[1:5] : articles()

  metadata = meta()
  metadata[:baseurl] = baseurl

  data = Dict(
    :meta => metadata,
    :content => Dict(
      :news => news,
      :orphans => orphans(),
      :articles => articles()
    )
  )

  return data
end

# @rmq revoir les messages d'erreur, s'aligner sur ce qui est attendu
"""
    getcorpus(corpusname::String, baseurl::String="")

Get data for a specific corpus page.
Retrieves corpus informations and associated articles. If the corpus is not found,
returns an error message.

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
  matches = filter(c -> c[:path] == corpusname, allcorpuses)
  corpus = matches[1]

  if isempty(matches)
    metadata = meta()
    metadata[:baseurl] = baseurl

    return Dict(
      :error => true,
      :message => "Corpus introuvable",
      :meta => metadata,
      :workspacename => workspace()[:name],
      :corpuses => allcorpuses,
      :corpus => nothing,
      :articles => []
    )
  end

  metadata = meta()
  metadata[:baseurl] = baseurl
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
      :articles => filter(a -> a[:corpus][:path] == corpusname, articles())
    )
  )

  return data
end

# @rmq revoir les messages d'erreur, s'aligner sur ce qui est attendu
"""
    getarticle(corpusname::String, article::String, baseurl::String="")

Get data for a specific article.
Retrieves an article from a corpus.
If the article is not found, returns an error message.

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
  articleidx = findfirst(a -> a[:path] == joinpath(corpusname, URIs.escapepath(article)), list)

  if articleidx === nothing
    metadata = meta()
    metadata[:baseurl] = baseurl

    return Dict(
      :error => true,
      :message => "Article introuvable",
      :meta => metadata,
      :corpuses => corpuses(),
      :content => Dict(:md => "", :bib => "")
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
    getbibliography(baseurl::String="")

Get general bibliography.
Retrieves the general bibliography article.

# Argument
- `baseurl`: Base URL for links (default "" for root deployment)

# Return
A `Dict()` with the following keys :
- `:meta`
- `:content`
"""
function getbibliography(baseurl::String="")
  bibliography = generalbibliography()

  metadata = meta()
  metadata[:baseurl] = baseurl

  data = Dict(
    :meta => metadata,
    :content => Dict(
      :id => bibliography[:_id],
      :title => bibliography[:title],
      :html => bibliography[:html]
    )
  )

  return data
end

"""
    searchindex()

Generate a search index for Lunr.

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
      :_id => article[:_id],
      :title => article[:title],
      :corpus => article[:corpus],
      :md => article[:md],
      :path => article[:path]
    )

    push!(indexedarticles, a)
  end

  return indexedarticles
end

