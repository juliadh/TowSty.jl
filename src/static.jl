"""
    freeze(outputdir::String; mountpath::String="/")

Wrapper function to generate a static site in `outputdir` from workspace data.

# Argument
- `outputdir`: Output directory path for the static site

# Keyword argument
- `mountpath`: Mount path for the application (default "/" for root deployment)
"""
function freeze(outputdir::String; mountpath::String="/")

  println("Generating static site in: $outputdir")
  println("Mount path: $mountpath")

  mkpath(outputdir)

  println("Copying static assets...")
  copyassets(outputdir, mountpath)

  println("Generating the home page...")
  statichomepage(outputdir, mountpath)

  println("Generating corpus pages...")
  for corpus in Base.invokelatest(corpuses)
    staticcorpuspage(outputdir, corpus, mountpath)
  end

  println("Generating article pages...")
  for article in Base.invokelatest(articles)
    staticarticlepage(outputdir, article, mountpath)
  end

  println("Generating single pages...")
  for page in Base.invokelatest(singlepages)
    staticsinglepagepage(outputdir, page, mountpath)
  end

  println("Generating search page and data...")
  staticsearchpage(outputdir, mountpath)
  staticsearchdata(outputdir)

  println("Static site generated successfully!")
  println("   → Directory: $outputdir")
  println("   → Pages: $(length(Base.invokelatest(corpuses))) corpus, $(length(Base.invokelatest(articles))) articles")
end

"""
    copyassets(outputdir::String, mountpath::String="/")

Copy static assets (CSS, JS, images) to the output directory.

# Arguments
- `outputdir`: Output directory path
- `mountpath`: Mount path for links (default "/" for root deployment)
"""
function copyassets(outputdir::String, mountpath::String="/")
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
    statichomepage(outputdir::String, mountpath::String="/")

Generate the home page (index.html).

# Arguments
- `outputdir`: Output directory path
- `mountpath`: Mount path for links (default "/" for root deployment)
"""
function statichomepage(outputdir::String, mountpath::String="/")
  data = Base.invokelatest(gethome, mountpath)
  templatepath = joinpath(TEMPLATES_PATH, "index.html")
  html = templaterender_static(templatepath, data)
  filepath = joinpath(outputdir, "index.html")
  
  write(filepath, html)
end

"""
    staticcorpuspage(outputdir::String, corpus::Dict, mountpath::String="")

Generate a corpus page.

# Arguments
- `outputdir`: Output directory path
- `corpus`: Corpus data dictionary
- `mountpath`: Mount path for links (default "" for root deployment)
"""
function staticcorpuspage(outputdir::String, corpus::Dict, mountpath::String="")
  corpusname = corpus[:path]
  
  data = Base.invokelatest(getcorpus, corpusname, mountpath)

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
    staticarticlepage(outputdir::String, article::Dict, mountpath::String="/")

Generate an article page.

# Arguments
- `outputdir`: Output directory path
- `article`: Article data dictionary
- `mountpath`: Mount path for links (default "/" for root deployment)
"""
function staticarticlepage(outputdir::String, article::Dict, mountpath::String="")
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

  data = Base.invokelatest(getarticle, corpusname, articlepath_decoded, mountpath)

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
    staticsinglepagepage(outputdir::String, page::Dict, mountpath::String="/")

Generate a single page (article with title starting with `__`).

# Arguments
- `outputdir`: Output directory path
- `page`: Single page Dict
- `mountpath`: Mount path for links (default "/" for root deployment)
"""
function staticsinglepagepage(outputdir::String, page::Dict, mountpath::String="")
  slug_decoded = URIs.unescapeuri(page[:slug])
  
  data = Base.invokelatest(getsinglepage, page[:slug], mountpath)
  templatepath = joinpath(TEMPLATES_PATH, "article.html")
  html = templaterender_static(templatepath, data)

  # Create the page directory using decoded slug
  pagedir = joinpath(outputdir, slug_decoded)
  mkpath(pagedir)

  filepath = joinpath(pagedir, "index.html")
  write(filepath, html)
end

"""
    staticsearchpage(outputdir::String, mountpath::String="/")

Generate the search page.

# Arguments
- `outputdir`: Output directory path
- `mountpath`: Mount path for links (default "/" for root deployment)
"""
function staticsearchpage(outputdir::String, mountpath::String="")
  metadata = Base.invokelatest(meta)
  metadata[:mountpath] = mountpath

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
