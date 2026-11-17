/**
 * @description The manager's review of a report whose wizard they may not see (Wizard__c is
 * Private, the manager is not the owner nor above them): access to the report decides.
 * Expense_Report__c is Private too: a reviewer gets a report through the role hierarchy (above
 * the employee) or a share (a sharing rule, a queue); here mostly a manual share, so the reviewer
 * still does not see the wizard. Without either, a colleague does not see the report at all.
 */
@IsTest
private class ExpenseReviewAccessTest {

    /** Standard User with the given permission sets (no role, so no hierarchy) */
    private static User userWith(String name, List<String> permissionSets) {
        return ExpenseReportTestData.userWith(name, permissionSets);
    }

    private static final List<String> EXPENSE_SETS = new List<String>{ 'Wizard_Framework_User', 'Expense_Report_User' };

    /** The employee fills in and submits a report: their own wizard */
    private static Id submittedBy(User employee) {
        Id wizardId;
        System.runAs(employee) {
            wizardId = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE').Id;
            ExpenseReportController.submitReport(wizardId, true);
        }
        return wizardId;
    }

    private static Id reportOf(Id wizardId) {
        return [SELECT Id FROM Expense_Report__c WHERE Wizard__c = :wizardId].Id;
    }

    @IsTest
    static void aManagerWhoCannotSeeTheWizardReviewsTheReport() {
        User employee = userWith('emma', EXPENSE_SETS);
        User manager = userWith('mark', EXPENSE_SETS);
        Id wizardId = submittedBy(employee);
        Id reportId = reportOf(wizardId);
        ExpenseReportTestData.shareReport(reportId, manager.Id, 'Edit');

        System.runAs(manager) {
            // the wizard is the employee's: the manager does not see it
            System.Assert.areEqual(0, [SELECT COUNT() FROM prolet__Wizard__c WHERE Id = :wizardId]);
            // but reviews the report
            ExpenseReviewData review = ExpenseReviewController.getReview(reportId);
            System.Assert.areEqual(prolet.WizardStates.LOCKED, review.wizardState);
            System.Assert.areEqual(2, review.lines.size());
            ExpenseReviewController.requestChanges(reportId, new List<String>{ 'e1' }, null, false, 'Check hotel');
        }
        System.Assert.areEqual(prolet.WizardStates.ACTIVE, ExpenseReportTestData.reload(wizardId).prolet__State__c,
                'the employee can change the report again');

        System.runAs(employee) {
            // the employee makes the change and submits again
            Map<String, Object> model = ExpenseReportTestData.validModel();
            for (Object item : (List<Object>) ((Map<String, Object>) model.get('ExpenseItems')).get('expenses')) {
                Map<String, Object> expense = (Map<String, Object>) item;
                if (expense.get('id') == 'e1') {
                    expense.put('amount', '123');
                }
            }
            ExpenseReportTestData.updateModel(wizardId, model);
            ExpenseReportController.submitReport(wizardId, true);
        }
        System.runAs(manager) {
            ExpenseReviewController.approveReport(reportId);
        }
        System.Assert.areEqual('Approved', [SELECT Status__c FROM Expense_Report__c WHERE Id = :reportId].Status__c);
    }

    @IsTest
    static void aUserWithoutAccessToTheReportCannotReviewIt() {
        User employee = userWith('emma', EXPENSE_SETS);
        // the framework, but not the expense example: no access to Expense_Report__c
        User other = userWith('olga', new List<String>{ 'Wizard_Framework_User' });
        Id wizardId = submittedBy(employee);
        Id reportId = reportOf(wizardId);

        System.runAs(other) {
            try {
                ExpenseReviewController.getReview(reportId);
                System.Assert.fail('getReview without access to the report');
            } catch (AuraHandledException e) {
                System.Assert.isTrue(e.getMessage().startsWith('Expense report not found'), e.getMessage());
            }
            try {
                ExpenseReviewController.approveReport(reportId);
                System.Assert.fail('approveReport without access to the report');
            } catch (AuraHandledException e) {
                System.Assert.isTrue(e.getMessage().startsWith('Expense report not found'), e.getMessage());
            }
        }
        System.Assert.areEqual('Submitted', [SELECT Status__c FROM Expense_Report__c WHERE Id = :reportId].Status__c);
        System.Assert.areEqual(prolet.WizardStates.LOCKED, ExpenseReportTestData.reload(wizardId).prolet__State__c);
    }

