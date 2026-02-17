"""
    freeze(outputdir::String; baseurl::String="")

Wrapper function to generate a static site in `outputdir` from workspace data.

# Argument
- `outputdir`: Output directory path for the static site

# Keyword argument
- `baseurl`: Base URL path without leading slash (default "" for root, e.g., "blog" for /blog/)
"""
function freeze(outputdir::String; baseurl::String="")
  println("Generating static site in: $outputdir")
  println("Base URL: $baseurl")

  # Create the output directory
  mkpath(outputdir)

  # Copy static assets
  println("Copying static assets...")
  copyassets(outputdir, baseurl)

  # Generate the home page
  println("Generating the home page...")
  statichomepage(outputdir, baseurl)

  # Generate corpus pages
  println("Generating corpus pages...")
  for corpus in corpuses()
    staticcorpuspage(outputdir, corpus, baseurl)
  end

  # Generate article pages
  println("Generating article pages...")
  for article in articles()
    staticarticlepage(outputdir, article, baseurl)
  end

  # Generate bibliography page if it exists
  if !isnothing(generalbibliography())
    println("Generating bibliography page...")
    staticbibliographypage(outputdir, baseurl)
  end

  # Generate search page and search data JSON
  println("Generating search page and data...")
  staticsearchpage(outputdir, baseurl)
  staticsearchdata(outputdir)

  println("Static site generated successfully!")
  println("   → Directory: $outputdir")
  println("   → Pages: $(length(corpuses())) corpus, $(length(articles())) articles")
end

"""
    copyassets(outputdir::String)

Copy static assets (CSS, JS, images) to the output directory.

# Arguments
- `outputdir`: Output directory path
- `baseurl`: Base URL for links (default "" for root deployment)
"""
function copyassets(outputdir::String, baseurl::String="")
  assetssrc = joinpath(pwd(), "assets/static")
  assetsdest = joinpath(outputdir, "static")

  if isdir(assetssrc)
    mkpath(dirname(assetsdest))
    cp(assetssrc, assetsdest, force=true)
  else
    @warn "Static assets directory not found: $assetssrc"
  end
end

"""
    statichomepage(outputdir::String, baseurl::String="")

Generate the home page (index.html).

# Arguments
- `outputdir`: Output directory path
- `baseurl`: Base URL for links (default "" for root deployment)
"""
function statichomepage(outputdir::String, baseurl::String="")
  data = gethome(baseurl)
  templatepath = joinpath(TEMPLATES_PATH, "index.html")
  html = templaterender_static(templatepath, data)
  filepath = joinpath(outputdir, "index.html")
  
  write(filepath, html)
end

"""
    staticcorpuspage(outputdir::String, corpus::Dict, baseurl::String="")

Generate a corpus page.

# Arguments
- `outputdir`: Output directory path
- `corpus`: Corpus data dictionary
- `baseurl`: Base URL for links (default "" for root deployment)
"""
function staticcorpuspage(outputdir::String, corpus::Dict, baseurl::String="")
  corpusname = corpus[:path]
  data = getcorpus(corpusname, baseurl)

  if get(data, :error, false)
    @warn "Unable to generate page for corpus: $corpusname"
    return
  end

  templatepath = joinpath(TEMPLATES_PATH, "corpus.html")
  html = templaterender_static(templatepath, data)

  # Create the corpus directory
  corpusdir = joinpath(outputdir, corpusname)
  mkpath(corpusdir)

  filepath = joinpath(corpusdir, "index.html")
  write(filepath, html)
end

"""
    staticarticlepage(outputdir::String, article::Dict, baseurl::String="")

Generate an article page.

# Arguments
- `outputdir`: Output directory path
- `article`: Article data dictionary
- `baseurl`: Base URL for links (default "" for root deployment)
"""
function staticarticlepage(outputdir::String, article::Dict, baseurl::String="")
  path = article[:path]
  pathparts = splitpath(path)
  
  if length(pathparts) < 2
    @warn "Invalid path for article: $path"
    return
  end

  corpusname = pathparts[1]
  articlepath = pathparts[2]

  data = getarticle(corpusname, articlepath, baseurl)

  if get(data, :error, false)
    @warn "Unable to generate page for article: $path"
    return
  end

  templatepath = joinpath(TEMPLATES_PATH, "article.html")
  html = templaterender_static(templatepath, data)

  # Create the article directory using the full path
  articledir = joinpath(outputdir, path)
  mkpath(articledir)

  # Write the HTML file as index.html
  filepath = joinpath(articledir, "index.html")
  write(filepath, html)
end

"""
    staticbibliographypage(outputdir::String, baseurl::String="")

Generate the bibliography page.

# Arguments
- `outputdir`: Output directory path
- `baseurl`: Base URL for links (default "" for root deployment)
"""
function staticbibliographypage(outputdir::String, baseurl::String="")
  data = getbibliography(baseurl)
  templatepath = joinpath(TEMPLATES_PATH, "article.html")
  html = templaterender_static(templatepath, data)

  # Create the bibliography directory
  bibliographydir = joinpath(outputdir, "bibliographie")
  mkpath(bibliographydir)

  filepath = joinpath(bibliographydir, "index.html")
  write(filepath, html)
end

"""
    staticsearchpage(outputdir::String, baseurl::String="")

Generate the search page.

# Arguments
- `outputdir`: Output directory path
- `baseurl`: Base URL for links (default "" for root deployment)
"""
function staticsearchpage(outputdir::String, baseurl::String="")
  metadata = meta()
  metadata[:baseurl] = baseurl

  data = Dict(
    :meta => metadata
  )

  templatepath = joinpath(TEMPLATES_PATH, "recherche.html")

  if !isfile(templatepath)
    @warn "Search template not found: $templatepath. Skipping search page generation."
    return
  end

  html = templaterender_static(templatepath, data)

  # Create the search directory
  searchdir = joinpath(outputdir, "recherche")
  mkpath(searchdir)

  filepath = joinpath(searchdir, "index.html")
  write(filepath, html)
end

"""
    staticsearchdata(outputdir::String)

Generate the search data as a JSON.

# Argument
- `outputdir`: Output directory path
"""
function staticsearchdata(outputdir::String)
  # Write JSON file at the root of build directory
  jsonpath = joinpath(outputdir, "articles.json")

  open(jsonpath, "w") do io
    JSON.print(io, searchindex(), 2)
  end
end