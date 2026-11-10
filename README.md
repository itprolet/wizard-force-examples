# Wizard Framework Examples

Public examples and developer documentation for the **Wizard Framework** Salesforce managed package (namespace `prolet`).

This repository is for Salesforce developers who want to evaluate the package and build their own wizards on it. It contains documentation and example code only; the package's source is private.

## Documentation

The documentation is published with GitHub Pages from the `docs/` folder.

- Start here: [docs/index.md](docs/index.md)
- Install and run a first wizard: [docs/getting-started.md](docs/getting-started.md)
- Which names need `prolet`: [docs/namespace.md](docs/namespace.md)

## Examples

Each example is a package directory of its own and deploys on its own, into an org with the package installed. Take them in this order:

| # | Example | What it shows |
|---|---|---|
| 1 | [vacation](examples/vacation) | The smallest wizard: three pages, required fields only, no Apex; the answers live in `prolet__Wizard__c` |
| 2 | [embedded](examples/embedded) | A single form inside your own component: the plan, rules and answers come from the parent, nothing is stored (`wizardchange` / `wizardcomplete`) |
| 3 | [feedback](examples/feedback) | A full flow: its own object, a `with sharing` controller, `WizardApi.assertCompleted` / `lock`, pages on `wizardPageBase` |
| 4 | [serviceVisit](examples/serviceVisit) | A conditional page and two lookups from metadata (`Smart_Lookup_Setting`) |
| 5 | [complaint](examples/complaint) | Labels, attachments, patterns, hints, page errors, a new wizard after a locked one |
| 6 | [clubMembership](examples/clubMembership) | A lookup written in Apex, `ticked` boxes, `hidden` fields, page validators, translations, its own frame |
| 7 | [showcase](examples/showcase) | Every input and element of the package (tabs, datatable, alerts) |
| 8 | [expense](examples/expense) | Constants, server validators (`IValidator` / `IPageValidator`), two tabs on one wizard, locking, a manager's review with `prolet__Wizard_Framework_Back_Office` |
| — | [carRental](examples/carRental) | Optional, an advanced look: tiles, photos, two objects |

Deploy one:

```bash
sf project deploy start -o <your org> -d examples/vacation
```

## Expected Setup

Before deploying an example, install the Wizard Framework package and assign `prolet__Wizard_Framework_User` to the users who fill in wizards (and the example's own permission set, where it has one). See [Getting Started](docs/getting-started.md).

## Repository Shape

```text
README.md
docs/                 the GitHub Pages site
examples/<name>/      one subscriber-style implementation per folder
config/               a scratch org definition
sfdx-project.json     one package directory per example
```

The examples are published from the framework's own repository, where they are tested against the package before every release.