    @IsTest
    static void readingTheReportIsNotEnoughToDecide() {
        User employee = userWith('emma', EXPENSE_SETS);
        // may read reports, not edit them: by the object permission (read only) ...
        User reader = userWith('rita', new List<String>{ 'Wizard_Framework_User' });
        System.runAs(new User(Id = UserInfo.getUserId())) {
            PermissionSet readOnly = new PermissionSet(
                    Name = 'Expense_Test_Read_Only_' + Datetime.now().getTime(), Label = 'Expense test: read only');
            insert readOnly;
            // the objects' names from the schema: with a namespace, they have its prefix
            insert new List<ObjectPermissions>{
                    new ObjectPermissions(ParentId = readOnly.Id, PermissionsRead = true,
                            SobjectType = Expense_Report__c.SObjectType.getDescribe().getName()),
                    new ObjectPermissions(ParentId = readOnly.Id, PermissionsRead = true,
                            SobjectType = Expense_Line__c.SObjectType.getDescribe().getName())
            };
            insert new PermissionSetAssignment(PermissionSetId = readOnly.Id, AssigneeId = reader.Id);
        }
        // ... or by the record: Expense_Report_User (edit on the object), the report shared to read
        User sharedToRead = userWith('rosa', EXPENSE_SETS);
        Id wizardId = submittedBy(employee);
        Id reportId = reportOf(wizardId);
        ExpenseReportTestData.shareReport(reportId, reader.Id, 'Read');
        ExpenseReportTestData.shareReport(reportId, sharedToRead.Id, 'Read');

        for (User user : new List<User>{ reader, sharedToRead }) {
            System.runAs(user) {
                // sees the review
                System.Assert.areEqual(prolet.WizardStates.LOCKED, ExpenseReviewController.getReview(reportId).wizardState, user.LastName);
                // but does not decide
                try {
                    ExpenseReviewController.approveReport(reportId);
                    System.Assert.fail(user.LastName + ': approveReport with read access only');
                } catch (AuraHandledException e) {
                    System.Assert.areEqual('You may not review this expense report.', e.getMessage(), user.LastName);
                }
                try {
                    ExpenseReviewController.requestChanges(reportId, new List<String>{ 'e1' }, null, false, 'x');
                    System.Assert.fail(user.LastName + ': requestChanges with read access only');
                } catch (AuraHandledException e) {
                    System.Assert.areEqual('You may not review this expense report.', e.getMessage(), user.LastName);
                }
            }
        }
        System.Assert.areEqual(prolet.WizardStates.LOCKED, ExpenseReportTestData.reload(wizardId).prolet__State__c, 'nothing changed');
    }

    // ------------------------------------------------------------------ a forged link report -> wizard

    private static final List<String> FORGER_SETS = new List<String>{
            'Wizard_Framework_User', 'Expense_Report_User', 'Wizard_Framework_Back_Office'
    };

    /** A locked wizard of the victim: another process (Car Rental) or a submitted expense report */
    private static Id lockedWizardOf(User victim, String wizardType) {
        Id wizardId;
        System.runAs(victim) {
            prolet__Wizard__c wizard = new prolet__Wizard__c(prolet__Wizard_Type__c = wizardType, prolet__State__c = prolet.WizardStates.LOCKED);
            insert wizard;
            wizardId = wizard.Id;
        }
        return wizardId;
    }

    @IsTest
    static void aUserCannotLinkAReportToAWizard() {
        User victim = userWith('vera', EXPENSE_SETS);
        User forger = userWith('fred', FORGER_SETS);
        Id carRental = lockedWizardOf(victim, 'CarRental');

        System.runAs(forger) {
            // as the UI or the API does it (the user's field access): Wizard__c and Status__c are the server's
            try {
                Database.insert(new Expense_Report__c(Wizard__c = carRental, Status__c = 'Submitted'), AccessLevel.USER_MODE);
                System.Assert.fail('a user linked a report to a wizard');
            } catch (Exception e) {
                System.Assert.isTrue(e.getMessage().contains('inaccessible'), e.getMessage());
            }
            // the reason is those two fields: the same report without them is allowed
            Database.insert(new Expense_Report__c(Purpose__c = 'Not linked'), AccessLevel.USER_MODE);
        }
        System.Assert.areEqual(0, [SELECT COUNT() FROM Expense_Report__c WHERE Wizard__c = :carRental]);
    }

