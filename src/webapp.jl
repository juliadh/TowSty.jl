function route(path::String)
  return rstrip(MOUNTPATH, '/') * path
end

staticfiles("assets/static", route("/static"))

@get route("/") function()
  data = gethome(MOUNTPATH)
  templatepath = joinpath(TEMPLATES_PATH, "index.html")

  return templaterender(templatepath, data)
end

# debug
@get route("/data") function()
  data = gethome(MOUNTPATH)

  return data
end

@get route("/{slug}") function (req::HTTP.Request, slug::String)
  # first check if it's a singlepage
  pages = singlepages()
  pageidx = findfirst(p -> p[:slug] == slug, pages)

  if !isnothing(pageidx)
    data = getsinglepage(slug, MOUNTPATH)
    get(data, :error, false) && return HTTP.Response(404, ["Error-Message" => data[:message]])
    templatepath = joinpath(TEMPLATES_PATH, "article.html")
    return templaterender(templatepath, data)
  end

  # otherwise, treat as a corpus
  data = getcorpus(slug, MOUNTPATH)
  get(data, :error, false) && return HTTP.Response(404, ["Error-Message" => data[:message]])
  templatepath = joinpath(TEMPLATES_PATH, "corpus.html")

  return templaterender(templatepath, data)
end

@get route("/{slug}/data") function (req::HTTP.Request, slug::String)
  # first check if it's a singlepage
  pages = singlepages()
  pageidx = findfirst(p -> p[:slug] == slug, pages)

  if !isnothing(pageidx)
    data = getsinglepage(slug, MOUNTPATH)
    get(data, :error, false) && return HTTP.Response(404, ["Error-Message" => data[:message]])
    return data
  end

  # otherwise, treat as a corpus
  data = getcorpus(slug, MOUNTPATH)
  get(data, :error, false) && return HTTP.Response(404, ["Error-Message" => data[:message]])
  return data
end

@get route("/{corpus}/{article}") function (req::HTTP.Request, corpus::String, article::String)
  data = getarticle(corpus, article, MOUNTPATH)
  get(data, :error, false) && return HTTP.Response(404, ["Error-Message" => data[:message]])
  templatepath = joinpath(TEMPLATES_PATH, "article.html")

  return templaterender(templatepath, data)
end

@get route("/{corpus}/{article}/data") function (req::HTTP.Request, corpus::String, article::String)
  data = getarticle(corpus, article, MOUNTPATH)
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

@get route("/rss") function()

  return HTTP.Response(200, ["Content-Type" => "application/xml"], body=generatefeed())
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

@post route("/workspace/update") function (req::HTTP.Request)
  form = formdata(req)
  styloapikey = get(form, "styloapikey", "")
  workspaceid = get(form, "workspaceid", "")
  hash = get(form, "hash", "")

  # check hash
  if !checkhash(hash)
    message = Dict{Symbol, Any}(:message => "Clé de vérification erronée. La mise à jour est annulée !")
  else
    # Hash is valid, proceed with update
    try
      backupworkspace()

      data = getworkspace(workspaceid, styloapikey, backup=false) |> string2symbol

      if isnothing(data) || !haskey(data, :name) # Invalid data received
        @warn "Invalid workspace data received"
        restoreworkspace()
        reloaddata()
        message = Dict{Symbol, Any}(:message => "Une erreur s'est produite lors de la récupération des données. Les anciennes données ont été restaurées.")
      else
        try # try to process the new data
          reloaddata()
          message = Dict(
            :message => "Données mises à jour avec succès !",
            :log => processlog()
          )
        catch process_error # Processing failed, restore backup
          @error "Data processing failed" exception=process_error
          restoreworkspace()
          reloaddata()
          message = Dict{Symbol, Any}(:message => "Erreur lors du traitement des données : $(process_error). La anciennes données ont été restaurées." )
        end
      end
    catch e # Fetch failed, try to restore
      @error "Update failed" exception=e
      if restoreworkspace()
        reloaddata()
      end
      message = Dict{Symbol, Any}(:message => "Erreur lors de la récupération des données : $(e). Les anciennes données ont été restaurées.")
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
