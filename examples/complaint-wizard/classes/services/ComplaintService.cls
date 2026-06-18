/**
 * @description Service for operations with complaints (Complaint__c).
 * Reuses WizardSelector for querying Wizard__c.
 * Does not touch WizardService/WizardController — they are generic framework.
 */
public inherited sharing class ComplaintService implements IComplaintService {

    private static final WizardSelector wizardSelector = new WizardSelector();

    public Id submitComplaint(Id wizardId, Boolean agreedToGdpr) {
        // Load the Wizard__c record by Id
        List<Wizard__c> wizards = wizardSelector.selectByIds(wizardId);
        if (wizards.isEmpty()) {
            throw new ComplaintException('Wizard model is empty, id= ' + wizardId);
        }

        Wizard__c wizard = wizards[0];
        if (String.isBlank(wizard.Model__c)) {
            throw new ComplaintException('Wizard model is empty, id= ' + wizardId);
        }

        // Deserialize the JSON model and build the Complaint__c record
        Map<String, Object> model = (Map<String, Object>) JSON.deserializeUntyped(wizard.Model__c);
        Complaint__c complaint = buildComplaint(wizardId, model, agreedToGdpr);

         if (agreedToGdpr != true) {
            throw new ComplaintException('GDPR consent is required to submit a complaint.');
        }

        insert complaint;

        return complaint.Id;
    }

    /**
     * @description Maps wizard model (JSON) to Complaint__c fields.
     * Model keys correspond to the page components:
     *   WizardComplaintCategory  → category, subCategory
     *   WizardComplaintDetails   → description, incidentDate, referenceNumber, affectedService
     *   WizardComplaintAttachment→ invoiceNumber, disputedAmount
     *   WizardComplaintContact   → firstName, lastName, email, phone, preferredContact, preferredTime
     */
    private static Complaint__c buildComplaint(Id wizardId, Map<String, Object> model, Boolean agreedToGdpr) {
        // Build and return a Complaint__c record based on the wizardId and model
        Map<String, Object> categoryData = toMap(model.get('WizardComplaintCategory'));
        Map<String, Object> detailsData = toMap(model.get('WizardComplaintDetails'));
        Map<String, Object> attachmentData = toMap(model.get('WizardComplaintAttachment'));
        Map<String, Object> contactData = toMap(model.get('WizardComplaintContact'));

        Complaint__c complaint = new Complaint__c();
        complaint.Wizard__c = wizardId;

        // Category
        complaint.Category__c = strVal(categoryData, 'category');
        complaint.Sub_Category__c = strVal(categoryData, 'subCategory');

        // Details
        complaint.Description__c = strVal(detailsData, 'description');
        String incidentDateStr = strVal(detailsData, 'incidentDate');
        if (String.isNotBlank(incidentDateStr)) {
            try {
                complaint.Incident_Date__c = Date.valueOf(incidentDateStr);
            } catch (Exception e) {
                // Handle invalid date format if necessary
            }
        }
        complaint.Reference_Number__c = strVal(detailsData, 'referenceNumber');
        complaint.Affected_Service__c = strVal(detailsData, 'affectedService');

        // Attachment (only for billing, otherwise can be null)
        complaint.Invoice_Number__c = strVal(attachmentData, 'invoiceNumber');
        String disputedAmountStr = strVal(attachmentData, 'disputedAmount');
        if (String.isNotBlank(disputedAmountStr)) {
            try {
                complaint.Disputed_Amount__c = Decimal.valueOf(disputedAmountStr);
            } catch (Exception e) {
                // Handle invalid decimal format if necessary
            }
        }

        // Contact
        complaint.First_Name__c = strVal(contactData, 'firstName');
        complaint.Last_Name__c = strVal(contactData, 'lastName');
        complaint.Email__c = strVal(contactData, 'email');
        complaint.Phone__c = strVal(contactData, 'phone');
        complaint.Preferred_Contact__c = strVal(contactData, 'preferredContact');
        complaint.Preferred_Time__c = strVal(contactData, 'preferredTime');

        // Summary
        complaint.Agreed_to_GDPR__c = agreedToGdpr;

        return complaint;
    }

    // --- Helper Methods ---

    /**
     * @description Helper method to cast an Object to a Map<String, Object>.
    */
    private static Map<String, Object> toMap(Object obj) {
        if (obj instanceof Map<String, Object>) {
            return (Map<String, Object>) obj;
        }
        return new Map<String, Object>();
    }

    /**
     * @description Helper method to safely extract a String value from a Map by key.
    */
    private static String strVal(Map<String, Object> m, String key) {
        if (m == null || !m.containsKey(key)) {
            return null;
        }
        Object val = m.get(key);
        return val != null ? String.valueOf(val) : null;
    }
}