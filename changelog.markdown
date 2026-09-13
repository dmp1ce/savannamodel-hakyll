---
title: Changelog
---

All notable changes to this website are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and versions follow [Semantic Versioning](https://semver.org/): MAJOR for
redesigns, MINOR for new features, PATCH for fixes and content updates.

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
