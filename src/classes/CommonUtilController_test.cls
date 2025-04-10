/**
 * Created by 송찬영 on 24. 10. 21..
 */

@IsTest
private class CommonUtilController_test {

    @TestSetup
    static void setup() {
        TestObjectBuilder2.createAccountBundle();
    }

    @IsTest
    static void testBehavior() {
        String dateTypeA = CommonUtilController.formatDate(Datetime.now(), 'A');
        String dateTypeB = CommonUtilController.formatDate(Datetime.now(), 'B');
        String dateTypeC = CommonUtilController.formatDate(Datetime.now(), 'C');

        String url = 'https://url/home?code=123';
        String codeValue = CommonUtilController.extractStringFromURL(url, 'code');

        String str = '함수 테스트중입니다. abc와 ABC는 가나다';
        List<String> returnStrList = CommonUtilController.sliceStrLength(str, 3, 6).split('<->');
        String returnStr = CommonUtilController.sliceStrLength(str, 1, 6);

        List<Map<String, String>> pickList = CommonUtilController.getPickList('Account', 'Type');
        Set<String> pickListValue = CommonUtilController.getPickListValue('Account', 'Type');
        Map<String, String> pickListMap = CommonUtilController.getPickListMap('Account', 'Type');
        String type = CommonUtilController.getPicklistLabelForLabel('Account', 'Type', 'Analyst');

        List<String> fieldList = CommonUtilController.getAllFields('Account');
        System.debug(fieldList);

        List<String> stringList = new List<String>{'123', '456'};
        String joinedString = CommonUtilController.joinedString(stringList);
        System.debug(joinedString);

        List<String> labelList = new List<String>{'Id', 'Name'};
        List<Account> accountList = [
                SELECT Id, Name
                FROM Account
        ];
        Map<String, List<SObject>> returnMap = CommonUtilController.getObjectMapJoin(accountList, labelList, '_');
        System.debug(returnMap);

        List<Account> insertList = new List<Account>();
        Account t = new Account();
        t.Name = '테스트';
        insertList.add(t);

        Map<String, Map<String, Object>> returnMap2 = CommonUtilController.applyObject(insertList, 'INSERT');
        Map<String, Object> accountMap = returnMap2.get('SUCCESS');
        for(Account acc : [
                SELECT Id
                FROM Account
                WHERE Id IN: accountMap.keySet()
        ]) {
            System.debug(acc.Id);
        }

        List<Map<String, String>> listView = CommonUtilController.getListView('Account');

        Map<String, Object> filterMap = new Map<String, Object>();
        filterMap.put('Name1', 'Test');
        filterMap.put('Name2', '!= NULL');
        filterMap.put('Name3', '= NULL');
        filterMap.put('Name4', true);
        filterMap.put('Name5', '>');
        String buildWhereConditions = CommonUtilController.buildWhereConditions(filterMap);
        String buildQuery = CommonUtilController.buildQuery('Id', 'Account', '');
        String convertId = CommonUtilController.convert15to18DigitId(t.Id.to15());
        String processStr = CommonUtilController.sliceUBarBefore('A__1');
        Boolean isWeekend = CommonUtilController.isWeekend(Date.today());
        CommonUtilController.delayTime(Datetime.now(), 1);

        CommonUtilController.sortSObjectList(accountList, 'Name', true);
    }
}