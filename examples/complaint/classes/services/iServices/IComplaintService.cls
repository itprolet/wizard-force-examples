public interface IComplaintService {
    /**
     * @description Finalizes complaints wizard and persists Complaint__c record.
     * @param wizardId ID of the Wizard__c record
     * @param agreedToGdpr Boolean indicating if the user agreed to GDPR terms
     * @return ID of the new Complaint__c record
     */
    Id submitComplaint(Id wizardId, Boolean agreedToGdpr);
}