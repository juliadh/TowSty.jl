"""
    templaterender(templatepath::String, data::Dict)

Render a template with provided data and return an HTTP response.
Reads the template file, compiles it using Otera, and renders it with the given data.

* `templatepath::String`: Path to the template file
* `data::Dict`: Data to pass to the template
"""
function templaterender(templatepath::String, data::Dict)
  template = read(templatepath, String)
  render = otera(template)

  return Base.invokelatest(render, data)
end

"""
    templaterender_static(templatepath::String, data::Dict)

Render a template with provided data and return raw HTML string.
Similar to `templaterender` but extracts and returns the HTML content as a string
instead of an HTTP response, suitable for static site generation.

* `templatepath::String`: Path to the template file
* `data::Dict`: Data to pass to the template
"""
function templaterender_static(templatepath::String, data::Dict)
  template = read(templatepath, String)
  render = otera(template)
  html = Base.invokelatest(render, data)

  # Extraire le HTML si c'est une réponse HTTP
  if isa(html, HTTP.Messages.Response)
    return String(html.body)
  else
    return String(html)
  end
end