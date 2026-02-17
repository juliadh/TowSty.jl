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
- `:orphans` - Articles not associated with any corpus
- `:bibliography` - The general bibliography article
- `:meta` - Workspace metadata including navigation
"""
function processdata(workspace::Dict{Symbol, Any})
  println("Processing data...")
  corpuses = [processcorpus(corpus) for corpus in workspace[:corpus]]

  articles = Vector{Dict{Symbol, Any}}()
  for c in corpuses
    append!(articles, c[:articles])
  end

  articleids = [article[:_id] for article in articles]

  orphans = filter(a -> !in(a[:_id], articleids) && a[:title] != "__bibliographie", workspace[:articles])
  processorphans = [processarticle(Dict(:article => o), Dict(:path => "", :name => "")) for o in orphans]

  bibliography = processbibliography(workspace[:articles])

  sorted = sort(articles, by = x -> x[:createdAt], rev=true)

  workspace[:articles] = vcat(orphans, articles)

  return Dict(
    :workspace => workspace,
    :corpuses => corpuses,
    :orphans => processorphans,
    :articles => sorted,
    :bibliography => !isnothing(bibliography) ? bibliography : nothing,
    :meta => Dict(
      :workspacename => workspace[:name],
      :nav => vcat(
        [Dict(:name => c[:name], :path => formatpath(c[:path])) for c in corpuses],
        !isnothing(bibliography) ? [Dict(:name => "Bibliographie", :path => "bibliographie")] : []
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
function processcorpus(corpus::Dict{Symbol, Any})
  println("  -> Processing corpus: $(corpus[:name])")
  corpusinfo = Dict(
    :name => corpus[:name],
    :path => formatpath(corpus[:name])
  )

  corpus[:path] = formatpath(corpus[:name])
  corpus[:articles] = processarticles(corpus[:articles], corpusinfo)
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
  println("      -> Processing articles")
  formattedarticles = [processarticle(article, corpusinfo) for article in articles]

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
  println("        -> Processing article $(article[:article][:_id])")
  article = article[:article]
  yaml = getyamlheader(article[:workingVersion][:md]) |> string2symbol
  yamltitle = markdowntoplain(yaml[:title]) |> strip #strip to remove break (\n) at end of the string
  yaml[:slug] = formatpath(String(yamltitle))
  yaml[:path] = joinpath( corpusinfo[:path], formatpath(String(yamltitle)) )
  yaml[:title] = markdowntohtml( yaml[:title] ) |> stripparagraph |> String |> strip

  merge!(article, yaml)

  article[:md] = article[:workingVersion][:md]
  article[:bib] = article[:workingVersion][:bib]
  article[:yaml] = article[:workingVersion][:yaml]
  article[:corpus] = corpusinfo
  article[:html] = Dict(:md => article[:workingVersion][:md], :bib => article[:workingVersion][:bib]) |> markdowntohtml

  delete!(article, :workingVersion)

  return article
end

"""
    processbibliography(articles::Vector)

Process the main bibliography article.

Retrieves the bibliography article and converts the markdown content to html 
and processes metadata (yaml header, path, slug, etc.)

# Arguments
- `articles::Vector`: a Vector of articles from the workspace

# Return
A Dict containing the formatted bibliography article, or `nothing` if not found.
"""
function processbibliography(articles::Vector{Dict{Symbol, Any}})
  println("Processing bibliography")
  bibindex = findfirst(a -> a[:title] == "__bibliographie", articles)
  if !isnothing(bibindex)
    bibliography = processarticle(Dict(:article => articles[bibindex]), Dict(:name => "", :path => ""))
    return bibliography
  end
end

# Lazy-loaded cache to avoid IO at module load
const DATA_CACHE = Ref{Dict}(Dict())

"""
    ensure_data_loaded()

Ensure that the TowSty data is loaded.

This function checks if the data cache is empty.
If it is, it loads the sources and processes them, and stores the result in the cache.
Subsequent calls return the cached data without reloading.

See also [`reload_data!()`](@ref) to force refresh of the cached data.

# Return
See [`processdata`](@ref).
"""
function ensure_data_loaded()
  if isempty(DATA_CACHE[])
    sources = loadsources()
    data = processdata(sources)
    DATA_CACHE[] = data
  end
  return DATA_CACHE[]
end

"""
    reload_data!()

Force a complete reload of the TowSty data from the workspace file.

This function clears the internal data cache and reloads all data from the source.

# Return
See [`processdata`](@ref).
"""
function reload_data!()
  DATA_CACHE[] = Dict()
  return ensure_data_loaded()
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
  return ensure_data_loaded()[:workspace]
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
  return ensure_data_loaded()[:corpuses]
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
  return ensure_data_loaded()[:articles]
end

"""
    orphans()

List all orphan articles.

Orphan articles are those that exist in the workspace but are not associated
with any corpus. Each orphan is processed with empty corpus information

See also [`generalbibliography`](@ref).

# Return
A Vector of processed orphan article Dict objects
"""
function orphans()
  return ensure_data_loaded()[:orphans]
end

"""
    generalbibliography()

Retrieve the general bibliography article.

Returns the special bibliography article (identified by the Stylo title `__bibliographie`).

# Return
- A Dict representing the processed bibliography article.
- `nothing` if no bibliography article is found in the workspace
"""
function generalbibliography()
  return ensure_data_loaded()[:bibliography]
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
  return ensure_data_loaded()[:meta]
end