    @IsTest
    static void aForgedReportOpensNoWizardOfSomeoneElse() {
        User victim = userWith('vera', EXPENSE_SETS);
        User forger = userWith('fred', FORGER_SETS);
        // another process's wizard, a locked expense wizard, and one the victim really submitted
        // (its context names the victim's own report, not the forged one)
        List<Id> targets = new List<Id>{
                lockedWizardOf(victim, 'CarRental'),
                lockedWizardOf(victim, ExpenseReportService.WIZARD_TYPE),
                submittedBy(victim)
        };

        for (Id target : targets) {
            Id reportId;
            System.runAs(forger) {
                // made past the field access (as an admin or a data load could): the review still refuses it
                Expense_Report__c forged = new Expense_Report__c(Wizard__c = target, Status__c = 'Submitted');
                insert forged;
                reportId = forged.Id;
                try {
                    ExpenseReviewController.requestChanges(reportId, null, null, true, 'Review');
                    System.Assert.fail('requestChanges unlocked the wizard of a forged report');
                } catch (AuraHandledException e) {
                    System.Assert.areEqual('This expense report is not linked to its own expense wizard.', e.getMessage());
                }
                try {
                    ExpenseReviewController.getReview(reportId);
                    System.Assert.fail('getReview read the wizard of a forged report');
                } catch (AuraHandledException e) {
                    System.Assert.areEqual('This expense report is not linked to its own expense wizard.', e.getMessage());
                }
                try {
                    ExpenseReviewController.approveReport(reportId);
                    System.Assert.fail('approveReport wrote the wizard of a forged report');
                } catch (AuraHandledException e) {
                    System.Assert.areEqual('This expense report is not linked to its own expense wizard.', e.getMessage());
                }
            }
            prolet__Wizard__c after = ExpenseReportTestData.reload(target);
            System.Assert.areEqual(prolet.WizardStates.LOCKED, after.prolet__State__c, 'the victim\'s wizard stays locked');
            Map<String, Object> context = after.prolet__Context__c == null ? new Map<String, Object>()
                    : (Map<String, Object>) JSON.deserializeUntyped(after.prolet__Context__c);
            System.Assert.isNull(context.get(ExpenseReportService.CTX_COMMENT), 'no review was written in it');
        }
    }

    @IsTest
    static void aWizardMadeForTheEmployeeByAnAdminIsReviewed() {
        User employee = userWith('emma', EXPENSE_SETS);
        User manager = userWith('mark', EXPENSE_SETS);
        // an admin (or an integration) makes the wizard and gives it to the employee
        prolet__Wizard__c wizard = new prolet__Wizard__c(prolet__Wizard_Type__c = ExpenseReportService.WIZARD_TYPE, prolet__State__c = prolet.WizardStates.ACTIVE,
                prolet__Model__c = JSON.serialize(ExpenseReportTestData.validModel()), OwnerId = employee.Id);
        insert wizard;
        System.runAs(employee) {
            ExpenseReportController.submitReport(wizard.Id, true);
        }
        Id reportId = reportOf(wizard.Id);
        System.Assert.areNotEqual([SELECT CreatedById FROM prolet__Wizard__c WHERE Id = :wizard.Id].CreatedById,
                [SELECT CreatedById FROM Expense_Report__c WHERE Id = :reportId].CreatedById, 'made by different users');
        ExpenseReportTestData.shareReport(reportId, manager.Id, 'Edit');

        System.runAs(manager) {
            System.Assert.areEqual(2, ExpenseReviewController.getReview(reportId).lines.size());
            ExpenseReviewController.approveReport(reportId);
        }
        System.Assert.areEqual('Approved', [SELECT Status__c FROM Expense_Report__c WHERE Id = :reportId].Status__c);
    }

