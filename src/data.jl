function loadsources()
  workspacedata = JSON.parsefile(DATA_PATH) |> string2symbol
  return workspacedata
end

function standardizedata(corpuses::Vector)
  corpuses = [standardizecorpus(corpus) for corpus in corpuses]
  articles = Vector()
  for c in corpuses
    append!(articles, c[:articles])
  end
  sorted = sort(articles, by = x -> x[:date])
  return Dict(
    :corpuses => corpuses,
    :articles => sorted
  )
end

function standardizecorpus(corpus::Dict)
  corpus[:normalizedname] = Unicode.normalize(corpus[:name], stripmark=true) |> Unicode.lowercase
  corpus[:articles] = standardizearticles(corpus[:articles], corpus[:normalizedname])

  return corpus
end

function standardizearticles(articles::Vector, corpusname::String)
  formatedarticles = [standardizearticle(article, corpusname) for article in articles]
  sorted = sort(formatedarticles, by = x -> x[:date])
  return sorted
end

function standardizearticle(article::Dict, corpusname)
  article = article[:article]
  yaml = getYamlFromMarkdown(article[:workingVersion][:md]) |> string2symbol
  yamltitle = markdowntoplain(yaml[:title])
  yaml[:slugtitle] = joinpath( corpusname, slugify( yamltitle ) )
  yaml[:title] = markdowntohtml( yaml[:title] ) |> stripparagraph |> String

  merge!(article, yaml)

  article[:md] = article[:workingVersion][:md]
  article[:bib] = article[:workingVersion][:bib]
  article[:yaml] = article[:workingVersion][:yaml]
  article[:corpus] = corpusname

  delete!(article, :workingVersion)

  return article
end

# Lazy-loaded cache to avoid IO at module load
const DATA_CACHE = Ref{Dict}(Dict())

function ensure_data_loaded()
  if isempty(DATA_CACHE[]) 
    sources = loadsources()
    data = standardizedata(sources[:corpus])
    DATA_CACHE[] = data
  end
  return DATA_CACHE[]
end

function corpuses()
  return ensure_data_loaded()[:corpuses]
end

function articles()
  return ensure_data_loaded()[:articles]
end
