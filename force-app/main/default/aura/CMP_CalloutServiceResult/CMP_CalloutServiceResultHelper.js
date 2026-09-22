({
	getResult : function(component, helper) {

		helper.getCalloutResults(component, helper);
		
	},

	getCalloutResults: function(component, helper) {

		var action = component.get("c.getResultService");
		action.setParams({ 
			serviceName : component.get("v.serviceName"),
            recordId : component.get("v.recordId")
		});
		
        component.set("v.showLoading",true);
        
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
                try {
				//component.set('v.dataTableColumns', JSON.parse(component.get("v.allColumns")));
                var nameservice = component.get("v.serviceName");
				var responseData = response.getReturnValue();

                var jSonParse = JSON.parse(responseData && responseData.data ? responseData.data : '[]');

                if(jSonParse != null){ 
                    console.log(jSonParse);
					component.set('v.dataList', responseData.data); 
                    if(nameservice.includes('querySF')){
                        jSonParse.length = jSonParse.totalSize;
                    } 
					component.set('v.objectData', jSonParse);   
					component.set('v.dataTableData', jSonParse); 

                    var newRecords = [];
                    var records = responseData.preview;
                    if(nameservice.includes('querySF')){
                        var columnsJSON = JSON.parse(responseData.columns);
                        var columnsFinal = [];
                        for(var columfld in columnsJSON){
                            if(columnsJSON[columfld].type != 'Id'){
                                columnsFinal.push(columnsJSON[columfld]);
                            }
                        }
                        component.set('v.dataTableColumns', columnsFinal);

                        var dataFinal = [];
                        for(var j in jSonParse.records){
                            var rcrd = JSON.stringify(jSonParse.records[j]);
                            var newColumn = [];
                            var data = [];
                            var idFound = false;
                            var keyId = '';
                            for(var i in columnsJSON){
                                var fldName = columnsJSON[i].fieldName;
                                var labelName = columnsJSON[i].label;
                                var aux = JSON.parse(rcrd);
                                var typefld = columnsJSON[i].type;
                                if(typefld == 'Id' && !idFound){ // Si un campo tiene el tipo id se asigna este valor a la clave del registro
                                    keyId = aux[fldName];
                                    idFound = true;
                                }else{
                                    if(!idFound){ // Si ya se ha encontrado un campo tipo Id no se machaca el valor del keyId
                                        keyId = j;
                                    }
                                }
                                var keyText = '';
                                var listfld = fldName.split(".");
                                if(listfld.length > 0){ // If para campos de la query que sean una relación
                                    var keyTextAux = '';
                                    var rcrdaux = aux;
                                    for(var c in listfld){
                                        keyTextAux = rcrdaux[listfld[c]];
                                        rcrdaux = keyTextAux;
                                    }
                                    keyText = rcrdaux;
                                }else{
                                    keyText = aux[fldName];
                                }
                                if(typefld != 'Id'){
                                    newColumn.push({value:keyText, key:labelName, type:typefld}); // Se guarda el tipo del campo, porque si es link se crea una redirección
                                    var datarcrd = '"' + fldName + '":"' + keyText + '"';
                                    data.push(datarcrd);
                                }
                            }
                            data = '{' + data + '}';
                            dataFinal.push(data);
                            newRecords.push({value:newColumn, key:keyId}); // Se le asigna el keyId a la clave registro
                        }
                        dataFinal = '[' + dataFinal + ']';
                        component.set('v.dataTableData', JSON.parse(dataFinal));        
                    }else{
                        component.set('v.dataTableColumns',JSON.parse(responseData.columns));
                        for(var key in records){
                            var newColumn = [];
                            var columns = records[key];
                            for(var keyCol in columns){
                                newColumn.push({value:columns[keyCol], key:keyCol})
                            }
                            newRecords.push({value:newColumn, key:key});
                        }
                    }
                    component.set('v.previewData', newRecords);
					component.set("v.showLoading",false);
                }else{
	                component.set('v.objectData', []); 
                    component.set('v.dataTableData', []);
                }
                } catch (error) {
                    console.error('Error processing CalloutServiceResult response', error);
                    component.set('v.objectData', []);
                    component.set('v.dataTableData', []);
                } finally {
                    component.set("v.showLoading",false);
                }
			} else if (state === "INCOMPLETE") {
                component.set("v.showLoading",false);
            }
            else if (state === "ERROR") {
                component.set("v.showLoading",false);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }

		});
		// enqueue the action
		$A.enqueueAction(action);

	},
    
	getViewColumns: function(component, helper) {
		var action = component.get("c.getColumns");
        
		action.setParams({ 
			serviceName : component.get("v.serviceName")
		});

		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				component.set('v.allColumns', response.getReturnValue());
			}
		});
		// enqueue the action
		$A.enqueueAction(action);

	},
    getContentData : function(component, event, helper) {
        var content = event.currentTarget.getAttribute("data-contentdata");
        var fileName = event.currentTarget.getAttribute("data-fileName");
        component.set('v.contentData',content);
        component.set('v.fileName',fileName);
	}
    ,
    previewFile : function(component, event, helper) {
        
         $A.createComponent(
            "c:cmp_pdfviewer",
            	{
                	"pdfData": component.get('v.contentData')

            	},
            	function(pdfViewer, status, errorMessage){
                	if (status === "SUCCESS") {

                        component.find('overlayLib').showCustomModal({
                            header: component.get('v.fileName'),
                            body: pdfViewer,
                            showCloseButton: true,
                            cssClass: "mymodal slds-modal_large",
                            closeCallback: function() {
                            }
                        });
                	}
                	else if (status === "INCOMPLETE") {
                        alert("No response from server or client is offline.");
                    	console.log("No response from server or client is offline.")
                	}
                	else if (status === "ERROR") {
                        alert("Error: " + errorMessage);
                        console.log("Error: " + errorMessage);
	                }
       			}
    	);
        
    }
    
})