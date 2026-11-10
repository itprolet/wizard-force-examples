---
title: Namespace
---

# Namespace

The Wizard Framework is a managed package with the namespace `prolet`. In your org, every name of the package carries it; your own names do not. This page lists where it goes.

## Navigation

- [Home](index.md) · [Framework Concepts](framework-concepts.md) · [Getting Started](getting-started.md) · [Build a Wizard](build-a-wizard.md)
- [Registry API](registry-api.md) · [Apex Extension Points](apex-extension-points.md) · [Validation](validation.md) · [Data Model](data-model.md)
- [LWC Components](lwc-components.md) · [Themes](themes.md) · [Locked Wizards](locked-wizards.md) · [Namespace](namespace.md)
- [Deployment, Security, and Testing](deployment-security-testing.md) · [Troubleshooting](troubleshooting.md) · [GitHub Pages Setup](github-pages-setup.md)

## Where `prolet` Goes

| Where | The package's name | Your own name |
|---|---|---|
| JS import | `import WizardPageBase from "prolet/wizardPageBase";`, `from "prolet/wizardUtils"` | `from "c/myPage"` |
| CSS | `@import "prolet/styles";` | `@import "c/myStyles";` |
| HTML tag | `<prolet-wizard>`, `<prolet-input-text>`, `<prolet-elem-alert>`, `<prolet-page-progress>` | `<c-my-frame>` |
| Lightning page (flexipage) | `prolet:wizard` | `c:myWizardRegistry` |
| Apex class | `prolet.WizardApi`, `prolet.WizardStates`, `prolet.WizardPageData`, `prolet.IValidator` | `MyService` |
| Object | `prolet__Wizard__c` | `My_Record__c` |
| Field of the package | `prolet__Model__c`, `prolet__State__c`, `prolet__Context__c` | `My_Field__c`, also a lookup to the wizard you name `Wizard__c` |
| Lookup to a wizard | `<referenceTo>prolet__Wizard__c</referenceTo>` | the field itself stays yours |
| Custom metadata record | file `prolet__Wizard_Setup.MyWizard.md-meta.xml`, fields `prolet__Plan__c`, `prolet__Rules__c`, `prolet__Title__c` | |
| Lookup setting | `prolet__Smart_Lookup_Setting.MyLookup.md-meta.xml`, `prolet__Soql__c`, `prolet__ApexClass__c` | the class it names: `MyLookup` |
| Constant | `prolet__Wizard_Contstant.MyConstant.md-meta.xml`, `prolet__Value__c` | |
| Permission set | `prolet__Wizard_Framework_User`, `prolet__Wizard_Framework_Back_Office` | |
| Label in Apex | `System.Label.get('prolet', 'Wizard_err_locked')` | `System.Label.My_label` |
| Label in LWC | `@salesforce/label/prolet.Wizard_err_locked` | `@salesforce/label/c.My_label` |

## Where It Does Not Go

- **Page names in the plan and the rules** (`"Contact": "ShowcaseContact"`): the registry hands the wizard your constructors, not names to look up.
- **Your labels in the rules** (`"message": "My_err_label"`): the wizard translates them from your registry.
- **The rules language**: `$ctx`, `$con`, `required`, `hidden`, ... are written as they are.
- **The JSON in `Model__c`, `Context__c`, `Path__c`**: its keys are your page and field names.

## A Query in a Lookup Setting

The query in `prolet__Soql__c` runs in your org as written. When it names a field of the package, write the full name:

```sql
SELECT Id, Name FROM prolet__Wizard__c WHERE prolet__State__c = 'ACTIVE'
```

## A Lookup or Validator Class of Yours

A lookup setting (`prolet__ApexClass__c`) or a validator in the rules names your class by its name (`MyLookup`, `ValidateIban`). If your own org has a namespace too, write it with it: `myns.MyLookup`. The error in the debug log says so when the class is not found.

## Apex That Is Not Yours to Call

Only `global` Apex of the package is visible in your org. `prolet.WizardController`, `WizardService`, `WizardUtils`, `SmartLookupCtrl` and the `Wf*` classes are `public`: your code cannot call them. Their uses have a global way:

| Instead of | Use |
|---|---|
| `new WizardSelector()` | `prolet.WizardSelector.newInstance()` (a `prolet.IWizardSelector`) |
| `SmartLookupCtrl.likePattern(text)` | `prolet.WizardApi.likePattern(text)` |
| `WizardUtils.parsePageRules(page, rules, model)` | `prolet.WizardApi.parsePageRules(page, rules, model)` |

## JSON of the Package's Classes

Apex outside the package cannot `JSON.serialize` or `JSON.deserialize` the package's classes, even the global ones ("Type cannot be serialized"). To write a path (for a test, say), build it from maps:

```apex
private static String pathJson(List<prolet.WizardPageData> path) {
    List<Map<String, Object>> pages = new List<Map<String, Object>>();
    for (prolet.WizardPageData page : path) {
        pages.add(new Map<String, Object>{ 'title' => page.title, 'page' => page.page, 'initParams' => page.initParams });
    }
    return JSON.serialize(pages);
}
```

The same goes for a custom metadata record built in a test with `JSON.deserialize`: the keys are the full field names (`'prolet__Plan__c'`), a JSON key does not get the namespace by itself.
