---
title: Changelog
---

All notable changes to this website are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and versions follow [Semantic Versioning](https://semver.org/): MAJOR for
redesigns, MINOR for new features, PATCH for fixes and content updates.

## [2.0.14] - 2026-10-19

### Changed
- Every food page now has an illustration. Added missing images to 50+
  pages (fish oils, game meats, exotic meats, eggs, nuts, beverages and
  more) using Wikimedia Commons files, each verified for relevance.
- Replaced the last 48 externally hotlinked images (blogspot, wordpress,
  shopify and similar sources that can rot or hotlink-block) with stable
  Wikimedia Commons equivalents. All 189 image URLs verified live.
- Quote fixes: 19 food pages gained quotes through 69 high-confidence
  alias tag mappings (waters→water, salmon-oil→salmon, bok-choy→cabbage,
  green-onion→onion and more). Remaining 41 gaps documented in a review
  list for category-mapping decisions.

## [2.0.13] - 2026-10-17

### Added
- "Ask a question" AI assistant on the FAQ page. The assistant answers
  only from Geoff Bond's books and *The Bond Briefing* (curated quotes
  and FAQ answers), citing the passage behind every claim. Questions
  are answered by GLM 5.3 Flash routed through private, encrypted
  model providers — no advertising, no data mining. Not medical
  advice, as always.

## [2.0.12] - 2026-10-13

### Added
- FAQ page (new "FAQ" nav item): 32 reader questions answered by Geoff
  Bond in *The Bond Briefing* Q&A column, curated from the 1999–2025
  archive and grouped into 9 categories (Salt & Electrolytes, Water &
  Hydration, Protein & Meat, Supplements & Vitamins, Fats & Oils,
  Sugar & Sweeteners, Grains & Breads, Dairy, Fruits & Vegetables).
  Every answer is verbatim with an issue citation and is searchable
  via the site search. Published with Geoff Bond's permission.

## [2.0.11] - 2026-10-11

### Added
- Site search (new "Search" nav item): a client-side full-text
  search over all 507 food pages and the other site pages, powered
  by [Pagefind](https://pagefind.app/). The search index is built
  in CI and shipped with the site — search runs entirely in the
  browser with no external calls. This is the site's first
  JavaScript, loaded only on the search page.

## [2.0.10] - 2026-10-11

### Added
- Site favicon: a traffic-light icon (green/amber/red — the food-tier
  motif) in SVG, ICO, PNG, and apple-touch-icon form.

### Changed
- `chocolate "drinks"` food page renamed to `chocolate drinks`,
  matching the book's wording.

### Fixed
- Manually reviewed the 6 quotes flagged by the page verifier — all
  are correctly cited (page-span quotations are cited at their start
  page, and the "duplicate" sentences genuinely appear on p. 102's
  Stage 3 tables). No citations changed.

## [2.0.9] - 2026-10-11

### Added
- 29 new food pages from a systematic audit of the *Paleo in a
  Nutshell* food-group tables against the food database. Highlights:
  asparagus, French fries, pretzels, Cheerios, Rice Krispies, Shredded
  Wheat, Weetabix, Tabasco, lentils (green and red), bologna,
  bratwurst, sardine oil, sesame oil, tallow, rice milk, erythritol,
  polyols, Demerara sugar, vetch, and chia/flax/hempseed butters and
  flours. Four new categories: Seed Products (Green-Green), Starchy
  Vegetables (Green-Yellow), Sugar Replacements (Green), and Animal
  Fats (Yellow-Red).
- `/data/foods.json` now falls back to the filename for foods without
  a title (matching how the site renders them) instead of shipping an
  empty name.

## [2.0.8] - 2026-10-11

### Added
- Machine-readable data feeds for a future native app: `/data/foods.json`
  (name, tier, category path, URL, foodtag for every food) and
  `/data/quotes.json` (book, chapter, page, tags, body, and a stable
  link into the Sources page for every quote).

## [2.0.7] - 2026-10-11

### Changed
- The Sources page is now a compact index: one line per quote (page
  number + food links) instead of the full passages, which are already
  shown on the food pages. Removed from the nav menu; reachable via a
  footer link and the per-quote citations.

## [2.0.6] - 2026-10-11

### Added
- New **Sources** page: every one of the 309 quotes from Geoff Bond's
  books, browsable by book and chapter, each entry linking back to the
  food pages it appears on.
- Quotes on food pages are now collapsible: the citation line (book,
  chapter, page) expands to reveal the full passage, and links to the
  quote's entry on the Sources page.
- Citations now include the chapter, from a new book/chapter map
  (`sources/chapters.json`) that `quote-check` also validates against.

### Fixed
- Two quote files slipped through validation: `dh-63-reptile-food` had a
  typo'd `.thml` extension, and `dh-93-cretan-breakfast` was misnamed —
  it is actually from *Paleo in a Nutshell* p. 123 (now
  `pian-123-cretan-breakfast`). `quote-check` now also fails if it
  finds any non-`.html` file in `quotes/`.

## [2.0.5] - 2026-10-11

### Fixed
- Three quote citations pointed at the wrong page: the two Stage 3 meat
  group restrictions ("per session"/"per day") cited p. 97 (the Stage 2
  nuts group) instead of p. 102, and the children-and-meat quote cited
  p. 106 instead of p. 105 where the passage starts. All 308 quotes
  re-verified; the remaining "off-by-one" flags are span quotes that
  correctly cite their start page.

### Added
- New `quote-check` executable: validates every quote file using the
  site's own Hakyll metadata parsing (known book, numeric page,
  non-empty body). Runs in CI before the site build, so a malformed
  quote can never deploy silently.

