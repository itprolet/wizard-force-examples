---
title: GitHub Pages Setup
---

# GitHub Pages Setup

This repository is structured as a project-site documentation repository:

- root `README.md` is the GitHub landing page;
- `docs/` is the GitHub Pages source folder;
- `docs/index.md` is the documentation homepage.

## Navigation

- [Home](index.md) · [Framework Concepts](framework-concepts.md) · [Getting Started](getting-started.md) · [Build a Wizard](build-a-wizard.md)
- [Registry API](registry-api.md) · [Apex Extension Points](apex-extension-points.md) · [Validation](validation.md) · [Data Model](data-model.md)
- [LWC Components](lwc-components.md) · [Themes](themes.md) · [Review Mode](review-mode.md)
- [Deployment, Security, and Testing](deployment-security-testing.md) · [Troubleshooting](troubleshooting.md) · [GitHub Pages Setup](github-pages-setup.md)

## Enable Publishing

1. Push the repository to GitHub.
2. Open repository **Settings**.
3. Open **Pages**.
4. Under **Build and deployment**, select:
   - **Source**: `Deploy from a branch`
   - **Branch**: `main` (or your default branch)
   - **Folder**: `/docs`
5. Save settings.

GitHub will publish the site from `docs/` and provide a URL in the Pages settings panel.

## Content Rules

- Keep all documentation pages in English.
- Keep all documentation files under `docs/`.
- Use relative links between pages, for example `getting-started.md`.
- Keep one topic per page.
- Do not link to private managed package source files.
- Link to public examples and contract snippets only.

## Local Preview (Optional)

If you want to test docs rendering locally with Jekyll:

```bash
bundle install
bundle exec jekyll serve --source docs
```

Then open `http://127.0.0.1:4000`.

## Suggested Publishing Flow

1. Merge documentation changes to default branch.
2. Confirm links and page front matter.
3. Verify `docs/index.md` navigation.
4. Verify status tracker in `DOCS_PROGRESS.md`.
5. Validate Pages build output in GitHub.
