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
  slugparts = splitpath(article[:slugtitle])
  if length(slugparts) < 2
    @warn "Invalid slug for article: $(article[:slugtitle])"
    return
  end

  corpusname = slugparts[1]
  articleslug = slugparts[2]

  data = getarticle(corpusname, articleslug)

  if get(data, :error, false)
    @warn "Unable to generate page for article: $(article[:slugtitle])"
    return
  end

  templatepath = joinpath(TEMPLATES_PATH, "articles.html")
  html = templaterender_static(templatepath, data)

  # Create the corpus directory if necessary
  corpusdir = joinpath(outputdir, corpusname)
  mkpath(corpusdir)

  # Write the HTML file directly (no subdirectory)
  filepath = joinpath(corpusdir, "$articleslug.html")
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