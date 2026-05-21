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

  mkpath(outputdir)

  println("Copying static assets...")
  copyassets(outputdir, baseurl)

  println("Generating the home page...")
  statichomepage(outputdir, baseurl)

  println("Generating corpus pages...")
  for corpus in Base.invokelatest(corpuses)
    staticcorpuspage(outputdir, corpus, baseurl)
  end

  println("Generating article pages...")
  for article in Base.invokelatest(articles)
    staticarticlepage(outputdir, article, baseurl)
  end

  println("Generating single pages...")
  for page in Base.invokelatest(singlepages)
    staticsinglepagepage(outputdir, page, baseurl)
  end

  println("Generating search page and data...")
  staticsearchpage(outputdir, baseurl)
  staticsearchdata(outputdir)

  println("Static site generated successfully!")
  println("   → Directory: $outputdir")
  println("   → Pages: $(length(Base.invokelatest(corpuses))) corpus, $(length(Base.invokelatest(articles))) articles")
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
  data = Base.invokelatest(gethome, baseurl)
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
  
  data = Base.invokelatest(getcorpus, corpusname, baseurl)

  if get(data, :error, false)
    @warn "Unable to generate page for corpus: $corpusname"
    return
  end

  templatepath = joinpath(TEMPLATES_PATH, "corpus.html")
  html = templaterender_static(templatepath, data)

  # Create the corpus directory using decoded path (for filesystem)
  corpusname_decoded = URIs.unescapeuri(corpusname)
  corpusdir = joinpath(outputdir, corpusname_decoded)
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

  # Decode paths: getarticle() expects decoded article (will re-encode for matching)
  # but corpusname should stay encoded
  articlepath_decoded = URIs.unescapeuri(articlepath)

  data = Base.invokelatest(getarticle, corpusname, articlepath_decoded, baseurl)

  if get(data, :error, false)
    @warn "Unable to generate page for article: $path"
    return
  end

  templatepath = joinpath(TEMPLATES_PATH, "article.html")
  html = templaterender_static(templatepath, data)

  # Create the article directory using decoded paths (for filesystem)
  corpusname_decoded = URIs.unescapeuri(corpusname)
  articledir = joinpath(outputdir, corpusname_decoded, articlepath_decoded)
  mkpath(articledir)

  # Write the HTML file as index.html
  filepath = joinpath(articledir, "index.html")
  write(filepath, html)
end

"""
    staticsinglepagepage(outputdir::String, page::Dict, baseurl::String="")

Generate a single page (article with title starting with `__`).

# Arguments
- `outputdir`: Output directory path
- `page`: Single page Dict
- `baseurl`: Base URL for links (default "" for root deployment)
"""
function staticsinglepagepage(outputdir::String, page::Dict, baseurl::String="")
  slug_decoded = URIs.unescapeuri(page[:slug])
  
  data = Base.invokelatest(getsinglepage, page[:slug], baseurl)
  templatepath = joinpath(TEMPLATES_PATH, "article.html")
  html = templaterender_static(templatepath, data)

  # Create the page directory using decoded slug
  pagedir = joinpath(outputdir, slug_decoded)
  mkpath(pagedir)

  filepath = joinpath(pagedir, "index.html")
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
  metadata = Base.invokelatest(meta)
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
    JSON.print(io, Base.invokelatest(searchindex), 2)
  end
end
