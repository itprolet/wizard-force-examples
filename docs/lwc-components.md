---
title: LWC Components
---

# LWC Components

The package's components that your pages can use. Each is `prolet-...` in your templates (see [Namespace](namespace.md)); styles come with `@import "prolet/styles";`.

## Navigation

- [Home](index.md) · [Framework Concepts](framework-concepts.md) · [Getting Started](getting-started.md) · [Build a Wizard](build-a-wizard.md)
- [Registry API](registry-api.md) · [Apex Extension Points](apex-extension-points.md) · [Validation](validation.md) · [Data Model](data-model.md)
- [LWC Components](lwc-components.md) · [Themes](themes.md) · [Locked Wizards](locked-wizards.md) · [Namespace](namespace.md)
- [Deployment, Security, and Testing](deployment-security-testing.md) · [Troubleshooting](troubleshooting.md) · [GitHub Pages Setup](github-pages-setup.md)

## The Wizard: `<prolet-wizard>`

| Attribute                                                                                                   | What it does                                                                                                                                                                                                           |
| ----------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `wizard-type-config`                                                                                        | The wizard type (`DeveloperName` of a `prolet__Wizard_Setup__mdt` record). Needed on App, Home and Record pages and for several wizards on one page; on an Experience page it can come from the URL (`c__wizardType`). |
| `page-registry`                                                                                             | `{ PageName: Constructor }`: the pages of this wizard.                                                                                                                                                                 |
| `validator-registry`, `page-validator-registry`                                                             | Field and page validators by name.                                                                                                                                                                                     |
| `label-registry`                                                                                            | `{ Name: text }`: the wizard's labels.                                                                                                                                                                                 |
| `primary-color`, `secondary-color`, `shape`                                                                 | The look; see [Themes](themes.md).                                                                                                                                                                                     |
| `plan-config`, `rules-config`, `initial-model`, `wizard-title-config`, `context-config`, `constants-config` | The single-page mode; see [Data Model](data-model.md).                                                                                                                                                                 |

## Inputs

All inputs take `name`, `label`, `required`, `read-only`, `disabled`, `error`, `message` and send `change` with `{ name, value }`, which `handleChange` of `wizardPageBase` understands.

| Component                                         | Use                                                                                                      | Its own attributes                                                                                                                                                   |
| ------------------------------------------------- | -------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `prolet-input-text`                               | Text, number, date, email, a multi-line text                                                             | `type`, `value`, `placeholder`, `pattern`, `restrict-to-pattern`, `min`, `max`, `max-length`, `multiline`, `strip-whitespace`, `hint`, `accept`, `readonly-textlike` |
| `prolet-input-checkbox`                           | A yes / no answer, a consent                                                                             | `value` (checked)                                                                                                                                                    |
| `prolet-input-combobox`                           | A choice from a list                                                                                     | `items` (`[{ label, value }]`), `value`, `placeholder`, `hint`, `dropdown-direction`, `readonly-textlike`                                                            |
| `prolet-input-fixed`                              | A fixed-length code (one box per character)                                                              | `size`, `size-long`, `placeholder`, `hint`                                                                                                                           |
| `prolet-input-suggester`                          | A lookup: search as you type                                                                             | see below                                                                                                                                                            |
| `prolet-input-button`, `prolet-input-button-icon` | Buttons in the package's style                                                                           | `icon`, `size`, `disabled`, `loading`, `classname` / `title`, `bg-color`; they send `clicked`                                                                        |
| `prolet-input-tabset`                             | Tabs over parts of a page: each child `<div data-role="tab" data-value="..." data-label="...">` is a tab | `value` (the open tab), `disabled`, `read-only`; it sends `change`                                                                                                   |

## Lookups: `<prolet-input-suggester>`

What a lookup may read is decided only on the server, by a `prolet__Smart_Lookup_Setting__mdt` record named in `lookup-name`. The component sends the record's name, the typed text and the arguments: never an object, fields or a query.

