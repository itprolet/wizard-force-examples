/**
 * Tests of ClubMembershipReferredByLookup.
 * WIZARD-MAKER: created once by "npm run make page". Add tests for the search you write.
 */
@isTest
private class ClubMembershipReferredByLookupTest {

    @isTest
    static void searchReturnsAList() {
        Callable lookup = new ClubMembershipReferredByLookup();
        Map<String, Object> arguments = new Map<String, Object>{ '$searchValue' => 'no record has this name' };

        List<SObject> records = (List<SObject>) lookup.call('search', arguments);

        Assert.isNotNull(records, 'The lookup returns a list, also when nothing is found');
    }

    @isTest
    static void unknownActionFails() {
        try {
            new ClubMembershipReferredByLookup().call('somethingElse', new Map<String, Object>());
            Assert.fail('An unknown action should fail');
        } catch (IllegalArgumentException e) {
            Assert.isTrue(e.getMessage().contains('somethingElse'), 'The message names the action');
        }
    }
}
