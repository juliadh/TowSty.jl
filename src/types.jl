"""
    art

# Fields
- `title::String`
- `slug::String`
- `path::String`
- `meta::Dict`
- `corpus::Dict`
- `md::String`
- `html::String`
- `bib::String`
"""
Base.@kwdef struct articulus
  title::String
  slug::String
  path::String
  meta::Dict
  corpus::Dict
  md::String
  html::String
  bib::String
end

"""
    art(rawtitle::String, corpus::Dict, meta::Dict, md::String, html::String, bib::String)

"""
function articulus(rawtitle::String, corpus::Dict, meta::Dict, md::String, html::String, bib::String)

  htmltitle = markdowntohtml(rawtitle) |> stripparagraph |> String |> strip

  plaintitle = markdowntoplain(rawtitle) |> strip
  slug = formatpath(String(plaintitle))
  path = joinpath(get(corpus, :path, ""), slug)

  return articulus(
    title = htmltitle,
    slug = slug,
    path = path,
    meta = meta,
    corpus = corpus,
    md = md,
    html = html,
    bib = bib
  )
end
