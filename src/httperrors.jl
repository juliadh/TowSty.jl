const HTTP_STATUS = Dict(
  404 => "Page introuvable",
  500 => "Erreur interne du serveur"
)

function errorpage(status::Int, path::String; message::String="")
  label = isempty(message) ? get(HTTP_STATUS, status, "Une erreur s'est produite") : message
  homeurl = BASEURL == "" ? "/" : "/" * BASEURL

  templatepath = joinpath(PROJECT_PATH, "templates", "error.html")
  if isfile(templatepath)
    template = read(templatepath, String)
  else
    template = """<!DOCTYPE html>
<html lang="fr">
  <head>
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>
    <title>Erreur {{ status }}</title>
    <style>
      div {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        width: 100%;
        min-height: 100vh;
      }
      h1 {
        font-size: 3em;
        margin-bottom: 0.5em;
        color: IndianRed;
      }
      .message {
        font-size: 1.2em;
      }
    </style>
  </head>
  <body>
    <div>
      <h1>{{ status }}</h1>
      <p class="message">{{ message }}</p>
      <p><a href="{{ homeurl }}">← Retour à l'accueil</a></p>
    </div>
  </body>
</html>"""
  end

  render = otera(template)
  data = Dict(
    :status => status,
    :message => label,
    :homeurl => homeurl,
    :path => path
  )
  response = Base.invokelatest(render, data)
  return HTTP.Response(status, response.headers, body=response.body)
end

function errorMiddleware(handler)
  return function (req::HTTP.Request)
    try
      response = handler(req)
      errormessage = String(HTTP.header(response, "Error-Message", ""))
      if response.status == 404
        return errorpage(404, req.target; message=errormessage)
      elseif response.status >= 500
        return errorpage(Int(response.status), req.target; message=errormessage)
      end
      return response
    catch e
      @error "Server error" exception = (e, catch_backtrace())
      return errorpage(500, req.target)
    end
  end
end
