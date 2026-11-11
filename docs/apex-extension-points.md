---
title: Apex Extension Points
---

# Apex Extension Points

Only `global` Apex of a managed package can be used from your org. This page lists the package's global API and how your own Apex plugs into it.

## Navigation

- [Home](index.md) · [Framework Concepts](framework-concepts.md) · [Getting Started](getting-started.md) · [Build a Wizard](build-a-wizard.md)
- [Registry API](registry-api.md) · [Apex Extension Points](apex-extension-points.md) · [Validation](validation.md) · [Data Model](data-model.md)
- [LWC Components](lwc-components.md) · [Themes](themes.md) · [Locked Wizards](locked-wizards.md) · [Namespace](namespace.md)
- [Deployment, Security, and Testing](deployment-security-testing.md) · [Troubleshooting](troubleshooting.md) · [GitHub Pages Setup](github-pages-setup.md)

## `prolet.WizardApi`

What the Apex of your process (a submit, a manager's decision) may do to a wizard. Each method reads the wizard locked (`FOR UPDATE`) until the end of the transaction, and the writes return a `prolet.WizardVersionChange`.

| Method                                                                                  | What it does                                                                                                                                                                                                                                                                                                  |
| --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `WizardVersionChange updateContext(Id wizardId, Map<String, Object> patch)`             | Puts values into the wizard's context (`$ctx`); the others stay. Also for a locked wizard, which stays locked. Returns null when `patch` is empty.                                                                                                                                                            |
| `WizardVersionChange lock(Id wizardId)`                                                 | Locks the wizard: from now on it can only be looked at. A locked wizard stays as it is.                                                                                                                                                                                                                       |
| `WizardVersionChange unlock(Id wizardId)`                                               | Makes a locked wizard `ACTIVE` again, for its user to change it.                                                                                                                                                                                                                                              |
| `void assertCompleted(Id wizardId)`                                                     | Refuses a wizard that is locked, whose path did not reach the last page of its plan, or with a page before the last one that does not pass its checks (`prolet.WizardException`). Call it first in a submit.                                                                                                  |
| `String likePattern(String searchValue)`                                                | What the user typed as a `LIKE` pattern, by the rules of a lookup: anywhere in the field, `*` the user's wildcard, a space matches anything between two words, `%` and `_` searched as they are, nothing typed is everything (`'A*'` → `'A%'`, `'Acme Corp'` → `'%Acme%Corp%'`). For a lookup class of yours. |
| `WizardPageRules parsePageRules(WizardPageData page, Object rawRules, Object rawModel)` | The rules of a page for the model given. It reads no wizard: a `$ctx` / `$con` condition is false unless you put `'$ctx'` and `'$con'` into the model yourself. The lists it returns are copies. For tests of your rules.                                                                                     |

A submit, in this order:

```apex
prolet.WizardApi.assertCompleted(wizardId);
insert request;                                  // your own record
prolet.WizardApi.updateContext(wizardId, new Map<String, Object>{ 'requestId' => request.Id });
return prolet.WizardApi.lock(wizardId);
```

See [Locked Wizards](locked-wizards.md).

## `prolet.WizardVersionChange`

When your Apex writes a wizard itself during a page's action, wrap the writes so the page can tell its tab (see [Data Model](data-model.md)):

| Member                                                |                                                                                                                |
| ----------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `static WizardVersionChange startChange(Id wizardId)` | Locks the wizard as the package's own methods do, and takes its version.                                       |
| `WizardVersionChange finish()`                        | The version after your last write of the wizard (or the same, when nothing was written). Call it in `finally`. |
| `Integer fromVersion`, `Integer pathVersion`          | The version before and after.                                                                                  |

## `prolet.WizardStates` and `prolet.WizardException`

- `prolet.WizardStates.ACTIVE`, `prolet.WizardStates.LOCKED`, `prolet.WizardStates.isLocked(String state)`: anything but `ACTIVE` is locked.
- `prolet.WizardException`: what the package throws for a refused action (a locked wizard, an incomplete one, a version conflict). `prolet.WizardException.PATH_VERSION_CONFLICT` is the code at the start of the conflict's message.

## Reading Wizards: `prolet.WizardSelector`

```apex
prolet.IWizardSelector selector = prolet.WizardSelector.newInstance();
List<prolet__Wizard__c> wizards = selector.selectByIds(wizardId);
```

`prolet.IWizardSelector` has `selectByIds(Id)`, `selectByIds(Set<Id>)`, `selectById(Id)`, `selectByIdForUpdate(Id)`, `selectByType(Set<String>)`, `selectByUserIdAndStateAndType(Id, String, String)`, `selectTypeById(Id)` and `selectStateById(Id)`. It runs with the sharing of the class that calls it. `new WizardSelector()` is not available outside the package; use `newInstance()`.

## Validators: `prolet.IValidator` and `prolet.IPageValidator`

A validator named in the rules runs in the browser as your JavaScript function and on the server as your Apex class of the same name. Declare the class `global`, so the package can create it in your org.

```apex
global with sharing class ValidateIban implements prolet.IValidator {
    /** null when the value is valid, otherwise the error message */
    global String validate(Object value, String message) {
        if (value == null || String.isBlank(String.valueOf(value))) {
            return null; // empty: use "required" for that
        }
        return isValid(String.valueOf(value)) ? null : (String.isNotBlank(message) ? message : 'Invalid IBAN');
    }
}
```

```apex
global with sharing class ValidateExpenseLimit implements prolet.IPageValidator {
    /** true when the page is valid; errors gets field -> message, or '$global' for the page */
    global Boolean validate(String page, Map<String, Object> model,
            prolet.WizardPageRules.ValidatorEntry entry, Map<String, Object> errors) {
        Decimal limitValue = Decimal.valueOf(String.valueOf(entry.properties.get('limit')));
        // ... sum the page's amounts from model.get(page)
        errors.put('$global', entry.message);
        return false;
    }
}
```

`entry.properties` holds every setting of the rule except `validator` and `message` (a `$con.Name` value is already the constant's value). See [Validation](validation.md) and the [expense example](../examples/expense).

## Lookups in Apex

A `prolet__Smart_Lookup_Setting__mdt` record can name your class (`prolet__ApexClass__c`) and its method (`prolet__ApexMethod__c`) instead of a query. The class implements `System.Callable`; the package calls `call(methodName, arguments)`, where `arguments` holds the field's arguments (`arg0` … `arg9`) and what the user typed under `'$searchValue'`, and returns a `List<SObject>`. What it returns is checked against the user's access: records they may not see are left out, fields they may not read are removed. Search with `prolet.WizardApi.likePattern(searchValue)` and keep `WITH USER_MODE` in your queries. See the [clubMembership example](../examples/clubMembership).

## Not Part of the Contract

`WizardController`, `WizardService`, `WizardUtils` and `SmartLookupCtrl` are `public`: your org cannot call them. The `Wf*` classes (selector, domain, unit of work, query builder) are `global` because the package's own global classes build on them, but they are not part of the contract: do not extend or call them, they may change in any version.
