# Publication Checklist

Use this checklist before publishing `wizard-force-examples` as a public repository.

## Source Safety

- Do not include `force-app/main/default` from the private package repository.
- Do not link documentation to private package implementation files.
- Link documentation only to public examples, public snippets, or published API contracts.
- Review examples for customer-specific names, internal business logic, IDs, URLs, or secrets.
- Confirm that the complaint example is acceptable for public release before keeping it.

## Namespace Pass

The copied examples currently come from the private development repository. Before public release, verify and update subscriber-org references for the managed package namespace.

Review at least:

- LWC imports from package modules, such as `c/wizardUtils`.
- LWC markup that renders package components, such as `<c-wizard>`.
- Apex references to package classes, such as `WizardSelector`.
- Apex and metadata references to package objects and fields, such as `Wizard__c`, `Wizard__c.Model__c`, and `Wizard_Setup__mdt`.
- Lookup fields that reference package objects.
- Permission set object/field references.

The public docs should include the final namespace syntax for the installed package release.

## Documentation

- Keep the root `README.md` short and product-oriented.
- Publish GitHub Pages from `docs/`.
- Keep documentation in English.
- Document framework APIs contract-first: signature, required overrides, optional overrides, parameter types, return values, examples.
- For each API page, link to public example code instead of private package source.

## Example Validation

- Deploy each example into a clean org with the managed package installed.
- Run Apex tests for examples that include Apex.
- Verify the registry component renders the package wizard component.
- Verify page navigation, validation, review behavior, and submit flows.
- Verify all documented commands work from this repository.
