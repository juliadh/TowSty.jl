"""
    templaterender(templatepath::String, data::Dict)

Render a template with provided data and return an HTTP response.
Reads the template file, compiles it using Otera, and renders it with the given data.

* `templatepath::String`: Path to the template file
* `data::Dict`: Data to pass to the template
"""
function templaterender(templatepath::String, data::Dict)
  template = read(templatepath, String)
  render = otera(template)

  return Base.invokelatest(render, data)
end

"""
    templaterender_static(templatepath::String, data::Dict)

Render a template with provided data and return raw HTML string.
Similar to `templaterender` but extracts and returns the HTML content as a string
instead of an HTTP response, suitable for static site generation.

* `templatepath::String`: Path to the template file
* `data::Dict`: Data to pass to the template
"""
function templaterender_static(templatepath::String, data::Dict)
  template = read(templatepath, String)
  render = otera(template)
  html = Base.invokelatest(render, data)
  
  # Extraire le HTML si c'est une réponse HTTP
  if isa(html, HTTP.Messages.Response)
    return String(html.body)
  else
    return String(html)
  end
end

"""
    gethome()

Get data for the home page.
Retrieves all corpuses available in the system.
"""
function gethome()
  data = Dict(
    :meta => meta()
  )

  return data
end

"""
    getcorpus(corpusname::String)

Get data for a specific corpus page.
Retrieves corpus information and associated articles. If the corpus is not found,
returns an error structure.

* `corpusname::String`: Normalized name of the corpus
"""
function getcorpus(corpusname::String)
  allcorpuses = corpuses()
  matches = filter(c -> c[:path] == corpusname, allcorpuses)
  corpus = matches[1]

  if isempty(matches)
    return Dict(
      :error => true,
      :message => "Corpus introuvable",
      :workspacename => workspace()[:name],
      :corpuses => allcorpuses,
      :corpus => nothing,
      :articles => []
    )
  end

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
      :corpusname => corpus[:name],
      :id => corpus[:_id],
      :description => corpus[:description],
      :articles => filter(a -> a[:corpus][:path] == corpusname, articles())
    )
  )

  return data
end

"""
    getarticle(corpusname::String, article::String)

Get data for a specific article.
Retrieves and processes an article from a corpus, converting Markdown to HTML
with citations. If the article is not found, returns an error structure.

* `corpusname::String`: Normalized name of the corpus
* `article::String`: Article slug/identifier
"""
function getarticle(corpusname::String, article::String)
  corpus = getcorpus(corpusname)

  list = articles()
  articleidx = findfirst(a -> a[:path] == joinpath(corpusname, article), list)

  if articleidx === nothing
    return Dict(
      :error => true,
      :message => "Article introuvable",
      :corpuses => corpuses(),
      :content => Dict(:md => "", :bib => "")
    )
  end

  article = list[articleidx]
  metadata = corpus[:meta]
  breadcrumb = Dict(:name => article[:title], :path => article[:path] )
  push!(metadata[:breadcrumb], breadcrumb)


  data = Dict(
    :meta => meta(),
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
    getbibliography()

Get general bibliography
Retrieves and processes the general bibliography, converting Markdown to HTML
with citations.
"""
function getbibliography()
  bibliography = generalbibliography()
  data = Dict(
    :meta => meta(),
    :content => Dict(
      :id => bibliography[:_id],
      :title => bibliography[:title],
      :article => bibliography[:html]
    )
  )

  return data
end
