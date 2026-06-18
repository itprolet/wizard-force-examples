# Documentation Progress

Last updated: 2026-06-17

This file tracks what has been completed for the public Wizard Framework docs and what remains before publication.

## Completed

- Created multi-page docs structure under `docs/` for:
  - `index.md`
  - `framework-concepts.md`
  - `getting-started.md`
  - `build-a-wizard.md`
  - `registry-api.md`
  - `apex-extension-points.md`
  - `validation.md`
  - `data-model.md`
  - `lwc-components.md`
  - `themes.md`
  - `review-mode.md`
  - `deployment-security-testing.md`
  - `troubleshooting.md`
- Added GitHub Pages Jekyll configuration in `docs/_config.yml`.
- Added explicit GitHub Pages setup guide in `docs/github-pages-setup.md`.
- Added `framework-concepts.md` and linked it in the docs map.
- Kept docs content and templates in English.
- Added publication constraints and safety checks in `PUBLICATION_CHECKLIST.md`.

## Remaining Before Public Release

- Fill every placeholder page with full contract-level content (currently many pages are planned outlines).
- Complete API reference details for all supported global Apex classes/interfaces/methods:
  - parameter types
  - return values
  - examples
  - supported vs non-supported global artifacts
- Complete `wizardRegistry.js` API reference with options, defaults, and error semantics.
- Complete full LWC component catalog with all public `@api` properties, emitted events, slots, defaults, and examples.
- Complete end-to-end tutorial with registration, pages, validation, review mode, and submit flow.
- Run namespace pass for subscriber-org syntax across docs and examples.
- Validate all links point to public examples/contracts only.
- Validate each example in a clean org with the managed package installed.
- Run Apex tests for example code and document required deploy steps.
- Confirm if `examples/complaint-wizard` is approved for public release.
- Enable GitHub Pages in repo settings (`Deploy from branch`, branch default, folder `/docs`).

## Publication Readiness Checklist

Use these files together before announcing docs:

- `PUBLICATION_CHECKLIST.md`
- `docs/github-pages-setup.md`
- `docs/index.md`
