function loadsources()
  workspacedata = JSON.parsefile(DATA_PATH) |> string2symbol
  return workspacedata
end

function standardizedata(workspace::Dict)
  corpuses = [standardizecorpus(corpus) for corpus in workspace[:corpus]]

  articles = Vector()
  for c in corpuses
    append!(articles, c[:articles])
  end

  bibliography = processbibliography(workspace[:articles])
  #append!( articles, [bibliography] )

  sorted = sort(articles, by = x -> x[:date])

  return Dict(
    :workspace => workspace,
    :corpuses => corpuses,
    :articles => sorted,
    :bibliography => !isnothing(bibliography) ? bibliography : nothing,
    :meta => Dict(
      :workspacename => workspace[:name],
      :nav => vcat(
        [Dict(:name => c[:name], :normalizedname => c[:normalizedname]) for c in corpuses],
        !isnothing(bibliography) ? [Dict(:name => "Bibliographie", :normalizedname => "bibliographie")] : []
      )
    )
  )
end

function standardizecorpus(corpus::Dict)
  corpus[:normalizedname] = Unicode.normalize(corpus[:name], stripmark=true) |> Unicode.lowercase
  corpus[:articles] = standardizearticles(corpus[:articles], corpus[:normalizedname])
  corpus[:description] = markdowntohtml(corpus[:description])

  return corpus
end

function standardizearticles(articles::Vector, corpusname::String)
  formatedarticles = [standardizearticle(article, corpusname) for article in articles]
  sorted = sort(formatedarticles, by = x -> x[:date])
  return sorted
end

function standardizearticle(article::Dict, corpusname::String)
  article = article[:article]
  yaml = getYamlFromMarkdown(article[:workingVersion][:md]) |> string2symbol
  yamltitle = markdowntoplain(yaml[:title])
  yaml[:path] = joinpath( corpusname, slugify( yamltitle ) )
  yaml[:title] = markdowntohtml( yaml[:title] ) |> stripparagraph |> String

  merge!(article, yaml)

  article[:md] = article[:workingVersion][:md]
  article[:bib] = article[:workingVersion][:bib]
  article[:yaml] = article[:workingVersion][:yaml]
  article[:corpus] = corpusname
  article[:html] = Dict(:md => article[:workingVersion][:md], :bib => article[:workingVersion][:bib]) |> processarticle

  delete!(article, :workingVersion)

  return article
end

function processbibliography(articles::Vector)
  article = filter(a -> a[:title] == "__bibliographie", articles)
  if length(article) != 0
    bibliography = standardizearticle(Dict(:article => article[1]), "")
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
    data = standardizedata(sources)
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

function generalbibliography()
  return ensure_data_loaded()[:bibliography]
end

function meta()
  return ensure_data_loaded()[:meta]
end
