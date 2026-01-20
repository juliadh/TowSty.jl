function route(path::String)
  baseurl = get(() -> "/", () -> WEBAPP_BASEURL)
  normalized_base = rstrip(baseurl, '/')
  return normalized_base * path
end

staticfiles("assets/static", route("/static"))

@get route("/") function()
  data = gethome(WEBAPP_BASEURL)
  templatepath = joinpath(TEMPLATES_PATH, "index.html")

  return templaterender(templatepath, data)
end

@get route("/data") function()
  data = gethome(WEBAPP_BASEURL)

  return data
end

@get route("/{corpus}") function (req::HTTP.Request, corpus::String)
  data = getcorpus(corpus, WEBAPP_BASEURL)
  templatepath = joinpath(TEMPLATES_PATH, "corpus.html")

  return templaterender(templatepath, data)
end

@get route("/{corpus}/data") function (req::HTTP.Request, corpus::String)
  data = getcorpus(corpus, WEBAPP_BASEURL)

  return data
end

@get route("/{corpus}/{article}") function (req::HTTP.Request, corpus::String, article::String)
  data = getarticle(corpus, article, WEBAPP_BASEURL)
  templatepath = joinpath(TEMPLATES_PATH, "article.html")

  return templaterender(templatepath, data)
end

@get route("/{corpus}/{article}/data") function (req::HTTP.Request, corpus::String, article::String)
  data = getarticle(corpus, article, WEBAPP_BASEURL)

  return data
end

@get route("/articles.json") function()
  data = articles()

  return data
end

@get route("/recherche") function()
  metadata = meta()
  metadata[:baseurl] = WEBAPP_BASEURL
  data = Dict(:meta => metadata)
  templatepath = joinpath(TEMPLATES_PATH, "recherche.html")

  return templaterender(templatepath, data)
end

@get route("/bibliographie") function()
  data = getbibliography(WEBAPP_BASEURL)
  templatepath = joinpath(TEMPLATES_PATH, "article.html")

  return templaterender(templatepath, data)
end

@get route("/workspace") function (req::HTTP.Request)
  templatepath = joinpath(TEMPLATES_PATH, "workspace.html")
  template = read(templatepath, String)
  render = otera(template)
  data = Dict( :content => "" )

  return Base.invokelatest(render, data)
end

@get route("/workspace/update") function (req::HTTP.Request)
  form = queryparams(req)
  styloapikey = get(form, "styloapikey", "")
  workspaceid = get(form, "workspaceid", "")

  data = getworkspace(workspaceid, styloapikey) |> string2symbol

  if !isnothing(data) && haskey(data, :name)
    message = Dict(
      :message => "Données mise à jour !"
    )
    write(DATA_PATH, JSON.json(data))
  else
    message = Dict(
      :message => "Erreur lors de la mise à jour des données !"
    )
  end

  template = """
    <html>
      <head>
        <meta charset="utf-8"/>
      </head>
      <body>
        <header style="margin: auto; padding: 2em;">
          <nav>
            <a href="$(route("/"))">Retour à l'accueil</a>
          </nav>
        </header>
        <main style="width: 800px; margin: auto; padding: 2em;">
          <h1>Mise à jour des données</h1>
          <p>{{ message }}</p>
        </main>
      </body>
    </html>
    """
  render = otera(template)
  reload_data!()
  return Base.invokelatest(render, message)
end