```html
<prolet-input-suggester
  label="Account"
  lookup-name="Expense_AccountId"
  key-field="Id"
  name-field="Name"
  selected-id="{data.accountId}"
  selected-name="{data.accountIdName}"
  onsmartlookupselected="{accountSelected}"
></prolet-input-suggester>
```

On a choice it sends `smartlookupselected` with `{ lookupId, selectedId, selectedName, rawData }` (not `change`: a lookup has two answers, the Id and the name). Other attributes: `display-field`, `custom-value` (accept free text), `record-id` and `arg0-value` … `arg9-value` (arguments), `placeholder`, `hint`.

The setting:

| Field                                                        | What it holds                                                                                             |
| ------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------- |
| `prolet__Soql__c`                                            | A query with `:query` (the typed text, as a `LIKE` pattern) and `:arg0` … `:arg9`.                        |
| `prolet__ArgsBaseObjectType__c`, `prolet__ArgsFieldNames__c` | Arguments read from the record of `record-id`: its object and its fields (comma-separated, dotted paths). |
| `prolet__ApexClass__c`, `prolet__ApexMethod__c`              | Your `System.Callable` class and its method, instead of a query.                                          |
| `prolet__RequiredPermission__c`                              | A custom permission the user needs; empty means anyone who can open the wizard.                           |

Every lookup runs as the user (`USER_MODE`: sharing and field access), returns at most 50 records, and gives the browser one general message on any error (the reason is in the debug log). The search rules: the text anywhere in the field, `*` is the user's wildcard (`A*` starts with A), a space matches anything between two words, `%` and `_` are plain characters. See the [serviceVisit](../examples/serviceVisit) and [clubMembership](../examples/clubMembership) examples.

## Elements

| Component               | Use                                    | Attributes                               |
| ----------------------- | -------------------------------------- | ---------------------------------------- |
| `prolet-elem-alert`     | An info, success, warning or error box | `type`, `show`, `closable`, `icon`       |
| `prolet-elem-chip`      | A coloured label                       | `color`, `icon`, `block`                 |
| `prolet-elem-tile`      | A choice shown as a tile               | `icon`, `state`, `classname`             |
| `prolet-elem-marquee`   | A status line                          | `icon`, `prefix`, `status`               |
| `prolet-elem-preloader` | A spinner                              | `text`, `large`, `absolute`, `badge`     |
| `prolet-elem-toast`     | A toast                                | `icon`, `show`, `item-id`, `items-count` |
| `prolet-page-progress`  | The steps, for a frame of your own     | `pages`, `read-only`, `allow-forward`    |

## A Table: `<prolet-elem-datatable>`

| Attribute                                                              | Default | What it does                         |
| ---------------------------------------------------------------------- | :-----: | ------------------------------------ |
| `columns`                                                              |  `[]`   | The columns (required)               |
| `data`                                                                 |  `[]`   | The rows                             |
| `fill-width`, `headless`, `footer-fade`, `fixed-columns`, `force-wrap` | `false` | Layout                               |
| `loading`                                                              | `false` | A spinner instead of the rows        |
| `empty-message`                                                        | a label | The text of an empty table           |
| `server-sort`                                                          | `false` | Sorting by the parent (`sort` event) |
| `hide-pagination`                                                      | `false` | No pages                             |
| `total`                                                                |         | Server-side paging (`page` event)    |

A column: `fieldName`, `label`, `type`, `typeData`, `align`, `sortable`, `width`, `classname`, `style`. Types: `text` (default), `number`, `boolean`, `date`, `time`, `datetime`, `richtext`, `url` (`{ icon, disabled }`), `link` (`{ url, callback, dataField, disabled, target }`), `icon` (`{ icon, title, dataField, callback, disabled }`), `chip` (`{ chipItems: [{ value, color, icon }] }`).

Links open only for `http:`, `https:`, `mailto:`, `tel:` and paths of the site; anything else is shown as text. Events: `sort` (`{ sortBy, direction }`), `page` (`{ rowOffset, pageSize, total }`).

See the [showcase example](../examples/showcase), which uses every component.
