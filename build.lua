local c = {
    reset = "\27[0m",
    bold = "\27[1m",
    green = "\27[32m",
    blue = "\27[34m",
    cyan = "\27[36m",
    dim = "\27[2m",
    magenta = "\27[35m",
    yellow = "\27[33m"
}

print(c.bold.. c.magenta.. "🚀 LUAX SSG v4.0".. c.reset)
print(c.dim.. "▶ LAX Template Engine".. c.reset.. "\n")

local Lax = dofile("lax.lua")
local yaml = dofile("yaml.lua")

local function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*all")
    f:close()
    return content
end

local function write_file(path, content)
    if not path or path == "" then print("ERROR: write_file called with empty path") return end
    if not content then print("ERROR: write_file called with empty content for: ".. path) return end
    local f = io.open(path, "w")
    if not f then print("ERROR: Cannot open file: ".. tostring(path)) return end
    f:write(content)
    f:close()
end

local function list_files(dir)
    local files = {}
    local cmd
    if package.config:sub(1,1) == "\\" then cmd = 'dir "'.. dir.. '" /b 2>nul' else cmd = 'ls -1 "'.. dir.. '" 2>/dev/null' end
    local handle = io.popen(cmd)
    if handle then for file in handle:lines() do table.insert(files, file) end handle:close() end
    return files
end

local function copy_public()
    local public_dir = "public"
    if package.config:sub(1,1) == "\\" then
        local check = io.popen('if exist "'.. public_dir.. '\\" (echo 1) else (echo 0)')
        local result = check:read("*all") check:close()
        if result:match("0") then return end
        os.execute('xcopy "'.. public_dir.. '" "dist\\" /E /I /Y >nul 2>nul')
    else
        local check = io.popen('test -d "'.. public_dir.. '" && echo 1 || echo 0')
        local result = check:read("*all") check:close()
        if result:match("0") then return end
        os.execute('cp -r "'.. public_dir.. '"/* "dist/" 2>/dev/null')
    end
    print(c.green.. "✔".. c.reset.. " Public assets copied")
end

local function parse_markdown(content)
    local html = content
    local frontmatter = {}
    local lines = {}
    for line in html:gmatch("[^\n]+") do table.insert(lines, line) end
    if #lines > 0 and lines[1] == "---" then
        local end_idx = nil
        for i = 2, #lines do if lines[i] == "---" then end_idx = i break end end
        if end_idx then
            local fm_raw = table.concat(lines, "\n", 2, end_idx-1)
            frontmatter = yaml.parse(fm_raw) or {}
            local new_lines = {}
            for i = end_idx + 1, #lines do table.insert(new_lines, lines[i]) end
            html = table.concat(new_lines, "\n")
        end
    end
    local result = {}
    local in_code = false
    local code_block = {}
    local in_list = false
    local list_items = {}
    for line in html:gmatch("[^\n]*") do
        local trimmed = line:gsub("^%s*", ""):gsub("%s*$", "")
        if trimmed == "" then
            if in_list and #list_items > 0 then table.insert(result, "<ul>".. table.concat(list_items, "\n").. "</ul>") list_items = {} in_list = false end
            goto continue
        end
        if trimmed:match("^---$") or trimmed:match("^%*%*%*$") or trimmed:match("^___$") then
        if in_list and #list_items > 0 then table.insert(result, "<ul>".. table.concat(list_items, "\n").. "</ul>") list_items = {} in_list = false end
        table.insert(result, "<hr>") goto continue
    end
    if trimmed:match("^```") then
        if not in_code then in_code = true code_block = {}
        else in_code = false local code_content = table.concat(code_block, "\n") code_content = code_content:gsub("\n$", "") table.insert(result, "<pre class='bg-dark text-white p-4 rounded-5 overflow-auto w-100'><code>".. code_content.. "</code></pre>") code_block = {} end
        goto continue
    end
        if in_code then table.insert(code_block, line) goto continue end
        if trimmed:match("^# ") then if in_list and #list_items > 0 then table.insert(result, "<ul>".. table.concat(list_items, "\n").. "</ul>") list_items = {} in_list = false end local text = trimmed:gsub("^# ", "") table.insert(result, "<h1>".. text.. "</h1>") goto continue end
        if trimmed:match("^## ") then if in_list and #list_items > 0 then table.insert(result, "<ul>".. table.concat(list_items, "\n").. "</ul>") list_items = {} in_list = false end local text = trimmed:gsub("^## ", "") table.insert(result, "<h2>".. text.. "</h2>") goto continue end
        if trimmed:match("^### ") then if in_list and #list_items > 0 then table.insert(result, "<ul>".. table.concat(list_items, "\n").. "</ul>") list_items = {} in_list = false end local text = trimmed:gsub("^### ", "") table.insert(result, "<h3>".. text.. "</h3>") goto continue end
        if trimmed:match("^#### ") then if in_list and #list_items > 0 then table.insert(result, "<ul>".. table.concat(list_items, "\n").. "</ul>") list_items = {} in_list = false end local text = trimmed:gsub("^#### ", "") table.insert(result, "<h4>".. text.. "</h4>") goto continue end
        if trimmed:match("^- ") then
            local text = trimmed:gsub("^- ", "") text = text:gsub("%*%*(.-)%*%*", "<strong>%1</strong>") text = text:gsub("%*(.-)%*", "<em>%1</em>") text = text:gsub("`(.-)`", "<code>%1</code>") text = text:gsub("%[(.-)%]%((.-)%)", '<a href="%2">%1</a>') text = text:gsub("!%[(.-)%]%((.-)%)", '<img src="%2" alt="%1">')
            table.insert(list_items, "<li>".. text.. "</li>") in_list = true goto continue
        end
        if in_list and #list_items > 0 then table.insert(result, "<ul>".. table.concat(list_items, "\n").. "</ul>") list_items = {} in_list = false end
        local text = trimmed text = text:gsub("%*%*(.-)%*%*", "<strong>%1</strong>") text = text:gsub("%*(.-)%*", "<em>%1</em>") text = text:gsub("`(.-)`", "<code>%1</code>") text = text:gsub("%[(.-)%]%((.-)%)", '<a href="%2">%1</a>') text = text:gsub("!%[(.-)%]%((.-)%)", '<img src="%2" alt="%1">')
        table.insert(result, "<p>".. text.. "</p>")
        ::continue::
    end
    if in_list and #list_items > 0 then table.insert(result, "<ul>".. table.concat(list_items, "\n").. "</ul>") end
    html = table.concat(result, "\n")
    return html, frontmatter
