/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-01-21      payo03@solomontech.net           Created
*/
@IsTest
private class FinancialDefermentRequest_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createOpportunityBundle();
    }

    @IsTest
    static void testBehavior() {
        Opportunity opportunity = [
                SELECT Id, Name,
                    (
                        SELECT Id
                        FROM Quotes
                        WHERE Status = 'Published'
                    )
                FROM Opportunity
                LIMIT 1
        ];
        Map<String, String> paramMap = new Map<String, String>{
                'recordId'          => opportunity.Id,
                'apiName'           => 'test',
                'updateField'       => 'TaxDeferredAmount__c',
                'deferredAmount'    => '100',
                'contractAmount'    => '100',
                'comment'           => 'test',

                'opportunityName'   => opportunity.Name,
                'dueDate'           => String.valueOf(Date.today()),
                'isCheck'           => String.valueOf(true),
                'requestDueDate'    => String.valueOf(Date.today()),
                'requestDays'       => '3'
        };

        FinancialDefermentRequest.screenInit(opportunity.Id);
        FinancialDefermentRequest.requestDeferred(paramMap);
        FinancialDefermentRequest.createDefermentRequest(paramMap);

    }
}