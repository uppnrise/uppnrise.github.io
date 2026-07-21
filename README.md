# bnacar.dev

The source for [bnacar.dev](https://bnacar.dev), a Jekyll portfolio and technical blog for Burhanettin Nacar.

The site includes a data-driven résumé, selected software projects, technical articles, print-friendly styles, structured SEO metadata, an RSS feed, and a sitemap. It is hosted with GitHub Pages and uses a custom domain.

## Local development

Requirements:

- Ruby and Bundler
- The Ruby versions supported by the locked `github-pages` gem

Install dependencies and start the development server:

```sh
bundle install
bundle exec jekyll serve
```

Open <http://localhost:4000>.

Build and run the regression checks:

```sh
bundle exec jekyll build
bundle exec ruby test/site_test.rb
```

## Content structure

- `_config.yml` contains site metadata, social profiles, and résumé section switches.
- `_data/` contains résumé and project content in YAML.
- `_posts/` contains technical articles in Markdown.
- `_layouts/` and `_includes/` define page structure.
- `_sass/` contains the component, page, responsive, and print styles.

Résumé sections use `section_<name>` switches in `_config.yml`. Keep a section disabled until its corresponding data file contains real content.

## Writing an article

Create `_posts/YYYY-MM-DD-slug.md` with this front matter:

```yaml
---
layout: post
title: "Article title"
date: YYYY-MM-DD
tags: [Tag One, Tag Two]
excerpt: "A concise description for listings, feeds, and search results."
---
```

The post layout renders the article title, publication date, and estimated reading time. Start the Markdown body with introductory text or an `##` section; do not repeat the title as an `#` heading.

Use consistent title-case tag names so related articles are grouped predictably.

## Deployment and checks

GitHub Pages publishes the repository using the versions pinned by the `github-pages` gem. Pull requests and pushes to the default branch run the site regression test in `.github/workflows/site-checks.yml`.

The test builds the site and verifies key metadata, post headings, accessible social links, portable internal URLs, section configuration, and placeholder-free public data.

## License

This project is available under the [MIT License](LICENSE.md).

## Contact

Email [mtbnacar@gmail.com](mailto:mtbnacar@gmail.com).