end

local function load_yaml_file(path)
    local content = read_file(path)
    if not content then return nil end
    return yaml.parse(content)
end

local function load_metadata()
    return load_yaml_file("data/metadata.yaml") or load_yaml_file("metadata.yaml") or {}
end

-- FIX: data_all harus di atas sebelum render
local data_all = {}
local function load_data_folder()
    local all = {}
    for _, f in ipairs(list_files("data")) do
        if f:match("%.yaml$") then
            local name = f:gsub("%.yaml$","")
            local d = load_yaml_file("data/"..f)
            if d then all[name] = d end
        end
    end
    return all
end

local function load_partials()
    local partials = {}
    local files = list_files("templates/partials")
    if files then
        for _, file in ipairs(files) do
            if file:match("%.lax$") then
                local content = read_file("templates/partials/".. file)
                if content then local name = file:gsub("%.lax$", "") partials[name] = content end
            end
        end
    end
    return partials
end

local function render_content_template(template_name, context, metadata, partials)
    local template_paths = {
        "templates/layouts/".. template_name,
        "templates/layouts/".. template_name.. ".lax",
        "templates/".. template_name,
        "templates/".. template_name.. ".lax",
    }
    local template_file = nil
    for _, path in ipairs(template_paths) do template_file = read_file(path) if template_file then break end end
    if not template_file then print("ERROR: Template not found: ".. tostring(template_name)) return "" end
    local engine = Lax.new(template_file)
    for k, v in pairs(context) do engine:set(k, v) end
    engine:set("metadata", metadata)
    engine:set("site", metadata)
    engine:set("data", data_all or {})
    engine:set("bro", data_all.bro or metadata)
    if data_all then for k,v in pairs(data_all) do engine:set(k, v) end end
    for name, content in pairs(partials) do engine:partial(name, content) end
    local result = engine:render()
    if not result then print("ERROR: render returned nil for: ".. tostring(template_name)) return "" end
    return result
end

local function get_image_with_fallback(item_image, metadata)
    local image = item_image or ""
    if image == "" then image = metadata.image or "" end
    return image
end

