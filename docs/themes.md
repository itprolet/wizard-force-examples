---
title: Themes
---

# Themes

The look of a wizard is set on `<prolet-wizard>` with three attributes.

## Navigation

- [Home](index.md) · [Framework Concepts](framework-concepts.md) · [Getting Started](getting-started.md) · [Build a Wizard](build-a-wizard.md)
- [Registry API](registry-api.md) · [Apex Extension Points](apex-extension-points.md) · [Validation](validation.md) · [Data Model](data-model.md)
- [LWC Components](lwc-components.md) · [Themes](themes.md) · [Locked Wizards](locked-wizards.md) · [Namespace](namespace.md)
- [Deployment, Security, and Testing](deployment-security-testing.md) · [Troubleshooting](troubleshooting.md) · [GitHub Pages Setup](github-pages-setup.md)

## Attributes

| Attribute         | Default                   | What it does                                                                   |
| ----------------- | ------------------------- | ------------------------------------------------------------------------------ |
| `primary-color`   | a light green (`#c8f27e`) | The main colour: buttons, the current step, focus. Any CSS colour (`#8dc8ff`). |
| `secondary-color` | a dark green (`#053027`)  | The second colour: texts and lines around the fields.                          |
| `shape`           | `round`                   | `round` or `sharp` corners of fields, buttons and tiles.                       |

```html
<prolet-wizard
  page-registry={_pageRegistry}
  primary-color="#8dc8ff"
  secondary-color="#535857"
  shape="sharp"
  wizard-type-config="Feedback"
></prolet-wizard>
```

A registry can let App Builder and Experience Builder change them: it declares them as its own `@api` properties, passes them to `<prolet-wizard>` (`primary-color={primaryColor}`), and lists them as `<property>` in its `js-meta.xml`, for `lightning__AppPage` (type `String`) and for `lightningCommunity__Default` (type `Color`). The [feedback registry](https://github.com/itprolet/wizard-force-examples/tree/main/examples/feedback/lwc/feedbackWizardRegistry) does this.

## Your Own Styles

Your pages import the package's styles and add their own:

```css
@import "prolet/styles";

.my-note {
  color: var(--color-regular);
}
```

The [carRental example](https://github.com/itprolet/wizard-force-examples/tree/main/examples/carRental) goes further: a frame of its own around the wizard, tiles and photos.
