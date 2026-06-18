public without sharing class ComplaintController {
    public static final IComplaintService complaintService = new ComplaintService();

    @AuraEnabled
    public static Id submitComplaint(Id wizardId, Boolean agreedToGdpr ) {
        try {
             return complaintService.submitComplaint(wizardId, agreedToGdpr);
        } catch (Exception e) {
            throw new AuraHandledException('Error submitting complaint: ' + e.getMessage());
        }
    }
}