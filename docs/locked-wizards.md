---
title: Locked Wizards
---

# Locked Wizards

A wizard is either `ACTIVE` (the user fills it in) or `LOCKED` (it can only be looked at, for example after it was submitted). This page explains what locking does, how your submit uses it, and how a process can send a wizard back to its user.

## Navigation

- [Home](index.md) · [Framework Concepts](framework-concepts.md) · [Getting Started](getting-started.md) · [Build a Wizard](build-a-wizard.md)
- [Registry API](registry-api.md) · [Apex Extension Points](apex-extension-points.md) · [Validation](validation.md) · [Data Model](data-model.md)
- [LWC Components](lwc-components.md) · [Themes](themes.md) · [Locked Wizards](locked-wizards.md) · [Namespace](namespace.md)
- [Deployment, Security, and Testing](deployment-security-testing.md) · [Troubleshooting](troubleshooting.md) · [GitHub Pages Setup](github-pages-setup.md)

## The Two States

`prolet__Wizard__c.prolet__State__c` is `ACTIVE` or `LOCKED`. Any other value (empty, or an old value from before 0.2.0 such as `SIGNED`, `REVIEW`, `APPROVED`) counts as locked: use `prolet.WizardStates.isLocked(state)` in Apex, `isLockedState(state)` from `prolet/wizardUtils` in JavaScript, never a comparison with a text.

The field is read-only in the package's permission set and layout. It changes only through `prolet.WizardApi.lock` and `unlock`.

## What a Locked Wizard Does

**On the server** (the client is never trusted):

- Every write of what the user fills in (answers, page, path) is refused with the label `Wizard_err_locked`.
- Moving through a locked wizard only shows: nothing is written, no rules are checked, and the pages are those of its saved path (back, forward, or any step of the path).
- A trigger keeps a locked wizard as it is also against writes outside the package (your Apex, inline edit, a flow, Data Loader): `Model__c`, `Path__c` and `Wizard_Type__c` do not change while it stays locked.
- The context (`Context__c`) belongs to your process: your Apex can still write it with `prolet.WizardApi.updateContext`, and the wizard stays locked.

**In the browser**:

- Every field is read-only and nothing is checked.
- The buttons and steps move without asking the page (its `handlePage` is not called).
- A message (`Wizard_msg_locked`) is shown above the page, and the last page has a button to the start page.
- Pages still receive `state` (`ACTIVE` / `LOCKED`), for actions that are not fields (a submit button, adding to a list, an upload).

## Submitting a Wizard

A submit in your Apex, in this order:

```apex
public with sharing class FeedbackService {
    public static Id submit(Id wizardId, Boolean agreed) {
        prolet.WizardApi.assertCompleted(wizardId);   // ACTIVE, and every page was gone through
        Feedback__c feedback = new Feedback__c(/* from the answers */);
        insert feedback;                              // your own record
        prolet.WizardApi.updateContext(wizardId, new Map<String, Object>{ 'feedbackId' => feedback.Id });
        prolet.WizardApi.lock(wizardId);              // from now on it can only be looked at
        return feedback.Id;
    }
}
```

- `assertCompleted` refuses a wizard that is locked already (a second click on Submit creates nothing), whose path did not reach the last page of its plan, or with a page before the last one that does not pass its checks (`Wizard_err_not_completed`, naming the page). The last page is the one the submit is made from: its answers (a GDPR tick, say) go to your submit as parameters, so your page and your submit check them.
- `lock` on a locked wizard changes nothing.
- Each method reads the wizard locked (`FOR UPDATE`) until the end of the transaction. `lock`, `unlock` and `updateContext` return a `prolet.WizardVersionChange` (the version before and after), which a page sends with its `refresh` so that its own tab does not see a conflict; `updateContext` returns `null` for an empty patch, and `assertCompleted` returns nothing.

The examples show the steps, not one of them all four:

- [feedback](https://github.com/itprolet/wizard-force-examples/tree/main/examples/feedback) and [complaint](https://github.com/itprolet/wizard-force-examples/tree/main/examples/complaint): `assertCompleted`, their own insert, `lock` (no `updateContext`).
- [expense](https://github.com/itprolet/wizard-force-examples/tree/main/examples/expense): `updateContext`, `lock` and `unlock`; instead of `assertCompleted` it checks `prolet.WizardStates.isLocked` itself, because its report is submitted again after changes.

## Sending a Wizard Back

`prolet.WizardApi.unlock(wizardId)` makes a locked wizard `ACTIVE` again, for its user to change it: a submit that failed later, a manager who asks for changes, a mistake. Only Apex can unlock; the user cannot.

The [expense example](https://github.com/itprolet/wizard-force-examples/tree/main/examples/expense) does this for a manager's review: "Request changes" unlocks the wizard and writes into `$ctx` what has to change; its rules make the other pages read-only while the report is in that status.

## When the Page Is Done

A page that sends the action `complete` ends the wizard in the browser: the wizard forgets its Id (in the URL and in the tab's storage) and sends `wizardcomplete` to its parent. If the server says the wizard is locked, the Id stays, so that a reload shows the locked wizard.

## Upgrading From 0.1.0

0.1.0 had a REVIEW state, `Review_Data__c` and `reviewData` for pages. They are gone in 0.2.0. 0.1.0 was a beta, and a beta cannot be upgraded: an org with 0.1.0 uninstalls it first, which removes its wizards too, so 0.2.0 starts with none.
