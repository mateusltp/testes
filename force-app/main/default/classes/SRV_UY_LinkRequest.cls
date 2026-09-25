public with sharing class SRV_UY_LinkRequest {

    @invocableMethod
    public static List<ResponseBody> doLogin(List<RequestBody> jsonBody){
        SRV_Callouts call = new SRV_Callouts('UY_Authentication');
        List<SRV_UY_LinkRequest.ResponseBody> responses = new List<SRV_UY_LinkRequest.ResponseBody>();
        SRV_HttpCustomResponse response = call.doCallout();
        SRV_UY_LinkRequest.LoginResponse loginResponse = (SRV_UY_LinkRequest.LoginResponse) System.JSON.deserialize(response.getBody(), SRV_UY_LinkRequest.LoginResponse.class);
        responses = doRequest(jsonBody, responses, loginResponse.token);
        return responses;
    }

    public static List<ResponseBody> doRequest(List<RequestBody> jsonBody, List<SRV_UY_LinkRequest.ResponseBody> responses, String token){

        SRV_Callouts call = new SRV_Callouts('UY_GetQuoteLink');
        if(!jsonBody.isEmpty()){
            Map<String,String> headers = new Map<String,String>();
            headers.put('Content-Length', String.valueOf(String.valueOf(jsonBody[0]).length()));
            headers.put('token', token);
            System.debug('Request ' + jsonBody[0]);
            call.setBody(jsonBody[0]);
            call.setHeaders(headers);
            SRV_HttpCustomResponse answer = call.doCallout();
            System.debug('Answer ' + answer.getBody());
            SRV_UY_LinkRequest.ResponseBody resp = (SRV_UY_LinkRequest.ResponseBody) System.JSON.deserialize(answer.getBody(), SRV_UY_LinkRequest.ResponseBody.class);
            responses.add(resp);
        }
        return responses;
    }
  
    public class RequestBody{
        @InvocableVariable
        public String codAgt;
        @InvocableVariable
        public String clientId;
        @InvocableVariable
        public String key;
        @InvocableVariable
        public String opportunityID;
        @InvocableVariable
        public String quotationId;
        @InvocableVariable
        public String tip;
        @InvocableVariable
        public String branch;
        @InvocableVariable
        public SRV_UY_AccountWrapper account;
    }

    public class ResponseBody{
        @InvocableVariable
        public String link;
        @InvocableVariable
        public String message;
    }

    public class LoginResponse{
        public String resultado;
        public String token;
    }
}