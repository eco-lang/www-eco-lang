# Codebase Structure

## Directory Layout
```
app/                    # elm-pages application code
  Route/                # File-based routing (each file = a URL route)
    Index.elm           # / (landing page, custom layout bypassing Layout.view)
    Blog.elm            # /blog (blog listing)
    Blog/Slug_.elm      # /blog/:slug (individual blog posts, preRender)
    About.elm           # /about
    Tags.elm            # /tags
    Tags/Slug_.elm      # /tags/:slug (posts filtered by tag, preRender)
    Docs.elm            # /docs (docs index, loads first doc page)
    Docs/Slug_.elm      # /docs/:slug (individual doc page, preRender)
  Shared.elm            # Shared state, model, msg; wraps pages with layout
  View.elm              # View type alias { title : String, body : List (Html msg) }
  Effect.elm            # Effect type for side effects (Cmd wrapper)
  ErrorPage.elm         # Error pages (NotFound, InternalError)
  Site.elm              # Site-wide config and head tags
  Api.elm               # API routes and manifest generation

src/                    # Shared library code
  Settings.elm          # Site config: canonicalUrl, title, subtitle, author, locale
  Layout.elm            # Main layout wrapper: header, nav, footer; seoHeaders
  Content/
    Blogpost.elm        # Blog content loading: Blogpost/Metadata types, allBlogposts, allTags, blogpostFromSlug
    Docs.elm            # Doc content loading: DocPage/DocMetadata/TocSection types, allDocPages, docPageFromSlug, tocSections
    About.elm           # Author data loading: Author type, allAuthors, defaultAuthor