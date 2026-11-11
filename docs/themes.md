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

| Attribute         | Default            | What it does                                                                   |
| ----------------- | ------------------ | ------------------------------------------------------------------------------ |
| `primary-color`   | the package's blue | The main colour: buttons, the current step, focus. Any CSS colour (`#8dc8ff`). |
| `secondary-color` | the package's grey | The second colour: texts and lines around the fields.                          |
| `shape`           | `round`            | `round` or `sharp` corners of fields, buttons and tiles.                       |

```html
<prolet-wizard
  page-registry="{_pageRegistry}"
  primary-color="#8dc8ff"
  secondary-color="#535857"
  shape="sharp"
  wizard-type-config="Feedback"
></prolet-wizard>
```

A registry can pass them on from App Builder by declaring them as its own `@api` properties (the [feedback registry](../examples/feedback/lwc/feedbackWizardRegistry) does).

## Your Own Styles

Your pages import the package's styles and add their own:

```css
@import "prolet/styles";

.my-note {
  color: var(--color-regular);
}
```

The [carRental example](../examples/carRental) goes further: a frame of its own around the wizard, tiles and photos.
