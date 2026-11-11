-- HTML only: replaces the hand-written "Protocol ID / Version / Author" lines at the
-- top of every protocol and buffer with one tidy row of badges (ID, version, last
-- revised) plus a Download PDF button. The PDF keeps its original header.
-- "Last revised" comes from the document's Version history table via _registry.tsv.

if not FORMAT:match("html") then return {} end

local function esc(s)
  return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"))
end

local function stringify(x) return pandoc.utils.stringify(x or "") end

local function read_revised(id)
  local dir = quarto.project.directory or os.getenv("QUARTO_PROJECT_DIR")
  if not dir or not id or id == "" then return nil end
  local f = io.open(dir .. "/protocols_src/_registry.tsv", "r")
  if not f then return nil end
  local header = true
  local revcol = nil
  for line in f:lines() do
    local cols = {}
    for c in (line .. "\t"):gmatch("([^\t]*)\t") do table.insert(cols, c) end
    if header then
      for i, name in ipairs(cols) do if name == "revised" then revcol = i end end
      header = false
    elseif cols[1] == id and revcol then
      f:close()
      return cols[revcol]
    end
  end
  f:close()
  return nil
end

local function fmt_date(d)
  local y, m, day = (d or ""):match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
  if not y then return d end
  local names = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"}
  return string.format("%d %s %s", tonumber(day), names[tonumber(m)] or m, y)
end

local meta_ref = nil

function Meta(m) meta_ref = m end

local function is_header_para(el)
  if el.t ~= "Para" and el.t ~= "Plain" then return false end
  local first = el.content[1]
  return first and first.t == "Strong" and stringify(first):match("^Protocol ID") ~= nil
end

function Pandoc(doc)
  local id = stringify(doc.meta.protocol_id)
  if id == "" then return nil end
  local version = stringify(doc.meta.version)
  local revised = read_revised(id)
  local input = quarto.doc.input_file or ""
  local base = input:match("([^/]+)%.qmd$")

  -- drop the old header paragraph (first one only)
  local blocks, removed = pandoc.List(), false
  for _, b in ipairs(doc.blocks) do
    if not removed and is_header_para(b) then
      removed = true
    else
      blocks:insert(b)
    end
  end
  if not removed then return nil end

  local html = {'<div class="doc-badges">'}
  table.insert(html, '<span class="doc-badge doc-id">' .. esc(id) .. '</span>')
  if version ~= "" then table.insert(html, '<span class="doc-badge">' .. esc(version) .. '</span>') end
  if revised and revised ~= "" and revised ~= "NA" then
    table.insert(html, '<span class="doc-badge">Last revised ' .. esc(fmt_date(revised)) .. '</span>')
  end
  if base then
    table.insert(html, '<a class="doc-pdf" href="' .. esc(base) .. '.pdf">Download PDF</a>')
  end
  table.insert(html, '</div>')
  blocks:insert(1, pandoc.RawBlock("html", table.concat(html, "")))
  doc.blocks = blocks
  return doc
end
