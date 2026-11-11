---
title: Getting Started
---

# Getting Started

The smallest working wizard: install the package, deploy the vacation example, put it on a page, and fill it in.

## Navigation

- [Home](index.md) · [Framework Concepts](framework-concepts.md) · [Getting Started](getting-started.md) · [Build a Wizard](build-a-wizard.md)
- [Registry API](registry-api.md) · [Apex Extension Points](apex-extension-points.md) · [Validation](validation.md) · [Data Model](data-model.md)
- [LWC Components](lwc-components.md) · [Themes](themes.md) · [Locked Wizards](locked-wizards.md) · [Namespace](namespace.md)
- [Deployment, Security, and Testing](deployment-security-testing.md) · [Troubleshooting](troubleshooting.md) · [GitHub Pages Setup](github-pages-setup.md)

## 1. Install the Package

Install the latest version of the Wizard Framework package into a sandbox, a developer org or a scratch org, from its install link or with the CLI:

```bash
sf package install --target-org <your org> --package <04t... id of the version> --wait 20
```

The package's namespace is `prolet`. Then give the users who fill in wizards the package's permission set:

```bash
sf org assign permset --target-org <your org> --name prolet__Wizard_Framework_User
```

`prolet__Wizard_Framework_Back_Office` is for people who must read other users' wizards (see [Deployment, Security, and Testing](deployment-security-testing.md)).

## 2. Deploy the Vacation Example

```bash
git clone https://github.com/itprolet/wizard-force-examples.git
cd wizard-force-examples
sf project deploy start --target-org <your org> --source-dir examples/vacation
```

It brings:

- `customMetadata/prolet__Wizard_Setup.Vacation.md-meta.xml`: the wizard type `Vacation`, with its plan and rules;
- `lwc/vacationDetails`, `vacationSickNote`, `vacationSummary`: the three pages;
- `lwc/vacationWizardRegistry`: the component you place on a page.

The plan shows the sick-note page only for a sick leave:

```json
{
  "Details": "VacationDetails",
  "if (VacationDetails.type='sick')": { "Sick note": "VacationSickNote" },
  "Summary": "VacationSummary"
}
```

and the rules make the dates and the type required:

```json
{
  "VacationDetails": { "required": ["startDate", "endDate", "type"] },
  "VacationSickNote": { "required": ["doctorNoteNumber", "doctorName"] }
}
```

## 3. Put It on a Page

The registry renders the package's wizard with its pages:

```html
<template>
  <prolet-wizard
    page-registry="{_pageRegistry}"
    wizard-type-config="Vacation"
  ></prolet-wizard>
</template>
```

In Lightning App Builder, create an App Page, drag **Vacation Wizard** onto it, save and activate it. In Experience Builder, the same component is available on a page of your site.

## 4. Fill It In

Open the page. The first page is shown without a record; on the first **Next**, a `prolet__Wizard__c` record is created, and every move saves the page's answers into it:

```sql
SELECT prolet__Wizard_Type__c, prolet__State__c, prolet__Model__c, prolet__Path__c
FROM prolet__Wizard__c ORDER BY CreatedDate DESC LIMIT 1
```

`prolet__Model__c` holds the answers by page, `prolet__Path__c` the pages gone through.

## Next

- [Build a Wizard](build-a-wizard.md): your own type, pages on `wizardPageBase`, a submit.
- [Namespace](namespace.md): which names need `prolet` in your code.
- The [feedback example](../examples/feedback): the same with its own object and a submit in Apex.
