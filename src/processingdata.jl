"""
    loadsources()

This function loads the `workspace.json` file.

# Return
`workspace.json` as a `Dict()`
"""
function loadsources()
  workspacedata = JSON.parsefile(DATA_PATH) |> string2symbol
  return workspacedata
end

"""
    processdata(workspace::Dict)

This function is a wrapper to process the data from a workspace.

# Argument
- `workspace::Dict`

# Return
A Dict with the following keys :
- `:workspace` - The complete workspace data
- `:corpuses` - Processed corpus data
- `:articles` - Sorted list of all articles
- `:orphans` - Articles not associated with any corpus (and not single pages)
- `:singlepages` - Single pages (articles with title starting with `__`)
- `:meta` - Workspace metadata including navigation
"""
function processdata(workspace::Dict{Symbol, Any}, baseurl::String)
  logmessage = "[workspace] $(workspace[:name])"
  PROCESS_LOG[] = String[]
  push!(PROCESS_LOG[], logmessage)
  println(logmessage)

  corpuses = [processcorpus(corpus, baseurl) for corpus in workspace[:corpus]]

  articles = Vector{Dict{Symbol, Any}}()
  for c in corpuses
    append!(articles, c[:articles])
  end

  articleids = [article[:_id] for article in articles]

  remainingarticles = filter(a -> !in(a[:_id], articleids), workspace[:articles])

  singlepages = filter(a -> startswith(a[:title], "__"), remainingarticles)
  orphans = filter(a -> !startswith(a[:title], "__"), remainingarticles)

  logmessage = "  [single pages]"
  push!(PROCESS_LOG[], logmessage)
  println(logmessage)
  processedsingle = filter(!isnothing, [processarticle(Dict(:article => s), Dict(:path => "", :name => "")) for s in singlepages])

  logmessage = "  [orphans]"
  push!(PROCESS_LOG[], logmessage)
  println(logmessage)
  processorphans = filter(!isnothing, [processarticle(Dict(:article => o), Dict(:path => "", :name => "")) for o in orphans])

  sorted = sort(articles, by = x -> x[:createdAt], rev=true)

  workspace[:articles] = vcat(processorphans, processedsingle, articles)

  singlepagesnav = [
    Dict(:name => s[:title], :path => s[:slug]) 
    for s in processedsingle if s[:label] != "__index"
  ]

  return Dict(
    :workspace => workspace,
    :corpuses => corpuses,
    :orphans => processorphans,
    :singlepages => processedsingle,
    :articles => sorted,
    :meta => Dict(
      :workspacename => workspace[:name],
      :baseurl => baseurl,
      :nav => vcat(
        [Dict(:name => c[:name], :path => formatpath(c[:path])) for c in corpuses],
        singlepagesnav
      )
    )
  )
end

"""
    processcorpus(corpus::Dict)

Wrapper to process the data from a corpus.

# Argument
- `corpus::Dict`: the corpus data to process

# Return
A processed corpus Dict
"""
function processcorpus(corpus::Dict{Symbol, Any}, baseurl::String)
  logmessage = "  [corpus] $(corpus[:name])"
  push!(PROCESS_LOG[], logmessage)
  println(logmessage)

  corpusinfo = Dict(
    :name => corpus[:name],
    :path => joinpath(baseurl, formatpath(corpus[:name]) )
  )

  corpus[:path] = joinpath(baseurl, formatpath(corpus[:name]) )
  corpus[:articles] = isempty(corpus[:articles]) ? [] : processarticles(corpus[:articles], corpusinfo)
  corpus[:description] = markdowntohtml(corpus[:description])

  return corpus
end

"""
    processarticles(articles::Vector, corpusinfo::Dict)

Process an array of articles from a corpus.

# Arguments
- `articles`: an array of articles (Dict) from a stylo corpus.
- `corpusinfo::Dict`: the `:name` and `:path` of the corpus.

# Return
A Vector of formatted articles
"""
function processarticles(articles::Vector{Dict{Symbol, Dict{Symbol, Any}}}, corpusinfo::Dict{Symbol, String})
  logmessage = "    [articles] $(length(articles)) article(s)"
  push!(PROCESS_LOG[], logmessage)
  println(logmessage)

  formattedarticles = filter(!isnothing, [processarticle(article, corpusinfo) for article in articles])

  return formattedarticles
end