## [2.0.4] - 2026-09-15

### Fixed
- 29 more food pages still had broken `1024px` Wikimedia thumbnails. The
  v2.0.2 fix pipeline only re-tested URLs the audit had marked *dead*,
  silently skipping the ones the audit flagged as *fixable* (broken size
  but a working standard size exists). All rewritten to working sizes,
  and the resolver now processes fixable entries too.

## [2.0.3] - 2026-09-15

### Fixed
- The eight food pages written as Markdown (`.md`) were missed by the
  v2.0.2 image audit and still had broken 1024px Wikimedia links —
  Brussels sprouts, broccoli, cabbages, Swiss chard, beet greens
  (image removed: dead hotlink), eggs, and lard. The audit tooling now
  scans `*.md` as well as `*.html`.

## [2.0.2] - 2026-09-14

### Fixed
- Food page images: Wikimedia Commons now only serves standardized
  thumbnail sizes (500/960/1280/1920px), so all `1024px-` hotlinks
  returned errors. 60 image URLs were rewritten to a working size.
- Removed 32 images whose non-Wikimedia hotlinks are dead (removed blogs,
  403s, dead CDNs). Those pages render without an image until proper
  replacements are found (a Phase 2 goal).
- CI now runs `site check` (Hakyll's internal + external link validator)
  after every build, so dead image links can never deploy silently again.
  Internal links are blocking; external checks are report-only since
  Wikimedia rate-limits datacenter IPs.
- Removed 6 dead image attribution links (image_source) to 404/403 pages.

## [2.0.1] - 2026-09-13

### Fixed
- Corrected 15 quote citations (11 wrong page numbers, 4 attributed to the
  wrong book) using automated verification of every quote against the
  extracted text of both books. A handful of quotes that span a page break
  remain flagged for manual review in the builder workspace.

## [2.0.0] - 2026-09-13

### Added
- This changelog page, linked from the site footer.
- A site version in the footer (single source of truth: the `VERSION` file in
  the [builder repository](https://github.com/dmp1ce/savannamodel-hakyll)).
- Automated build and deployment: pushing to the builder repository now
  builds and publishes the site automatically via GitHub Actions.
- Automated `package-lock.json` regeneration as part of deployment.

### Changed
- Upgraded Hakyll from 4.12.5.2 to 4.17.0.0 (Stackage LTS 24.58, GHC 9.10.3).
- Upgraded Fomantic UI (Semantic UI) from 2.8.4 to 2.9.4.
- Removed jQuery — the site only uses the CSS framework.

### Published
- Content changes from 2020–2022 that had never been manually deployed are
  now live: new foods (pineapple, watermelon, tahini) with quotes, and
  low-fructose high-glycemic fruits moved from Green-Yellow to Yellow.

## [1.0.0] - 2018-10-21

- Initial Hakyll-based website for the Savanna Model lifestyle, based on
  Geoff Bond's *Deadly Harvest* and *Paleo in a Nutshell*.
- Food classification system with six color tiers (Green-Green "Superfoods"
  through Red "Shun"), hundreds of food pages, and book quotes linked to each
  food.
- Fomantic UI (Semantic UI) frontend.
