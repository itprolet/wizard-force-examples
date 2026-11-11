/**
 * The records the "Referred By" lookup of the clubMembership wizard offers.
 * Called by the framework (SmartLookupCtrl) because Smart_Lookup_Setting.ClubMembership_ReferredBy
 * names this class and the method 'search'.
 *
 * WIZARD-MAKER: created once by "npm run make page"; write your own search here.
 */
public with sharing class ClubMembershipReferredByLookup implements Callable {

    public Object call(String action, Map<String, Object> arguments) {
        switch on action {
            when 'search' {
                return search((String) arguments.get('$searchValue'), arguments);
            }
            when else {
                throw new IllegalArgumentException('Unknown action: ' + action);
            }
        }
    }

    /**
     * @param searchValue what the user typed (may be empty)
     * @param arguments   the values of arg0-value … arg9-value of the field, e.g. arguments.get('arg0')
     * @return the records to offer; each needs the fields Id and Name (key-field and name-field in the page)
     */
    private List<SObject> search(String searchValue, Map<String, Object> arguments) {
        // What the user typed as a LIKE pattern, with the rules of every lookup: the text is
        // searched anywhere, "*" is the user's wildcard, "%" and "_" are plain characters.
        String query = prolet.WizardApi.likePattern(searchValue);

        // WIZARD-MAKER: your own search. This start does the same as a simple lookup.
        // Keep WITH USER_MODE in every query: the user then gets only the records, the objects
        // and the fields they have access to. ("with sharing" alone checks the records only.)
        // The framework also takes fields the user may not read out of what this method returns.
        return [
            SELECT Id, Name
            FROM User
            WHERE Name LIKE :query
            WITH USER_MODE
            ORDER BY Name
            LIMIT 30
        ];
    }
}
