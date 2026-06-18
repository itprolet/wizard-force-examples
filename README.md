# Wizard Framework Examples

Public examples and developer documentation for the **Wizard Framework** Salesforce managed package.

This repository is intended for Salesforce developers who want to evaluate the package and build subscriber-owned wizard implementations. It contains documentation and example code only. The managed package implementation source is private and is not included here.

## Documentation

The documentation is designed to be published with GitHub Pages from the `docs/` folder.

- Start here: [docs/index.md](docs/index.md)
- GitHub Pages setup: [docs/github-pages-setup.md](docs/github-pages-setup.md)

## Examples

| Example | Purpose |
|---|---|
| [examples/basic-wizard](examples/basic-wizard) | Minimal page registration and wizard rendering pattern |
| [examples/feedback-wizard](examples/feedback-wizard) | End-to-end wizard with custom pages, validation, submit service, and custom object mapping |
| [examples/embedded-form](examples/embedded-form) | Embedded single-form style usage |
| [examples/complaint-wizard](examples/complaint-wizard) | Larger multi-page business wizard example |

## Expected Setup

Before deploying an example into an org, install the Wizard Framework managed package and assign the package permission set to the users who will run the wizard.

These examples are a public extraction draft. Before publishing, run the namespace pass described in [PUBLICATION_CHECKLIST.md](PUBLICATION_CHECKLIST.md) so subscriber-org references point to the installed managed package namespace instead of same-repo source modules.

## Repository Shape

```text
README.md
docs/
examples/
config/
sfdx-project.json
```

The root `README.md` is the GitHub landing page. The `docs/` folder is the GitHub Pages site. The `examples/` folder contains subscriber-style implementations that demonstrate the public package contracts.
