"""
    freeze(outputdir::String; baseurl::String="/")

Generate a complete static site in `outputdir` from workspace data.

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

  templatepath = joinpath(TEMPLATES_PATH, "articles.html")
  html = templaterender_static(templatepath, data)

  # Create the article directory using the full path
  articledir = joinpath(outputdir, path)
  mkpath(articledir)

  # Write the HTML file as index.html
  filepath = joinpath(articledir, "index.html")
  write(filepath, html)
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
