"""
    gethome(baseurl::String="")

Get data for the home page.
Retrieves all corpuses available in the system.

* `baseurl`: Base URL for links (default "" for root deployment)
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

"""
    getcorpus(corpusname::String, baseurl::String="")

Get data for a specific corpus page.
Retrieves corpus information and associated articles. If the corpus is not found,
returns an error structure.

* `corpusname::String`: Normalized name of the corpus
* `baseurl`: Base URL for links (default "" for root deployment)
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

"""
    getarticle(corpusname::String, article::String, baseurl::String="")

Get data for a specific article.
Retrieves and processes an article from a corpus, converting Markdown to HTML
with citations. If the article is not found, returns an error structure.

* `corpusname::String`: Normalized name of the corpus
* `article::String`: Article slug/identifier
* `baseurl`: Base URL for links (default "" for root deployment)
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
    #==:content => Dict(
      :id => article[:_id],
      :title => article[:title],
      :article => article[:html]
    )==#
  )

  return data
end

"""
    getbibliography(baseurl::String="")

Get general bibliography
Retrieves and processes the general bibliography, converting Markdown to HTML
with citations.

* `baseurl`: Base URL for links (default "" for root deployment)
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
