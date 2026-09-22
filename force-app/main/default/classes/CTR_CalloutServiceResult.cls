/**
 * @File Name          : CONTROLLERResultService.cls
 * @Description        : 
 * @Author             : Everis
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 27/3/2020 16:34:15
 * @Modification Log   : 
 * Ver      Date            Author      		                    Modification
 * 1.0      19/03/2020      ChangeMeIn@UserSettingsUnder.SFDoc      Initial Version
**/
global with sharing class CTR_CalloutServiceResult {
	
    public static Boolean stopCallout = false;
    private static final Boolean USE_MOCK = false;
    
    @AuraEnabled
    global static Object getResultService(String serviceName, String recordId){
        
        if (USE_MOCK) {
            Map<String, Object> mockData =
                CalloutServiceResultMock.getMockData(serviceName);
            
            System.debug(
                '>>> RETORNANDO DADOS MOCK: ' +
                JSON.serialize(mockData)
            );
            
            return mockData;
        }

        Map<String,Object> mapOutput = new Map<String,Object>();
		ConfigurationService__mdt configService = new ConfigurationService__mdt();
		
        Map<String,Set<String>> configurationFilter = new Map<String,Set<String>>();
        configurationFilter.put('DeveloperName',new Set<String>{serviceName});
		if (Schema.sObjectType.ConfigurationService__mdt.isAccessible()) {
			configService = new SEL_ConfigurationServices().selectWithWhere(null, configurationFilter, null).get(0);
        }
		
        List<JSONColumn> columns = (List<JSONColumn>)JSON.deserialize(configService.Columns__c,List<JSONColumn>.class);
        Map<String,JSONColumn> mapColumn = new Map<String,JSONColumn>();
        List<String> lstColumns = new List<String>();
        for(JSONColumn column  : columns){
            mapColumn.put(column.fieldName,column);
            if(column.isPickList != null && column.isPickList){ 
                lstColumns.add('toLabel(' + column.fieldName +')'); 
            }else{ 
                lstColumns.add(column.fieldName); 
            }
	            
        }
        String strColumns = String.join(lstColumns,',');
        
        Map<String, CalloutSettings__c> calloutSettings = CalloutSettings__c.getAll();
        Map<String,Object> mapCallout = new Map<String,Object>();

        
        try {
            
            //String jsonFile = '[{"documentId":"","documentData":{"documentContent":""},"documentMetadata":{"url":"","name":"POLIZA_3011310100153_15022021","type":"PDF","description":"POLIZA","dateCapture":"2021-02-15T22:04:12.266","status":"READY","URL":"","owner":"MAPFRE","size":0,"mimeType":"application/pdf","source":""}}]';
            String body;
            if(serviceName.contains('Document')){ 
                mapCallout = callout(configService.ServiceName__c,recordId,configService.parameters__c, strColumns); 
                String jsonFile = (String)mapCallout.get('body'); 
                system.debug('jsonFile '+jsonFile); 
                jsonFile = jsonFile.replace('"url":"",','');
	                
                List<JSONDocument> documents =  (List<JSONDocument>)JSON.deserializeStrict(jsonFile,List<JSONDocument>.class);
                if(documents.size() > 0) { 
                    List<JSONDocumentResult> documentsResult = new List<JSONDocumentResult>(); 
                    for(JSONDocument jsonDoc : documents){
                        //jsonDoc.documentData.documentContent = filePDF;
                        documentsResult.add(new JSONDocumentResult(jsonDoc));
                    } 
                    body = JSON.serialize(documentsResult); 
                }
            }else{
                mapCallout = callout(configService.ServiceName__c,recordId,configService.parameters__c,strColumns);
                system.debug('mapCallout>> ' + mapCallout);
                body = (String)mapCallout.get('body');
            }
            
            if((Boolean) mapCallout.get('isError')){ 
                return mapOutput; 
            }else{
            //String jsonAttribute = configService.jsonAttribute__c;
            String bodyResult = body;
           
            List<Object> records;
            /*if(String.isNotBlank(jsonAttribute)){
                Map<String,Object> mapRecord = (Map<String,Object>)JSON.deserializeUntyped(bodyResult);
                records = (List<Object>)mapRecord.get(jsonAttribute);
                bodyResult = JSON.serialize(records);
            }else{
            }*/
            if(configService.ServiceName__c.contains('querySF')){
            	records = (List<Object>)JSON.deserializeUntyped('['+bodyResult+']');
            }else{
            	records = (List<Object>)JSON.deserializeUntyped(bodyResult);
            }
            
            
            
			Map<String,Map<String,String>> previewData = new Map<String,Map<String,String>>();
			Integer index = 0;
            for(Object objRecord : records){
                Map<String,Object> mapRecord = (Map<String,Object>)objRecord;
		        Map<String,String> record = new Map<String,String>();
                for (String fieldName : mapRecord.keySet()){
                    if(mapColumn.containsKey(fieldName)){
                        JSONColumn column = (JSONColumn)mapColumn.get(fieldName);
                        Object value = mapRecord.get(fieldName);
                        String data;

                        switch on column.type{
                            when 'currency'{
                                if (value != null) {
                                    data = ((Decimal)value).format();  
                                }else {
                                    data = '0';
                                }
                            }when 'number'{
                                if (value != null) {
                                    data = ((Decimal)value).format();
                                }else {
                                    data = '0';
                                }
                            }when 'datetime'{
                                if (value != null) {
                                    data = ((DateTime)JSON.deserialize('"'+(String)value + '"',DateTime.class)).format();
                                }else {
                                    data = null;
                                }
                            }when 'date'{
                                if (value != null) {
                                    data =  ((Date)JSON.deserialize('"'+((String)value).replace('T00:00:00','') + '"',Date.class)).format();
                                }else {
                                    data = null;
                                }
                            }when else{
                                data = (String)mapRecord.get(fieldName);
                            }
                            
                        }

                        if(column.showDefault){
							record.put(column.label,data);
						}
                            
                    }    
                }
				previewData.put(String.valueOf(index),record); 
                index++;
            }

            mapOutput.put('columns',configService.Columns__c.replace('"datetime"','"date"'));
            mapOutput.put('data',bodyResult);
            mapOutput.put('preview',previewData); 
          }      
        } catch (CalloutException e) {

        }
		
        return mapOutput;

	}

    @AuraEnabled
    global static Object getResultServiceRecord(String serviceName, String recordId){

        Map<String,String> mapOutput = new Map<String,String>();
		ConfigurationService__mdt configService = new ConfigurationService__mdt();
		
        Map<String,Set<String>> configurationFilter = new Map<String,Set<String>>();
        configurationFilter.put('DeveloperName',new Set<String>{serviceName});
		if (Schema.sObjectType.ConfigurationService__mdt.isAccessible()) {
			configService = new SEL_ConfigurationServices().selectWithWhere(null, configurationFilter, null).get(0);
        }
		
        List<JSONColumn> columns = (List<JSONColumn>)JSON.deserialize(configService.Columns__c,List<JSONColumn>.class);
        Map<String,JSONColumn> mapColumn = new Map<String,JSONColumn>();
        List<String> lstColumns = new List<String>();
        for(JSONColumn column  : columns){
            mapColumn.put(column.fieldName,column);
            if(column.isPickList != null && column.isPickList){ 
                lstColumns.add('toLabel(' + column.fieldName +')'); 
            }else{ 
                lstColumns.add(column.fieldName); 
            }
	            
        }
        String strColumns = String.join(lstColumns,',');
        
        Map<String, CalloutSettings__c> calloutSettings = CalloutSettings__c.getAll();
        Map<String,Object> mapCallout = new Map<String,Object>();
        
        try {
            
            mapCallout = callout(configService.ServiceName__c,recordId,configService.parameters__c, strColumns);
            system.debug('mapCallout>> ' + mapCallout);
            String body = (String)mapCallout.get('body');
            
            if((Boolean) mapCallout.get('isError')){
                mapOutput.put('columns','');
                mapOutput.put('data','');
                return mapOutput; 
            }else{
                String bodyResult = body;
                mapOutput.put('columns',configService.Columns__c.replace('"datetime"','"date"'));
                mapOutput.put('data',bodyResult);
            }      
        } catch (CalloutException e) {

        }
		
        return mapOutput;
	}
    
    public static Map<String,Object> callout(String calloutName, Id recordId,String jsonParameters, String strColumns){
        String sobjectType = recordId.getSObjectType().getDescribe().getName();
        SObject recordObj;
        switch on sobjectType{
            when 'Account'{
                recordObj = (SObject)new SEL_Accounts().selectById(recordId).get(0);
            }
            when 'CustomContract__c'{ 
                recordObj = (SObject)new SEL_CustomContracts().selectById(recordId).get(0); 
            }
            when 'Lead'{ 
                recordObj = (SObject)new SEL_Leads().selectById(recordId).get(0); 
            }
            when 'AccountRole__c'{ 
                recordObj = (SObject)new SEL_AccountRoles().selectById(recordId).get(0); 
            }
        }
        
        Map<String, String> urlParamMap = new Map<String, String>();
        urlParamMap.put('%%recordId%%',recordId);
        urlParamMap.put('%%columns%%',strColumns);
        if(String.isNotEmpty(jsonParameters)){
			List<CTR_CalloutServiceResult.Parameter> parameters = (List<CTR_CalloutServiceResult.Parameter>)JSON.deserializeStrict(jsonParameters,List<CTR_CalloutServiceResult.Parameter>.class);
            for(CTR_CalloutServiceResult.Parameter parameter : parameters){
                String value = parameter.value;
                switch on parameter.value{
                    when 'PreviusYear'{ 
                        value = String.valueOf(Date.today().addYears(-1).year()) + '-01-01';
                    }when 'CurrentYear'{ 
                        value = String.valueOf(Date.today().year())	+ '-12-31';
                    }when  else{
                        System.debug('Parameter type value: '+ parameter.type);
                        if(parameter.type == 'Field'){
                            if(recordObj.get(parameter.value) != null){ 
                                if(parameter.auxQuery != null){
                                    CalloutSettings__c auxQuerySettings = CalloutSettings__c.getValues(parameter.auxQuery);
                                    if (auxQuerySettings != null){
                                        SRV_AuxQueryBase aux = SRV_AuxQueryFactory.getAux(auxQuerySettings.AuxQueryParameters__c);
                                        aux.setEndPointParameters(urlParamMap, sobjectType);
                                    }
                               }
                                System.debug('Parameter needTokenization value: '+ parameter.needTokenization);
                                if(parameter.needTokenization=='true'){//por cada parametro que necesite token del endpoint
                                    CalloutSettings__c serviceTokenSetting = CalloutSettings__c.getValues(parameter.serviceToken);//CalloutSetting de servicio Tokenizador
                                    SRV_BaseAux serviceTokenAux= SRV_AuxFactory.getAux(serviceTokenSetting.AuxClassName__c);//Clase que completa el body del servicio Tokenizador
                                    SRV_Callouts tokenCall = new SRV_Callouts(parameter.serviceToken);//Token service call
                                    tokenCall.setBody(serviceTokenAux.setBodyRequest(parameter.value, recordId));
                                    SRV_HttpCustomResponse tokenizedCallResponse = tokenCall.doCallout();
                                    System.debug('Response token call: '+ tokenizedCallResponse.getData());
                                    if(!tokenizedCallResponse.isError()){
                                        value = (String)serviceTokenAux.getParameterResponse(tokenizedCallResponse.getData());
                                        System.debug('Tokenized value: '+ value);
                                    }else{
                                        value=null;
                                    }
                                }else{
                                    value = (String)recordObj.get(parameter.value);
                                } 
                            }else{ 
                                stopCallout = true;
                            }
                        }
                    }    
                }
                urlParamMap.put('%%' + parameter.name + '%%',value);
            }                        
        }

        Map<String,Object> mapOutput = new Map<String,Object>();
        if(!stopCallout){
            SRV_Callouts calloutService = new SRV_Callouts(calloutName);
            calloutService.setUrlParams(urlParamMap);
            String jsonResponse = (String)calloutService.doCallout().getData();
            system.debug('jsonResponse>>> ' + jsonResponse);
            mapOutput.put('isError',false);
            mapOutput.put('body',jsonResponse);
        }else{
            mapOutput.put('isError',true);
            mapOutput.put('body', 'Parameter null');
        }
        
        return mapOutput;
    }

    class JSONColumn{
        public String fieldName;
        public String label;
        public String type;
        public Boolean isPickList;
        public Boolean showDefault;
    }
    	
	class JSONDocumentResult{

        public JSONDocumentResult(JSONDocument jsonDoc){	

            if(jsonDoc.documentData != null){ 
                this.documentContent = jsonDoc.documentData.documentContent; 
            }
            if(jsonDoc.documentMetaData != null){ 
                this.name = jsonDoc.documentMetaData.name; 
                this.description = jsonDoc.documentMetaData.description;  
                this.mimeType = jsonDoc.documentMetaData.mimeType;
            }
            
        }
        
        public String documentContent;
        public String name;
        public String description;
        public String mimeType;
    }    
    
	class JSONDocument{
        public String documentId;
        public JSONDocumentData documentData;
        public JSONDocumentMetaData documentMetaData;
    }
    
    class JSONDocumentData{
        public String documentContent;
    }
    
	class JSONDocumentMetaData{
        public String URL;
        public String type;
        public String dateCapture;
        public String status;
        public Integer size;
        public String name;
        public String owner;
        public String source;
        public String description;
        public String mimeType;
        
    }
    class Parameter{
        public String name;
        public String value;
        public String type;
        public String needTokenization;
        public String serviceToken;
        public String auxQuery;
    }  
}