local function build_posts(metadata)
    local posts = {}
    local files = list_files("src/posts")
    if not files then return posts end
    for _, file in ipairs(files) do
        if file:match("%.md$") then
            local content = read_file("src/posts/".. file)
            if content then
                local html, fm = parse_markdown(content)
                local slug = file:gsub("%.md$", "")
                local layout_name = fm.layout or "default.lax"
                local tags = {}
                if fm.tags then
                    if type(fm.tags) == "table" then tags = fm.tags
                    else for tag in fm.tags:gmatch("[^,]+") do local clean_tag = tag:gsub("^%s*(.-)%s*$", "%1") if clean_tag ~= "" then table.insert(tags, clean_tag) end end end
                end
                local post = {title = fm.title or slug, date = fm.date or os.date("%Y-%m-%d"), slug = slug, excerpt = fm.excerpt or "", description = fm.description or "", tags = tags, author = fm.author or "LUAX Team", content = html, url = "/".. slug.. ".html", image = fm.image or metadata.image, layout = layout_name}
                if post.excerpt == "" then local text = html:gsub("<[^>]+>", "") post.excerpt = text:sub(1, 150).. "..." end
                post.image = get_image_with_fallback(post.image, metadata)
                table.insert(posts, post)
            end
        end
    end
    table.sort(posts, function(a, b) return a.date > b.date end)
    for i, post in ipairs(posts) do post.index = i post.total = #posts if i > 1 then post.prev_post = posts[i-1] end if i < #posts then post.next_post = posts[i+1] end end
    return posts
end

local function build_pages(metadata)
    local pages = {}
    local files = list_files("src/pages")
    if files then
        for _, file in ipairs(files) do
            if file:match("%.md$") then
                local content = read_file("src/pages/".. file)
                if content then
                    local html, fm = parse_markdown(content)
                    local slug = file:gsub("%.md$", "")
                    local layout_name = fm.layout or "default.lax"
                    local page = {title = fm.title or slug, description = fm.description or "", image = fm.image or metadata.image, slug = slug, content = html, url = "/".. slug.. ".html", layout = layout_name}
                    page.image = get_image_with_fallback(page.image, metadata)
                    table.insert(pages, page)
                end
            end
        end
    end
    return pages
end

local function format_date_for_rss(date_str)
    if not date_str or date_str == "" then return os.date("%a, %d %b %Y %H:%M:%S +0000") end
    local year, month, day = date_str:match("(%d+)-(%d+)")
    if year and month and day then local timestamp = os.time({year = tonumber(year), month = tonumber(month), day = tonumber(day), hour = 0, min = 0, sec = 0}) return os.date("%a, %d %b %Y %H:%M:%S +0000", timestamp) end
    return os.date("%a, %d %b %Y %H:%M:%S +0000")
end

local function format_date_for_sitemap(date_str)
    if not date_str or date_str == "" then return os.date("%Y-%m-%d") end
    local year, month, day = date_str:match("(%d+)-(%d+)-(%d+)")
    if year and month and day then return year.. "-".. month.. "-".. day end
    return os.date("%Y-%m-%d")
end

local function generate_sitemap(posts, site_url)
    local sitemap = '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n <url>\n <loc>'.. site_url.. '</loc>\n <lastmod>'.. os.date("%Y-%m-%d").. '</lastmod>\n <changefreq>daily</changefreq>\n <priority>1.0</priority>\n </url>\n'
    for _, post in ipairs(posts) do sitemap = sitemap.. ' <url>\n <loc>'.. site_url.. post.url.. '</loc>\n <lastmod>'.. format_date_for_sitemap(post.date).. '</lastmod>\n <changefreq>monthly</changefreq>\n <priority>0.8</priority>\n </url>\n' end
    sitemap = sitemap.. '</urlset>\n'
    return sitemap
end

local function generate_rss(posts, metadata, site_url)
    local rss = '<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">\n <channel>\n <title>'.. (metadata.title or "LUAX SSG").. '</title>\n <link>'.. site_url.. '</link>\n <description>'.. (metadata.description or "").. '</description>\n <language>en-us</language>\n <lastBuildDate>'.. os.date("%a, %d %b %Y %H:%M:%S +0000").. '</lastBuildDate>\n <atom:link href="'.. site_url.. 'feed.xml" rel="self" type="application/rss+xml" />\n'
    for _, post in ipairs(posts) do rss = rss.. ' <item>\n <title>'.. post.title.. '</title>\n <link>'.. site_url.. post.url.. '</link>\n <description><![CDATA['.. post.excerpt.. ']]></description>\n <pubDate>'.. format_date_for_rss(post.date).. '</pubDate>\n <guid>'.. site_url.. post.url.. '</guid>\n </item>\n' end
    rss = rss.. ' </channel>\n</rss>\n'
    return rss
