---
title: Build a Wizard
---

# Build a Wizard

A wizard of your own, end to end: a type, a plan with a condition, pages on `wizardPageBase`, a registry, a validator and a submit. It is a shortened version of the [feedback example](https://github.com/itprolet/wizard-force-examples/tree/main/examples/feedback). The example has more: rules for its summary page (`navigationByChild`, the consent box), a frame of its own, and templates written before `wizardPageBase` (`{_required.x}` / `{_errors.x}`; new pages use `{fields.x.required}` / `{fields.x.error}`, as below).

## Navigation

- [Home](index.md) · [Framework Concepts](framework-concepts.md) · [Getting Started](getting-started.md) · [Build a Wizard](build-a-wizard.md)
- [Registry API](registry-api.md) · [Apex Extension Points](apex-extension-points.md) · [Validation](validation.md) · [Data Model](data-model.md)
- [LWC Components](lwc-components.md) · [Themes](themes.md) · [Locked Wizards](locked-wizards.md) · [Namespace](namespace.md)
- [Deployment, Security, and Testing](deployment-security-testing.md) · [Troubleshooting](troubleshooting.md) · [GitHub Pages Setup](github-pages-setup.md)

## 1. The Wizard Type

`customMetadata/prolet__Wizard_Setup.Feedback.md-meta.xml`:

```xml
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Feedback</label>
    <protected>false</protected>
    <values>
        <field>prolet__Title__c</field>
        <value xsi:type="xsd:string">Feedback</value>
    </values>
    <values>
        <field>prolet__Plan__c</field>
        <value xsi:type="xsd:string">{
  "Rating": "FeedbackRating",
  "Comment": "FeedbackComment",
  "Summary": "WizardFeedbackSummary"
}</value>
    </values>
    <values>
        <field>prolet__Rules__c</field>
        <value xsi:type="xsd:string">{
  "FeedbackRating": { "required": ["rating"] },
  "FeedbackComment": { "required": ["comment", "email"], "validators": { "email": ["validateFeedbackEmail"] } }
}</value>
    </values>
</CustomMetadata>
```

The keys of the plan are the step titles shown on the left; the values are page names. A step can be conditional: `"if (FeedbackRating.rating < 3)": { "What went wrong": "FeedbackProblem" }`. See [Validation](validation.md) for the rules.

## 2. The Pages

Each page extends `prolet/wizardPageBase` and declares the shape of its answers:

```js
import WizardPageBase from "prolet/wizardPageBase";

export default class FeedbackComment extends WizardPageBase {
  data = { comment: null, email: null };
}
```

```html
<template>
  <prolet-input-text
    label="E-mail"
    name="email"
    value={data.email}
    required={fields.email.required}
    error={fields.email.error}
    read-only={fields.email.readOnly}
    onchange={handleChange}
  ></prolet-input-text>
</template>
```

```css
@import "prolet/styles";
```

The page needs no `@api` of its own: the base receives the wizard's properties and answers its moves. See [Registry API](registry-api.md).

## 3. A Validator

A function in the browser, and (optionally) a `global` Apex class with the same name on the server:

```js
export function validateFeedbackEmail(value, message) {
  if (!value) return undefined;
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
    ? undefined
    : message || "Invalid email";
}
```

## 4. The Registry

```js
import { LightningElement } from "lwc";
import FeedbackRating from "c/feedbackRating";
import FeedbackComment from "c/feedbackComment";
import WizardFeedbackSummary from "c/wizardFeedbackSummary";
import { validateFeedbackEmail } from "c/validatorFeedbackEmail";

export default class FeedbackWizardRegistry extends LightningElement {
  _pageRegistry = { FeedbackRating, FeedbackComment, WizardFeedbackSummary };
  _validatorRegistry = { validateFeedbackEmail };
}
```

```html
<template>
  <prolet-wizard
    page-registry={_pageRegistry}
    validator-registry={_validatorRegistry}
    wizard-type-config="Feedback"
  ></prolet-wizard>
</template>
```

Expose it for `lightning__AppPage` and `lightningCommunity__Page`, and place it on a page.

## 5. The Submit

The last page submits through your Apex, which turns the answers into your own record and locks the wizard:

```apex
public with sharing class FeedbackController {
    @AuraEnabled
    public static Id submitFeedback(Id wizardId, Boolean agreedToGdpr) {
        prolet.WizardApi.assertCompleted(wizardId);
        prolet__Wizard__c wizard = prolet.WizardSelector.newInstance().selectById(wizardId);
        Map<String, Object> answers = (Map<String, Object>) JSON.deserializeUntyped(wizard.prolet__Model__c);
        Feedback__c feedback = new Feedback__c(Wizard__c = wizardId /* , fields from answers */);
        insert feedback;
        prolet.WizardApi.lock(wizardId);
        return feedback.Id;
    }
}
```

On the summary page (`feedbackAgreeGdpr` is a property of the page, ticked by the user), call it while the wizard is locked for the wait, then refresh:

```js
async submit() {
  this.uiLock(true);
  try {
    await submitFeedback({ wizardId: this.wizardId, agreedToGdpr: this.feedbackAgreeGdpr });
    this.refresh({ pageModel: null });
  } finally {
    this.uiLock(false);
  }
}
```

After the refresh the wizard is shown locked: every field read-only. See [Locked Wizards](locked-wizards.md).

## 6. Deploy and Try

```bash
sf project deploy start --target-org <your org> --source-dir examples/feedback
sf org assign permset --target-org <your org> --name prolet__Wizard_Framework_User
```

## Larger Examples

- [complaint](https://github.com/itprolet/wizard-force-examples/tree/main/examples/complaint): labels, patterns, hints, page errors, a new wizard after a locked one.
- [clubMembership](https://github.com/itprolet/wizard-force-examples/tree/main/examples/clubMembership): a lookup in Apex, `ticked`, `hidden`, page validators, translations.
- [expense](https://github.com/itprolet/wizard-force-examples/tree/main/examples/expense): constants, server validators, a manager's review decided by access to the report, two tabs.
