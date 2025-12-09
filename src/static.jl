"""
    freeze(outputdir::String; baseurl::String="/")

Wrapper function to generate a complete static site in `outputdir` from workspace data.

* `outputdir`: Output directory path for the static site
* `baseurl`: Base URL for links (default "/")
"""
function freeze(outputdir::String; baseurl::String="/")
  println("Generating static site in: $outputdir")

  # Create the output directory
  mkpath(outputdir)

  # Copy static assets
  println("Copying static assets...")
  copyassets(outputdir)

  # Generate the home page
  println("Generating the home page...")
  statichomepage(outputdir)

  # Generate corpus pages
  println("Generating corpus pages...")
  for corpus in corpuses()
    staticcorpuspage(outputdir, corpus)
  end

  # Generate article pages
  println("Generating article pages...")
  for article in articles()
    staticarticlepage(outputdir, article)
  end

  # Generate bibliography page if it exists
  if !isnothing(generalbibliography())
    println("Generating bibliography page...")
    staticbibliographypage(outputdir)
  end

  # Generate search page and search data JSON
  println("Generating search page and data...")
  staticsearchpage(outputdir)
  staticsearchdata(outputdir)

  println("Static site generated successfully!")
  println("   → Directory: $outputdir")
  println("   → Pages: $(length(corpuses())) corpus, $(length(articles())) articles")
end

"""
    copyassets(outputdir::String)

Copy static assets (CSS, JS, images) to the output directory.

* `outputdir`: Output directory path
"""
function copyassets(outputdir::String)
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
    statichomepage(outputdir::String)

Generate the home page (index.html).

* `outputdir`: Output directory path
"""
function statichomepage(outputdir::String)
  data = gethome()
  templatepath = joinpath(TEMPLATES_PATH, "index.html")
  html = templaterender_static(templatepath, data)
  filepath = joinpath(outputdir, "index.html")
  
  write(filepath, html)
end

"""
    staticcorpuspage(outputdir::String, corpus::Dict)

Generate a corpus page.

* `outputdir`: Output directory path
* `corpus`: Corpus data dictionary
"""
function staticcorpuspage(outputdir::String, corpus::Dict)
  corpusname = corpus[:normalizedname]
  data = getcorpus(corpusname)

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
    staticarticlepage(outputdir::String, article::Dict)

Generate an article page.

* `outputdir`: Output directory path
* `article`: Article data dictionary
"""
function staticarticlepage(outputdir::String, article::Dict)
  path = article[:path]
  pathparts = splitpath(path)
  
  if length(pathparts) < 2
    @warn "Invalid path for article: $path"
    return
  end

  corpusname = pathparts[1]
  articlepath = pathparts[2]

  data = getarticle(corpusname, articlepath)

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
    staticbibliographypage(outputdir::String)

Generate the bibliography page.

* `outputdir`: Output directory path
"""
function staticbibliographypage(outputdir::String)
  data = getbibliography()
  templatepath = joinpath(TEMPLATES_PATH, "article.html")
  html = templaterender_static(templatepath, data)

  # Create the bibliography directory
  bibliographydir = joinpath(outputdir, "bibliographie")
  mkpath(bibliographydir)

  filepath = joinpath(bibliographydir, "index.html")
  write(filepath, html)
end

"""
    staticsearchpage(outputdir::String)

Generate the search page.

* `outputdir`: Output directory path
"""
function staticsearchpage(outputdir::String)
  data = Dict(
    :meta => meta()
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

* `outputdir`: Output directory path
"""
function staticsearchdata(outputdir::String)
  # Write JSON file at the root of build directory
  jsonpath = joinpath(outputdir, "articles.json")
  
  open(jsonpath, "w") do io
    JSON.print(io, articles(), 2)
  end
end

"""
    bake(outputdir::String="build"; baseurl::String="/")

Convenient alias for generating a static site.

* `outputdir`: Output directory path (default "build")
* `baseurl`: Base URL for links (default "/")
"""
function bake(outputdir::String="build"; baseurl::String="/")
  freeze(outputdir, baseurl=baseurl)
end