end

local start_time = os.clock()
data_all = load_data_folder()
local metadata = data_all.bro or data_all.metadata or load_metadata()
if not metadata.home then
    print(c.yellow.. "⚠ WARNING: metadata.home is nil, creating fallback".. c.reset)
    metadata.home = {title = metadata.title or "LUAX SSG", description = metadata.description or "", image = metadata.image or ""}
end
if not metadata.home.title then metadata.home.title = metadata.title or "LUAX SSG" end
if not metadata.home.description then metadata.home.description = metadata.description or "" end
if not metadata.home.image then metadata.home.image = metadata.image or "" end
local partials = load_partials()
if package.config:sub(1,1) == "\\" then os.execute("mkdir dist 2>nul") os.execute("mkdir dist\\img 2>nul") os.execute("mkdir dist\\tags 2>nul") else os.execute("mkdir -p dist 2>/dev/null") os.execute("mkdir -p dist/img 2>/dev/null") os.execute("mkdir -p dist/tags 2>/dev/null") end
copy_public()
local posts = build_posts(metadata)
local pages = build_pages(metadata)
print("\n".. c.cyan.. "▶".. c.reset.. " Building ".. c.bold.. #posts.. c.reset.. " posts")
for _, post in ipairs(posts) do
    local page_title = post.title ~= "" and post.title or (metadata.title or "LUAX SSG")
    local page_description = post.excerpt ~= "" and post.excerpt or (metadata.description or "")
    local page_image = post.image
    local page_url = post.url or "/"
    local has_tags = post.tags and #post.tags > 0
    local context = {title = page_title, description = page_description, image = page_image, current_url = page_url, date = post.date, content = post.content, tags = post.tags, post = post, has_tags = has_tags, base_url = "..", og_type = "article", og_title = page_title, og_description = page_description, og_image = page_image, og_url = page_url, json_ld_type = "BlogPosting", json_ld_headline = page_title, json_ld_description = page_description, json_ld_url = page_url, json_ld_date = post.date, json_ld_author = post.author or "LUAX Team"}
    context.metadata = metadata
    local html = render_content_template("layouts/post.lax", context, metadata, partials)
    write_file("dist/".. post.slug.. ".html", html)
    print(" ".. c.green.. "✔".. c.reset.. " ".. c.dim.. post.url.. c.reset)
end
print("\n".. c.cyan.. "▶".. c.reset.. " Building ".. c.bold.. #pages.. c.reset.. " pages")
for _, page in ipairs(pages) do
    local page_title = page.title ~= "" and page.title or (metadata.title or "LUAX SSG")
    local page_description = page.description ~= "" and page.description or (metadata.description or "")
    local page_image = page.image
    local page_url = page.url or "/"
    local context = {title = page_title, description = page_description, image = page_image, current_url = page_url, content = page.content, posts = posts, base_url = "..", og_type = "website", og_title = page_title, og_description = page_description, og_image = page_image, og_url = page_url, json_ld_type = "WebPage", json_ld_headline = page_title, json_ld_description = page_description, json_ld_url = page_url, json_ld_date = os.date("%Y-%m-%d"), json_ld_author = "LUAX Team"}
    context.metadata = metadata
    local html = render_content_template(page.layout, context, metadata, partials)
    write_file("dist/".. page.slug.. ".html", html)
    print(" ".. c.green.. "✔".. c.reset.. " ".. c.dim.. page.url.. c.reset)
end
local per_page = 6
local total_posts = #posts
local total_pages = math.max(1, math.ceil(total_posts / per_page))
if package.config:sub(1,1) == "\\" then os.execute("mkdir dist\\blog 2>nul") os.execute("mkdir dist\\blog\\page 2>nul") else os.execute("mkdir -p dist/blog 2>/dev/null") os.execute("mkdir -p dist/blog/page 2>/dev/null") end
for page_num = 1, total_pages do
    local start_idx = (page_num - 1) * per_page + 1
    local end_idx = math.min(page_num * per_page, total_posts)
    local page_posts = {}
    for i = start_idx, end_idx do table.insert(page_posts, posts[i]) end
    local pagination_html = ""
if total_pages > 1 then
    pagination_html = '<nav aria-label="Blog posts pagination"><ul class="pagination justify-content-center">'
    if page_num > 1 then if page_num == 2 then pagination_html = pagination_html.. '<li class="page-item"><a class="page-link" href="/blog.html" aria-label="Previous"><span aria-hidden="true">&laquo;</span></a></li>' else pagination_html = pagination_html.. '<li class="page-item"><a class="page-link" href="/blog/page/'.. (page_num - 1).. '.html" aria-label="Previous"><span aria-hidden="true">&laquo;</span></a></li>' end else pagination_html = pagination_html.. '<li class="page-item disabled"><span class="page-link" aria-hidden="true">&laquo;</span></li>' end
    for i = 1, total_pages do if i == page_num then pagination_html = pagination_html.. '<li class="page-item active" aria-current="page"><span class="page-link">'.. i.. '</span></li>' else if i == 1 then pagination_html = pagination_html.. '<li class="page-item"><a class="page-link" href="/blog.html">'.. i.. '</a></li>' else pagination_html = pagination_html.. '<li class="page-item"><a class="page-link" href="/blog/page/'.. i.. '.html">'.. i.. '</a></li>' end end end
    if page_num < total_pages then pagination_html = pagination_html.. '<li class="page-item"><a class="page-link" href="/blog/page/'.. (page_num + 1).. '.html" aria-label="Next"><span aria-hidden="true">&raquo;</span></a></li>' else pagination_html = pagination_html.. '<li class="page-item disabled"><span class="page-link" aria-hidden="true">&raquo;</span></li>' end
    pagination_html = pagination_html.. '</ul></nav>'
end
    local context = {title = page_num == 1 and "Blog" or "Blog - Page ".. page_num, description = "All blog posts", posts = page_posts, pagination = pagination_html, current_url = page_num == 1 and "/blog.html" or "/blog/page/".. page_num.. ".html", base_url = page_num == 1 and "" or "..", og_type = "website", og_title = page_num == 1 and "Blog" or "Blog - Page ".. page_num, og_description = "All blog posts", og_image = metadata.image or "", og_url = page_num == 1 and "/blog.html" or "/blog/page/".. page_num.. ".html", json_ld_type = "WebPage", json_ld_headline = page_num == 1 and "Blog" or "Blog - Page ".. page_num, json_ld_description = "All blog posts", json_ld_url = page_num == 1 and "/blog.html" or "/blog/page/".. page_num.. ".html", json_ld_date = os.date("%Y-%m-%d"), json_ld_author = "LUAX Team"}
    context.metadata = metadata
    local html = render_content_template("layouts/blog.lax", context, metadata, partials)
    if page_num == 1 then write_file("dist/blog.html", html) else write_file("dist/blog/page/".. page_num.. ".html", html) end
end
local redirect = '<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0; url=/blog.html"></head><body><a href="/blog.html">Redirecting...</a></body></html>'
write_file("dist/blog/page/index.html", redirect)
write_file("dist/blog/index.html", redirect)
if posts and #posts > 0 then
    local all_tags = {}
    for _, post in ipairs(posts) do if post.tags and #post.tags > 0 then for _, tag in ipairs(post.tags) do local clean_tag = tag:lower():gsub(" ", "-") if not all_tags[clean_tag] then all_tags[clean_tag] = {name = tag, posts = {}} end table.insert(all_tags[clean_tag].posts, post) end end end
    local tag_names = {}
    for clean_tag, data in pairs(all_tags) do table.insert(tag_names, {clean = clean_tag, name = data.name}) end
    table.sort(tag_names, function(a, b) return a.name < b.name end)
    if #tag_names > 0 then
        local tags_context = {title = "Tags - ".. (metadata.title or "LUAX SSG"), description = "All tags- ".. (metadata.title or "LUAX SSG"), tags = tag_names, base_url = "", current_url = "/tags", og_type = "website", og_title = "Tags - ".. (metadata.title or "LUAX SSG"), og_description = "All tags", og_image = metadata.image or "", og_url = "/tags", json_ld_type = "WebPage", json_ld_headline = "Tags", json_ld_description = "All tags", json_ld_url = "/tags", json_ld_date = os.date("%Y-%m-%d"), json_ld_author = "LUAX Team"}
        tags_context.metadata = metadata
        local tags_html = render_content_template("layouts/tags.lax", tags_context, metadata, partials)
        write_file("dist/tags/index.html", tags_html)
        for clean_tag, data in pairs(all_tags) do
            local tag_posts = data.posts table.sort(tag_posts, function(a, b) return a.date > b.date end)
            local post_count = #tag_posts
            local tag_context = {title = data.name.. " - ".. (metadata.title or "LUAX SSG"), description = "Posts tagged with ".. data.name.. " (".. post_count.. " posts)", tag = data.name, tag_clean = clean_tag, posts = tag_posts, post_count = post_count, debug_posts = #tag_posts, base_url = "..", current_url = "/tags/".. clean_tag, og_type = "website", og_title = data.name.. " - ".. (metadata.title or "LUAX SSG"), og_description = "Posts tagged with ".. data.name.. " (".. post_count.. " posts)", og_image = metadata.image or "", og_url = "/tags/".. clean_tag, json_ld_type = "WebPage", json_ld_headline = data.name, json_ld_description = "Posts tagged with ".. data.name.. " (".. post_count.. " posts)", json_ld_url = "/tags/".. clean_tag, json_ld_date = os.date("%Y-%m-%d"), json_ld_author = "LUAX Team"}
            tag_context.metadata = metadata
            local tag_html = render_content_template("layouts/tag.lax", tag_context, metadata, partials)
            write_file("dist/tags/".. clean_tag.. ".html", tag_html)
            print(" ".. c.green.. "✔".. c.reset.. " ".. c.dim.. "/tags/".. clean_tag.. ".html (".. post_count.. " posts)".. c.reset)
        end
    end
end
local site_url = metadata.url or "/"
local index_posts = {}
for i = 1, math.min(6, #posts) do table.insert(index_posts, posts[i]) end
local index_context = {title = metadata.home and metadata.home.title or metadata.title or "LUAX SSG", description = metadata.home and metadata.home.description or metadata.description or "", posts = index_posts, pages = pages, current_url = "/", base_url = "", og_type = "website", og_title = metadata.title or "LUAX SSG", og_description = metadata.description or "", og_image = metadata.image or "", og_url = site_url, json_ld_type = "WebSite", json_ld_headline = metadata.title or "LUAX SSG", json_ld_description = metadata.description or "", json_ld_url = site_url, json_ld_date = os.date("%Y-%m-%d"), json_ld_author = "LUAX Team"}
index_context.metadata = metadata
local html = render_content_template("layouts/index.lax", index_context, metadata, partials)
if html and html ~= "" then write_file("dist/index.html", html) else print("ERROR: Failed to render index.lax") end
write_file("dist/sitemap.xml", generate_sitemap(posts, site_url))
write_file("dist/feed.xml", generate_rss(posts, metadata, site_url))
write_file("dist/robots.txt", 'User-agent: *\nAllow: /\nSitemap: https://luax.axcora.com/sitemap.xml\n')
write_file("dist/humans.txt", '/* TEAM */\n Architect: Axcora Tech\n Website: '.. site_url.. '\n Labs: axcora.com\n/* SITE */\n Generator: LUAX SSG\n Built: '.. os.date("%Y-%m-%d %H:%M:%S").. '\n Powered by: Lua + LAX Template\n')
local build_time = os.clock() - start_time
print("\n".. c.green.. c.bold.. "▶ BUILD COMPLETE".. c.reset)
print(c.dim.. " Posts: ".. c.reset.. c.bold.. #posts.. c.reset)
print(c.dim.. " Pages: ".. c.reset.. c.bold.. #pages.. c.reset)
print(c.dim.. " Time: ".. c.reset.. string.format("%.3f", build_time).. "s")
print(c.dim.. " Dir: ".. c.reset.. "dist/\n")
print("\n".. c.green.. c.bold.. "LUAX BY AXCORA".. c.reset)
print(c.dim.. " Documentation: ".. c.reset.. "LUAX.AXCORA.COM")
print(c.dim.. " Lab1: ".. c.reset.. "AXCORA.COM")
print(c.dim.. " Lab2: ".. c.reset.. "AXCORA.MY.ID")