    @IsTest
    static void aReportCannotBeRelinkedToAnotherWizard() {
        User victim = userWith('vera', EXPENSE_SETS);
        User forger = userWith('fred', FORGER_SETS);
        Id target = lockedWizardOf(victim, ExpenseReportService.WIZARD_TYPE);
        // the forger's own report, made by a real submit
        Id reportId = reportOf(submittedBy(forger));

        System.runAs(forger) {
            try {
                update new Expense_Report__c(Id = reportId, Wizard__c = target);
                System.Assert.fail('a report was linked to another wizard');
            } catch (DmlException e) {
                System.Assert.isTrue(e.getMessage().contains('The wizard of an expense report cannot be changed.'), e.getMessage());
            }
        }
        System.Assert.areNotEqual(target, [SELECT Wizard__c FROM Expense_Report__c WHERE Id = :reportId].Wizard__c);
    }

    @IsTest
    static void aWizardOfAnotherProcessMakesNoReport() {
        User employee = userWith('emma', EXPENSE_SETS);
        System.runAs(employee) {
            prolet__Wizard__c carRental = new prolet__Wizard__c(prolet__Wizard_Type__c = 'CarRental', prolet__State__c = prolet.WizardStates.ACTIVE,
                    prolet__Model__c = JSON.serialize(ExpenseReportTestData.validModel()));
            insert carRental;
            try {
                ExpenseReportController.submitReport(carRental.Id, true);
                System.Assert.fail('a report was made for a wizard of another process');
            } catch (AuraHandledException e) {
                System.Assert.areEqual('This wizard is not an expense report.', e.getMessage());
            }
            System.Assert.areEqual(0, [SELECT COUNT() FROM Expense_Report__c WHERE Wizard__c = :carRental.Id]);
        }
    }

    /** Calls the link check with sharing: as a caller that does not elevate would */
    private with sharing class WithSharingCaller {
        void requireExpenseLink(Id reportId) {
            ExpenseReportService.requireExpenseLink(reportId);
        }
    }

    @IsTest
    static void theLinkCheckFailsClosedWhenItCannotReadTheWizard() {
        User employee = userWith('emma', EXPENSE_SETS);
        User manager = userWith('mark', EXPENSE_SETS);
        Id wizardId = submittedBy(employee);
        Id reportId = reportOf(wizardId);

        ExpenseReportTestData.shareReport(reportId, manager.Id, 'Edit');
        // without sharing (as the review calls it) the real link passes
        ExpenseReportService.requireExpenseLink(reportId);
        System.runAs(manager) {
            // with sharing the manager reads the report but not the wizard: "no row" is refused
            System.Assert.areEqual(0, [SELECT COUNT() FROM prolet__Wizard__c WHERE Id = :wizardId]);
            try {
                new WithSharingCaller().requireExpenseLink(reportId);
                System.Assert.fail('the check passed for a wizard it could not read');
            } catch (ExpenseReportException e) {
                System.Assert.areEqual(ExpenseReportService.NOT_LINKED, e.getMessage());
            }
        }
        // a report that is not there
        delete new Expense_Report__c(Id = reportId);
        try {
            ExpenseReportService.requireExpenseLink(reportId);
            System.Assert.fail('the check passed for a report that is not there');
        } catch (ExpenseReportException e) {
            System.Assert.isTrue(e.getMessage().startsWith('Expense report not found'), e.getMessage());
        }
    }

    // ------------------------------------------------------------------ nobody decides on their own report

    @IsTest
    static void theEmployeeSeesTheirReportButCannotDecideOnIt() {
        User employee = userWith('emma', EXPENSE_SETS);
        User manager = userWith('mark', EXPENSE_SETS);
        Id wizardId = submittedBy(employee);
        Id reportId = reportOf(wizardId);
        ExpenseReportTestData.shareReport(reportId, manager.Id, 'Edit');

        System.runAs(employee) {
            // her own report: she may edit it, and so pass the report check
            ExpenseReviewData review = ExpenseReviewController.getReview(reportId);
            System.Assert.isTrue(review.ownReport, 'her own report');
            System.Assert.areEqual(2, review.lines.size(), 'she sees it');
            try {
                ExpenseReviewController.approveReport(reportId);
                System.Assert.fail('she approved her own report');
            } catch (AuraHandledException e) {
                System.Assert.areEqual(ExpenseReportService.OWN_REPORT, e.getMessage());
            }
            try {
                ExpenseReviewController.requestChanges(reportId, new List<String>{ 'e1' }, null, false, 'x');
                System.Assert.fail('she asked for changes in her own report');
            } catch (AuraHandledException e) {
                System.Assert.areEqual(ExpenseReportService.OWN_REPORT, e.getMessage());
            }
        }
        System.Assert.areEqual('Submitted', [SELECT Status__c FROM Expense_Report__c WHERE Id = :reportId].Status__c);
        System.Assert.areEqual(prolet.WizardStates.LOCKED, ExpenseReportTestData.reload(wizardId).prolet__State__c, 'nothing changed');

        System.runAs(manager) {
            System.Assert.isFalse(ExpenseReviewController.getReview(reportId).ownReport);
            ExpenseReviewController.approveReport(reportId);
        }
        System.Assert.areEqual('Approved', [SELECT Status__c FROM Expense_Report__c WHERE Id = :reportId].Status__c);
    }

