public with sharing class SRV_UY_AuxQueryParameters extends SRV_AuxQueryBase {
    public override Map<String,String> setEndpointParameters(Map<String,String> urlParams, String objectType) {

        User crrntUser = SEL_Users.newInstance().selectById(UserInfo.getUserId()).get(0);
        List<AccountRole__c> accRole = [SELECT Id, Code__c FROM AccountRole__c WHERE User__c =: crrntUser.Id];
        if(!accRole.isEmpty()){
            urlParams.put('%%Code%%', accRole.get(0).Code__c);
        }
        else{
            urlParams.put('%%Code%%', System.Label.UY_GenericAgentCode);
        }
        String userKey = crrntUser.Key__c != null ? crrntUser.Key__c : '';
        urlParams.put('%%Key%%', userKey);
        
        return urlParams;
        
        
    }    
}