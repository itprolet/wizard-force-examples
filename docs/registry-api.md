---
title: Registry API
---

# Registry API

How your pages, validators and labels reach the wizard, what a page receives and sends, and the page base class `prolet/wizardPageBase`.

## Navigation

- [Home](index.md) · [Framework Concepts](framework-concepts.md) · [Getting Started](getting-started.md) · [Build a Wizard](build-a-wizard.md)
- [Registry API](registry-api.md) · [Apex Extension Points](apex-extension-points.md) · [Validation](validation.md) · [Data Model](data-model.md)
- [LWC Components](lwc-components.md) · [Themes](themes.md) · [Locked Wizards](locked-wizards.md) · [Namespace](namespace.md)
- [Deployment, Security, and Testing](deployment-security-testing.md) · [Troubleshooting](troubleshooting.md) · [GitHub Pages Setup](github-pages-setup.md)

## The Registry Component

The package never imports your pages. A registry LWC of yours hands them to `<prolet-wizard>`:

```html
<template>
  <prolet-wizard
    page-registry={_pageRegistry}
    validator-registry={_validatorRegistry}
    page-validator-registry={_pageValidatorRegistry}
    label-registry={_labelRegistry}
    wizard-type-config="MyType"
  ></prolet-wizard>
</template>
```

```js
import { LightningElement } from "lwc";
import MyPageA from "c/myPageA";
import MyPageB from "c/myPageB";

export default class MyWizardRegistry extends LightningElement {
  _pageRegistry = { MyPageA, MyPageB }; // the page names of the plan
  _validatorRegistry = {};
  _pageValidatorRegistry = {};
  _labelRegistry = {}; // { Name: text }, usually your custom labels
}
```

Expose the registry (`isExposed`, targets `lightning__AppPage`, `lightningCommunity__Page`, and `lightning__RecordPage` / `lightning__HomePage` if you need them) and place it with App Builder or Experience Builder. Several wizards on one page do not get in each other's way when each has its own registries.

Instead of the attributes, a registry can register globally before the wizard loads (`registerPage`, `registerValidator`, `registerPageValidator`, `registerLabels` from `prolet/wizardUtils`); then only one wizard per page is possible.

## What a Page Receives

| `@api`                                                                       | What it is                                                                                                                                   |
| ---------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `model`                                                                      | The answers of the whole wizard, by page name. `model[page].$ctx` and `$con` hold the context and the constants.                             |
| `page`                                                                       | This page's name. A page used twice in a plan can end in `_2`; the suffix is ignored when the page is looked up.                             |
| `title`, `wizardId`, `wizardType`, `currentId`                               | The step's title, the wizard, its type, the related record from the URL.                                                                     |
| `state`                                                                      | `ACTIVE` or `LOCKED`.                                                                                                                        |
| `required`, `readOnly`, `visible`, `errors`, `hints`, `messages`, `patterns` | What the rules say, per field (`errors.$global` for the page).                                                                               |
| `l`                                                                          | The wizard's labels.                                                                                                                         |
| `hasPrev`, `hasNext`                                                         | Whether there is a page before / after.                                                                                                      |
| your step parameters                                                         | `{ "page": "MyPage", "mode": "short" }` in the plan: declare `@api mode`. Values keep their type; a text that is a label name is translated. |

## What a Page Sends

- The wizard calls `handlePage(direction)` (`next`, `prev`, or a step `{ title, page }`). The page **always** answers with a `pagechange` event: `{ direction, pageModel }` to move with its answers, or direction `error` to stay. It may be `async`.
- `pagechange` with the name of a changed field: the wizard checks the page.
- `pagechange` with `refresh`: the wizard reads the wizard again (after your Apex changed it); `pageModel: null` sends no answers, `versionChange` is what your Apex returned.
- `action` with `{ action: "uiLock", status: "in_progress" | "done" }` (in pairs) while the page waits for its server call; `{ action: "complete" }` when the page is done.
- `toast` with `{ title, message, variant, duration }`.

The wizard sends `wizardcomplete` to its parent after `complete`, and `wizardchange` on every change in single-page mode.

## `prolet/wizardPageBase`

A page that extends the base class gets all of the above written once. It declares only the shape of its answers:

```js
import WizardPageBase from "prolet/wizardPageBase";

export default class MyPage extends WizardPageBase {
  data = { name: null, address: { city: null }, newsletter: false };
}
```

```html
<prolet-input-text
  name="address.city"
  value={data.address.city}
  required={fields.address.city.required}
  error={fields.address.city.error}
  read-only={fields.address.city.readOnly}
  onchange={handleChange}
></prolet-input-text>
```

What it does:

- **`data`** is built from the declared shape with the wizard's answers on top, at every level. Only declared keys are taken.
- **`handleChange(event)`** takes the name from `detail.name`, `data-name` or `name` (paths like `address.city`) and the value from the event. In a locked wizard it does nothing.
- **`handlePage(dir)`** always answers the wizard; for `next` it first asks `beforeNext()` (may be async), and `false` keeps the page.
- **`fields.<path>`** gives `{ value, required, readOnly, visible, error, hint, message, pattern }` for each answer. In a locked wizard every field is read-only.
- **Hooks**: `onModelChanged(pageModel)`, `onFieldValidated(name, veto)`, `beforeNext()`, `getPageModel()`.
- **Helpers**: `setValue(path, value, notify)`, `goBack()`, `refresh({ pageModel, versionChange })`, `toast(message, variant, title)`, `uiLock(on)`, `complete(detail)`, and `ctx` / `con` for the context and the constants.

Rules: do not declare the wizard's properties again (`@api model`, `@api errors`); react in a hook. The base has no `connectedCallback` / `renderedCallback`. The base does not validate: the rules do. An error of the page's own (an unticked consent on a summary) lives in a field of the page.

## Helpers in `prolet/wizardUtils`

`isLockedState(state)`, `lockWizardUi(page, locked)`, `showToast(page, title, message, variant)`, `registerPage`, `registerValidator`, `registerPageValidator`, `registerLabels`, `getLabelsMap`.

## Examples

- [vacation](https://github.com/itprolet/wizard-force-examples/tree/main/examples/vacation): pages written without the base, every property by hand
- [feedback](https://github.com/itprolet/wizard-force-examples/tree/main/examples/feedback), [complaint](https://github.com/itprolet/wizard-force-examples/tree/main/examples/complaint), [showcase](https://github.com/itprolet/wizard-force-examples/tree/main/examples/showcase): pages on `wizardPageBase`
- [embedded](https://github.com/itprolet/wizard-force-examples/tree/main/examples/embedded): the single-page mode