    @IsTest
    static void owningTheReportOrTheWizardIsEnough() {
        User employee = userWith('emma', EXPENSE_SETS);
        User manager = userWith('mark', EXPENSE_SETS);
        Id wizardId = submittedBy(employee);
        Id reportId = reportOf(wizardId);
        // the report is given to the manager, and shared back with the employee (Private: she would
        // not see it otherwise); the wizard stays the employee's
        update new Expense_Report__c(Id = reportId, OwnerId = manager.Id);
        ExpenseReportTestData.shareReport(reportId, employee.Id, 'Edit');

        for (User user : new List<User>{ employee, manager }) {
            System.runAs(user) {
                System.Assert.isTrue(ExpenseReviewController.getReview(reportId).ownReport, user.LastName);
                try {
                    ExpenseReviewController.approveReport(reportId);
                    System.Assert.fail(user.LastName + ' approved a report of their own');
                } catch (AuraHandledException e) {
                    System.Assert.areEqual(ExpenseReportService.OWN_REPORT, e.getMessage(), user.LastName);
                }
            }
        }
        System.Assert.areEqual('Submitted', [SELECT Status__c FROM Expense_Report__c WHERE Id = :reportId].Status__c);
    }

    // ------------------------------------------------------------------ who sees a report (Private)

    @IsTest
    static void aManagerAboveTheEmployeeReviewsTheirReport() {
        List<User> people = ExpenseReportTestData.employeeAndManager(EXPENSE_SETS);
        User employee = people[0];
        User manager = people[1];
        Id reportId = reportOf(submittedBy(employee));

        // no share: the role hierarchy gives the manager the report
        System.runAs(manager) {
            System.Assert.isFalse(ExpenseReviewController.getReview(reportId).ownReport);
            ExpenseReviewController.approveReport(reportId);
        }
        System.Assert.areEqual('Approved', [SELECT Status__c FROM Expense_Report__c WHERE Id = :reportId].Status__c);
    }

    @IsTest
    static void aColleagueDoesNotSeeTheReport() {
        // a colleague beside the employee: the same permission sets and the same role, nothing
        // shared. Private: the role hierarchy gives a report only to those above its owner
        List<User> people = ExpenseReportTestData.employeeAndManager(EXPENSE_SETS);
        User employee = people[0];
        User manager = people[1];
        User colleague = ExpenseReportTestData.userWith('carl', EXPENSE_SETS, employee.UserRoleId);
        Id wizardId = submittedBy(employee);
        Id reportId = reportOf(wizardId);

        System.runAs(manager) {
            System.Assert.areEqual(1, [SELECT COUNT() FROM Expense_Report__c WHERE Id = :reportId], 'above her: sees it');
        }
        System.runAs(colleague) {
            System.Assert.areEqual(0, [SELECT COUNT() FROM Expense_Report__c WHERE Id = :reportId]);
            try {
                ExpenseReviewController.getReview(reportId);
                System.Assert.fail('a colleague read the review');
            } catch (AuraHandledException e) {
                System.Assert.isTrue(e.getMessage().startsWith('Expense report not found'), e.getMessage());
            }
            try {
                ExpenseReviewController.approveReport(reportId);
                System.Assert.fail('a colleague approved the report');
            } catch (AuraHandledException e) {
                System.Assert.isTrue(e.getMessage().startsWith('Expense report not found'), e.getMessage());
            }
        }
        System.Assert.areEqual('Submitted', [SELECT Status__c FROM Expense_Report__c WHERE Id = :reportId].Status__c);
        System.Assert.areEqual(prolet.WizardStates.LOCKED, ExpenseReportTestData.reload(wizardId).prolet__State__c);
    }