"""
    processarticle(article::Dict, corpusinfo::Dict)

Process an article.
Converts markdown content to html and processes metadata (yaml header, path, slug, etc.)

# Arguments
- `article::Dict`: a Dict containing the article.
- `corpusinfo::Dict`: the `:name` and `:path` of the corpus.

# Return
A formatted article Dict
"""
function processarticle(article::Dict{Symbol, Dict{Symbol, Any}}, corpusinfo::Dict{Symbol, String})
  logmessage = "      [article] $(article[:article][:_id]) - $(article[:article][:title])"
  push!(PROCESS_LOG[], logmessage)
  println(logmessage)

  articledata = article[:article]

  yaml = getyamlheader(articledata[:workingVersion][:md])
  yaml = isnothing(yaml) ? Dict() : string2symbol(yaml) # when no yaml header

  label = articledata[:title]
  rawtitle = get(yaml, :title, label)

  html = try
    Dict(:md => articledata[:workingVersion][:md], :bib => articledata[:workingVersion][:bib]) |> markdowntohtml
  catch e
    @warn "Erreur lors de la convertion Pandoc, l’article ($(articledata[:_id])) est ignoré" exception=e
    push!(PROCESS_LOG[], "        [error] html")
    return nothing
  end

  meta = merge(Dict(pairs(articledata)...), Dict(pairs(yaml)...))
  delete!(meta, :workingVersion)
  delete!(meta, :title)
  meta[:stylo] = articledata[:workingVersion][:yaml] |> string2symbol

  if(haskey(meta, :abstract))
    meta[:abstract] =  markdowntohtml(meta[:abstract]) |> stripparagraph |> String
  end

  artobj = articulus(
    rawtitle,
    label,
    corpusinfo,
    meta,
    articledata[:workingVersion][:md],
    html,
    articledata[:workingVersion][:bib],
  )

  result = copy(artobj.meta)
  result[:title] = artobj.title
  result[:label] = artobj.label
  result[:slug] = artobj.slug
  result[:path] = artobj.path
  result[:corpus] = artobj.corpus
  result[:md] = artobj.md
  result[:html] = artobj.html
  result[:bib] = artobj.bib

  push!(PROCESS_LOG[], "        [ok]")
  return result
end

# Lazy-loaded cache to avoid IO at module load
const DATA_CACHE = Ref{Dict}(Dict())
const PROCESS_LOG = Ref{Vector{String}}(String[])

function processlog()
  return PROCESS_LOG[]
end

"""


Ensure that the TowSty data is loaded.

This function checks if the data cache is empty.
If it is, it loads the sources and processes them, and stores the result in the cache.
Subsequent calls return the cached data without reloading.

See also [`reloaddata()`](@ref) to force refresh of the cached data.

# Return
See [`processdata`](@ref).
"""
function loaddata()
  if isempty(DATA_CACHE[])
    sources = loadsources()
    data = processdata(sources, BASEURL)
    DATA_CACHE[] = data
    logpath = joinpath(TEMP_PATH, "process.log")
    write(logpath, join(PROCESS_LOG[], "\n"))
  end
  return DATA_CACHE[]
end

"""
    reloaddata()

Force a complete reload of the TowSty data from the workspace file.

This function clears the internal data cache and reloads all data from the source.

# Return
See [`processdata`](@ref).
"""
function reloaddata()
  DATA_CACHE[] = Dict()
  return loaddata()
end

"""
    workspace()

Retrieve the complete workspace data.

This function provides access to the raw workspace data loaded from the
`workspace.json` file, including articles, corpus and metadata.

# Return
A Dict containing the complete workspace data structure
"""
function workspace()
  return loaddata()[:workspace]
end

"""
    corpuses()

Retrieve all processed corpuses from the workspace.

Returns a Vector of all corpuses with their processed articles and descriptions, and formatted paths.

# Return
A Vector of Dict, where each Dict represents a processed corpus with fields:
- `:name`: Corpus name
- `:path`: Formatted URL path
- `:articles`: Vector of articles
- `:description`: HTML-formatted description
"""
function corpuses()
  return loaddata()[:corpuses]
end

"""
    articles()

List all articles from all corpuses, sorted by creation date.

Returns a Vector of processed articles **from all corpuses**,
sorted in reverse chronological order (most recent first).

# Return
A Vector of Dict, where each Dict represents a processed article with keys including:
- `:_id`: id of the article
- `:title`: HTML-formatted title
- `:slug`: URL-friendly title-slug
- `:path`: path to the article
- `:html`: Rendered HTML content (with bibliography)
- `:corpus`: Parent corpus information
- `:createdAt`: Creation timestamp (from Stylo)
- And all YAML header fields
"""
function articles()
  return loaddata()[:articles]
end

"""
    orphans()

List all orphan articles.

Orphan articles are those that exist in the workspace but are not associated
with any corpus and do not have a title starting with `__` (which would make them single pages).
Each orphan is processed with empty corpus information.

See also [`singlepages`](@ref).

# Return
A Vector of processed orphan article Dict objects
"""
function orphans()
  return loaddata()[:orphans]
end

"""
    singlepages()

List all single pages.

Single pages are special articles identified by a title starting with `__`.
They are not associated with any corpus but appear in the navigation menu.
Examples include the bibliography article (`__bibliographie`) or other global pages.

See also [`orphans`](@ref).

# Return
A Vector of processed single page Dict objects
"""
function singlepages()
  return loaddata()[:singlepages]
end

"""
    meta()

Retrieve workspace metadata and navigation information.

Provides access to workspace-level metadata including the workspace name
and navigation structure for building menus and site navigation, breadcrumb, etc.

# Return
A Dict containing:
- `:workspacename` - The name of the workspace
- `:nav` - Navigation array with entries for each corpus and bibliography
"""
function meta()
  return loaddata()[:meta]
end
