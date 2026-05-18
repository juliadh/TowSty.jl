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

@get route("/{slug}") function (req::HTTP.Request, slug::String)
  # first check if it's a singlepage
  pages = singlepages()
  pageidx = findfirst(p -> p[:slug] == slug, pages)

  if !isnothing(pageidx)
    data = getsinglepage(slug, BASEURL)
    get(data, :error, false) && return HTTP.Response(404, ["Error-Message" => data[:message]])
    templatepath = joinpath(TEMPLATES_PATH, "article.html")
    return templaterender(templatepath, data)
  end

  # otherwise, treat as a corpus
  data = getcorpus(slug, BASEURL)
  get(data, :error, false) && return HTTP.Response(404, ["Error-Message" => data[:message]])
  templatepath = joinpath(TEMPLATES_PATH, "corpus.html")

  return templaterender(templatepath, data)
end

@get route("/{slug}/data") function (req::HTTP.Request, slug::String)
  # first check if it's a singlepage
  pages = singlepages()
  pageidx = findfirst(p -> p[:slug] == slug, pages)

  if !isnothing(pageidx)
    data = getsinglepage(slug, BASEURL)
    get(data, :error, false) && return HTTP.Response(404, ["Error-Message" => data[:message]])
    return data
  end

  # otherwise, treat as a corpus
  data = getcorpus(slug, BASEURL)
  get(data, :error, false) && return HTTP.Response(404, ["Error-Message" => data[:message]])
  return data
end

@get route("/{corpus}/{article}") function (req::HTTP.Request, corpus::String, article::String)
  data = getarticle(corpus, article, BASEURL)
  get(data, :error, false) && return HTTP.Response(404, ["Error-Message" => data[:message]])
  templatepath = joinpath(TEMPLATES_PATH, "article.html")

  return templaterender(templatepath, data)
end

@get route("/{corpus}/{article}/data") function (req::HTTP.Request, corpus::String, article::String)
  data = getarticle(corpus, article, BASEURL)
  get(data, :error, false) && return HTTP.Response(404, ["Error-Message" => data[:message]])

  return data
end

@get route("/articles.json") function()
  data = searchindex()

  return data
end

@get route("/recherche") function()
  metadata = meta()
  data = Dict(:meta => metadata)
  templatepath = joinpath(TEMPLATES_PATH, "recherche.html")

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
    message = Dict(:message => "Clé de vérification erronée. La mise à jour est annulée !")
  else
    # Hash is valid, proceed with update
    try
      backupworkspace()

      data = getworkspace(workspaceid, styloapikey, backup=false) |> string2symbol

      if isnothing(data) || !haskey(data, :name) # Invalid data received
        @warn "Invalid workspace data received"
        restoreworkspace()
        reload_data!()
        message = Dict(:message => "Une erreur s'est produite lors de la récupération des données. Les anciennes données ont été restaurées.")
      else
        try # try to process the new data
          reload_data!()
          message = Dict(
            :message => "Données mises à jour avec succès !",
            :log => processlog()
          )
        catch process_error # Processing failed, restore backup
          @error "Data processing failed" exception=process_error
          restoreworkspace()
          reload_data!()
          message = Dict(:message => "Erreur lors du traitement des données : $(process_error). La anciennes données ont été restaurées." )
        end
      end
    catch e # Fetch failed, try to restore
      @error "Update failed" exception=e
      if restoreworkspace()
        reload_data!()
      end
      message = Dict(:message => "Erreur lors de la récupération des données : $(e). Les anciennes données ont été restaurées.")
    end
  end

  templatepath = joinpath(TEMPLATES_PATH, "log.html")
  template = read(templatepath, String)
  render = otera(template)
  
  message[:homeurl] = route("/")
  if !haskey(message, :log)
    message[:log] = []
  end
  return Base.invokelatest(render, message)
end
