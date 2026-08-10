---
layout: index.lax

hero: 
  title: "Build Fast. Ship Faster."
  description: "LUAX is a 12ms Lua-powered Static Site Generator. No Node.js, no bloat, no 500MB node_modules. Just one binary, Markdown, and blazing fast LAX templates."
  image: /img/cosmicluax.webp

intro:
  title: "Why LUAX?"
  description: "The modern web is slow and bloated"
  text: "We were tired of waiting 30 seconds for a site to build. Astro needs Node, Hugo needs Go templates that feel ancient. LUAX uses Lua 5.4 + LAX (Blade-like syntax) — familiar, fast, and fun. Write markdown, include partials, ship in milliseconds."
  image: /img/cyberluax.webp

about:
  title: "One Binary, Everything Included"
  description: "Zero dependencies, maximum speed"
  text: "LUAX starter comes with live reload server, YAML data support, layout inheritance, partials, and GitHub Pages ready. Clone, edit src/index.md, run luax build. Done."
  image: /img/axcoralogored.webp
  button: 
    text: Explore All Article
    url: "/posts/"

---
# LUAX Starter is Ready

This is your starter content. The three blocks above are mapped to `index.lax` via `hero`, `intro`, and `about`.

**To edit:**
- `hero.title` -> controls Hero section
- `intro.title` -> controls Intro section  
- `about.title` -> controls About section
- Text below this `---` is your free markdown content rendered via `@content`.

Luax build in 12ms. No node_modules.
## Welcome to LUAX

You just cloned the fastest Lua SSG on the planet. No `node_modules`, no `npm install`, no 300MB dependencies. Just `luax build`.

### Why LUAX?

**Modern SSGs are bloated.** Astro, Next, Hugo - they all need a maze of config. LUAX is one binary, markdown, and LAX templates inspired by Blade. The badger guards the burrow.

**Benchmark:** Build 1000 pages in 12ms. Not seconds. Milliseconds.

### Starter Structure

```
.
├── data/              # YAML / JSON global data
├── src/               # Your markdown content
│   └── index.md       # This file
├── templates/
│   ├── layouts/       # base.lax, index.lax
│   └── partials/      # header, hero, footer, etc
├── dist/              # Build output (auto generated)
└── build.lua          # Build script
```

### How to Write

1.  **Edit this file** `src/index.md` - frontmatter is your data for `index.lax`
2.  **Add partials** in `templates/partials/` - use `@include('partial-name')`
3.  **Looping & Logic** - LAX supports Blade-like syntax:
    ```lax
    @foreach(posts as post)
      <h2>{{ post.title }}</h2>
    @endforeach

    @if(show_hero)
      @include('hero')
    @endif
    ```

### Deploy

```bash
luax build
luax start   # preview at localhost:3000
```

Push to GitHub, GitHub Pages auto-deploy in 20s.