    @IsTest
    static void aResubmitUpdatesTheReportTheEmployeeNoLongerSees() {
        User employee = userWith('emma', EXPENSE_SETS);
        User manager = userWith('mark', EXPENSE_SETS);
        Id wizardId = submittedBy(employee);
        Id reportId = reportOf(wizardId);
        // the report goes to a review queue: the manager reviews it, the employee no longer sees it
        update new Expense_Report__c(Id = reportId, OwnerId = ExpenseReportTestData.reviewQueue(new List<User>{ manager }));
        System.runAs(employee) {
            System.Assert.areEqual(0, [SELECT COUNT() FROM Expense_Report__c WHERE Id = :reportId], 'she does not see it');
        }
        System.runAs(manager) {
            ExpenseReviewController.requestChanges(reportId, new List<String>{ 'e1' }, null, false, 'Check hotel');
        }

        System.runAs(employee) {
            Map<String, Object> model = ExpenseReportTestData.validModel();
            List<Object> expenses = (List<Object>) ((Map<String, Object>) model.get('ExpenseItems')).get('expenses');
            Map<String, Object> other;
            for (Object item : expenses) {
                Map<String, Object> expense = (Map<String, Object>) item;
                if (expense.get('id') == 'e1') {
                    expense.put('amount', '123');
                } else {
                    other = expense;
                }
            }
            // the requested change, and a line that was not asked for: refused, also when she does
            // not see the report (the check reads its lines)
            Object otherAmount = other.get('amount');
            other.put('amount', '999');
            ExpenseReportTestData.updateModel(wizardId, model);
            try {
                ExpenseReportController.submitReport(wizardId, true);
                System.Assert.fail('a line that was not asked for changed');
            } catch (AuraHandledException e) {
                System.Assert.isTrue(e.getMessage().startsWith('Only the requested changes can be made'), e.getMessage());
            }
            // the requested change alone goes through, into the same report
            other.put('amount', otherAmount);
            ExpenseReportTestData.updateModel(wizardId, model);
            ExpenseReportController.submitReport(wizardId, true);
        }
        List<Expense_Report__c> reports = [SELECT Id, Status__c FROM Expense_Report__c WHERE Wizard__c = :wizardId];
        System.Assert.areEqual(1, reports.size(), 'one report for the wizard');
        System.Assert.areEqual(reportId, reports[0].Id, 'the same report, updated');
        System.Assert.areEqual('Submitted', reports[0].Status__c);
        System.Assert.areEqual(123, [SELECT Amount__c FROM Expense_Line__c WHERE Expense_Report__c = :reportId AND Line_Key__c = 'e1'].Amount__c);
        System.Assert.areEqual(String.valueOf(reportId), String.valueOf(
                ((Map<String, Object>) JSON.deserializeUntyped(ExpenseReportTestData.reload(wizardId).prolet__Context__c)).get(ExpenseReportService.CTX_REPORT)));
    }

    @IsTest
    static void aUserWhoMayOnlyReadTheWizardCannotSubmitIt() {
        User employee = userWith('emma', EXPENSE_SETS);
        User colleague = userWith('carl', EXPENSE_SETS);
        Id wizardId;
        System.runAs(employee) {
            wizardId = ExpenseReportTestData.insertWizard(ExpenseReportTestData.validModel(), 'ACTIVE').Id;
        }
        // shared with the colleague to read: the report would be written without sharing, so the
        // submit needs the right to change the wizard
        SObject share = Schema.getGlobalDescribe().get(prolet__Wizard__c.SObjectType.getDescribe().getName().removeEnd('__c') + '__Share').newSObject();
        share.put('ParentId', wizardId);
        share.put('UserOrGroupId', colleague.Id);
        share.put('AccessLevel', 'Read');
        insert share;
        System.runAs(colleague) {
            try {
                ExpenseReportController.submitReport(wizardId, true);
                System.Assert.fail('a reader submitted the wizard');
            } catch (AuraHandledException e) {
                System.Assert.isTrue(e.getMessage().startsWith('Wizard not found'), e.getMessage());
            }
        }
        System.Assert.areEqual(0, [SELECT COUNT() FROM Expense_Report__c WHERE Wizard__c = :wizardId]);
    }
}
