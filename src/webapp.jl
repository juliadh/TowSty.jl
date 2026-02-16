function route(path::String)
  normalizedbase = rstrip(BASEURL, '/')
  # baseurl should not start with /, so we add it
  prefix = normalizedbase == "" ? "" : "/" * normalizedbase
  return prefix * path
end

staticfiles("assets/static", route("/static"))

@get route("/") function()
  data = gethome(BASEURL)
  templatepath = joinpath(TEMPLATES_PATH, "index.html")

  return templaterender(templatepath, data)
end


# debug
@get route("/data") function()
  data = gethome(BASEURL)

  return data
end

@get route("/{corpus}") function (req::HTTP.Request, corpus::String)
  data = getcorpus(corpus, BASEURL)
  templatepath = joinpath(TEMPLATES_PATH, "corpus.html")

  return templaterender(templatepath, data)
end

@get route("/{corpus}/data") function (req::HTTP.Request, corpus::String)
  data = getcorpus(corpus, BASEURL)

  return data
end

@get route("/{corpus}/{article}") function (req::HTTP.Request, corpus::String, article::String)
  data = getarticle(corpus, article, BASEURL)
  templatepath = joinpath(TEMPLATES_PATH, "article.html")

  return templaterender(templatepath, data)
end

@get route("/{corpus}/{article}/data") function (req::HTTP.Request, corpus::String, article::String)
  data = getarticle(corpus, article, BASEURL)

  return data
end

@get route("/articles.json") function()
  data = searchindex()

  return data
end

@get route("/recherche") function()
  metadata = meta()
  metadata[:baseurl] = BASEURL
  data = Dict(:meta => metadata)
  templatepath = joinpath(TEMPLATES_PATH, "recherche.html")

  return templaterender(templatepath, data)
end

@get route("/bibliographie") function()
  data = getbibliography(BASEURL)
  templatepath = joinpath(TEMPLATES_PATH, "article.html")

  return templaterender(templatepath, data)
end

@get route("/workspace") function (req::HTTP.Request)
  templatepath = joinpath(TEMPLATES_PATH, "workspace.html")
  template = read(templatepath, String)
  render = otera(template)
  data = Dict(
    :meta => meta(),
    :content => ""
  )

  return Base.invokelatest(render, data)
end

@get route("/workspace/update") function (req::HTTP.Request)
  form = queryparams(req)
  styloapikey = get(form, "styloapikey", "")
  workspaceid = get(form, "workspaceid", "")
  hash = get(form, "hash", "")

  # check hash
  if !checkhash(hash)
    message = Dict(
      :message => "Clé de vérification erronée. La mise à jour est annulée !"
    )
  else
    # Hash is valid, proceed with update
    try
      # Create backup before update
      backupworkspace()
      
      # Fetch new workspace data
      data = getworkspace(workspaceid, styloapikey, backup=false) |> string2symbol

      if isnothing(data) || !haskey(data, :name)
        # Invalid data received
        @warn "Invalid workspace data received"
        restoreworkspace()
        reload_data!()
        message = Dict(
          :message => "Une erreur s'est produite lors de la récupération des données. Les anciennes données ont été restaurées."
        )
      else
        # Try to process the new data
        try
          reload_data!()
          message = Dict(
            :message => "Données mises à jour avec succès !"
          )
        catch process_error
          # Processing failed, restore backup
          @error "Data processing failed" exception=process_error
          restoreworkspace()
          reload_data!()
          message = Dict(
            :message => "Erreur lors du traitement des données : $(process_error). La anciennes données ont été restaurées."
          )
        end
      end
    catch e
      # Fetch failed, try to restore
      @error "Update failed" exception=e
      if restoreworkspace()
        reload_data!()
      end
      message = Dict(
        :message => "Erreur lors de la récupération des données : $(e). Les anciennes données ont été restaurées."
      )
    end
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
  # reload_data!()
  return Base.invokelatest(render, message)
end
