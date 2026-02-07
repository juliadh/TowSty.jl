function loadsources()
  workspacedata = JSON.parsefile(DATA_PATH) |> string2symbol
  return workspacedata
end

function processdata(workspace::Dict)
  println("Processing data...")
  corpuses = [processcorpus(corpus) for corpus in workspace[:corpus]]

  articles = Vector()
  for c in corpuses
    append!(articles, c[:articles])
  end

  articleids = []
  for article in articles
    push!(articleids, article[:_id])
  end

  orphans = filter(a -> !in(a[:_id], articleids) && a[:title] != "__bibliographie", workspace[:articles])
  processorphans = [processarticle(Dict(:article => o), Dict(:path => "", :name => "")) for o in orphans]

  bibliography = processbibliography(workspace[:articles])
  #append!( articles, [bibliography] )

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

function processcorpus(corpus::Dict)
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

function processarticles(articles::Vector, corpusinfo::Dict)
  println("      -> Processing articles")
  formatedarticles = [processarticle(article, corpusinfo) for article in articles]
  #sorted = sort(formatedarticles, by = x -> x[:createdAt], rev=true)
  return formatedarticles
end

function processarticle(article::Dict, corpusinfo::Dict)
  println("        -> Processing article $(article[:article][:_id])")
  article = article[:article]
  yaml = getYamlFromMarkdown(article[:workingVersion][:md]) |> string2symbol
  yamltitle = markdowntoplain(yaml[:title])
  #yaml[:slug] = normalizelabel( yamltitle, slug=true )
  yaml[:slug] = formatpath(yamltitle)
  #yaml[:path] = joinpath( corpusinfo[:path], normalizelabel( yamltitle, slug=true ) )
  yaml[:path] = joinpath( corpusinfo[:path], formatpath(yamltitle) )
  yaml[:title] = markdowntohtml( yaml[:title] ) |> stripparagraph |> String

  merge!(article, yaml)

  article[:md] = article[:workingVersion][:md]
  article[:bib] = article[:workingVersion][:bib]
  article[:yaml] = article[:workingVersion][:yaml]
  article[:corpus] = corpusinfo
  article[:html] = Dict(:md => article[:workingVersion][:md], :bib => article[:workingVersion][:bib]) |> markdowntohtml
  #article[:plain] = Dict(:md => article[:workingVersion][:md], :bib => article[:workingVersion][:bib]) |> markdowntoplain

  delete!(article, :workingVersion)

  return article
end

function processbibliography(articles::Vector)
  println("Processing bibliography")
  article = filter(a -> a[:title] == "__bibliographie", articles)
  if length(article) != 0
    bibliography = processarticle(Dict(:article => article[1]), Dict(:name => "", :path => ""))
    return bibliography
  else
    return nothing
  end
end

# Lazy-loaded cache to avoid IO at module load
const DATA_CACHE = Ref{Dict}(Dict())

function ensure_data_loaded()
  if isempty(DATA_CACHE[])
    sources = loadsources()
    data = processdata(sources)
    DATA_CACHE[] = data
  end
  return DATA_CACHE[]
end

function reload_data!()
  DATA_CACHE[] = Dict()
  return ensure_data_loaded()
end

function workspace()
  return ensure_data_loaded()[:workspace]
end

function corpuses()
  return ensure_data_loaded()[:corpuses]
end

function articles()
  return ensure_data_loaded()[:articles]
end

function orphans()
  return ensure_data_loaded()[:orphans]
end

function generalbibliography()
  return ensure_data_loaded()[:bibliography]
end

function meta()
  return ensure_data_loaded()[:meta]
end
