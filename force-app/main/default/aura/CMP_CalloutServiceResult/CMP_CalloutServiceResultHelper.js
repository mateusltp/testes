({
	getResult : function(component, helper) {

		helper.getCalloutResults(component, helper);
		
	},

	getCalloutResults: function(component, helper) {

        //teste
        var useMockData = true;
        if (useMockData) {
            helper.setMockData(component);
            return;
        }
        //teste
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
    //teste
    setMockData: function(component) {
        var columns = [
            { label: "Id recibo", fieldName: "receiptId", type: "text" },
            { label: "Número de recibo", fieldName: "receiptNumber", type: "text" },
            { label: "Fecha de recibo", fieldName: "receiptDate", type: "date" },
            { label: "Moneda", fieldName: "currency", type: "text" },
            { label: "Importe total", fieldName: "totalAmount", type: "currency" },
            { label: "Método de pago", fieldName: "paymentMethod", type: "text" },
            { label: "Estado", fieldName: "status", type: "text" },
            { label: "Id póliza", fieldName: "policyId", type: "text" }
        ];
        var data = [
{
        policy: "MOCK-001",
        receiptId: "1-0040000534655-10-0-MOCK",
        receiptNumber: "39301050",
        receiptDate: "2027-04-02",
        currency: "UYU",
        totalAmount: 335.25,
        paymentMethod: "Pagos online",
        status: "EMITIDO PENDIENTE DE PAGO",
        policyId: "0040000534655"
    },
    {
        policy: "MOCK-002",
        receiptId: "1-0040000534649-5-0-MOCK",
        receiptNumber: "39301019",
        receiptDate: "2027-03-02",
        currency: "UYU",
        totalAmount: 787.97,
        paymentMethod: "Pagos online",
        status: "NOVO VALOR ADICIONADO",
        policyId: "0040000534649"
    },
    {
        policy: "MOCK-003",
        receiptId: "1-0040000534650-1-0-MOCK",
        receiptNumber: "39301020",
        receiptDate: "2027-01-15",
        currency: "UYU",
        totalAmount: 1250.00,
        paymentMethod: "Débito Automático",
        status: "COBRADO",
        policyId: "0040000534650"
    },
    {
        policy: "MOCK-004",
        receiptId: "1-0040000534651-2-0-MOCK",
        receiptNumber: "39301021",
        receiptDate: "2027-02-10",
        currency: "USD",
        totalAmount: 450.50,
        paymentMethod: "Tarjeta de Crédito",
        status: "EMITIDO PENDIENTE DE PAGO",
        policyId: "0040000534651"
    },
    {
        policy: "MOCK-005",
        receiptId: "1-0040000534652-3-0-MOCK",
        receiptNumber: "39301022",
        receiptDate: "2027-02-28",
        currency: "UYU",
        totalAmount: 980.00,
        paymentMethod: "Transferencia",
        status: "CANCELADO",
        policyId: "0040000534652"
    },
    {
        policy: "MOCK-006",
        receiptId: "1-0040000534653-4-0-MOCK",
        receiptNumber: "39301023",
        receiptDate: "2027-03-12",
        currency: "UYU",
        totalAmount: 610.10,
        paymentMethod: "Pagos online",
        status: "COBRADO",
        policyId: "0040000534653"
    },
    {
        policy: "MOCK-007",
        receiptId: "1-0040000534654-5-0-MOCK",
        receiptNumber: "39301024",
        receiptDate: "2027-03-25",
        currency: "USD",
        totalAmount: 120.00,
        paymentMethod: "Débito Automático",
        status: "EMITIDO PENDIENTE DE PAGO",
        policyId: "0040000534654"
    },
    {
        policy: "MOCK-008",
        receiptId: "1-0040000534656-6-0-MOCK",
        receiptNumber: "39301025",
        receiptDate: "2027-04-10",
        currency: "UYU",
        totalAmount: 2150.75,
        paymentMethod: "Convenio",
        status: "VENCIDO",
        policyId: "0040000534656"
    },
    {
        policy: "MOCK-009",
        receiptId: "1-0040000534657-7-0-MOCK",
        receiptNumber: "39301026",
        receiptDate: "2027-04-18",
        currency: "UYU",
        totalAmount: 430.00,
        paymentMethod: "Pagos online",
        status: "COBRADO",
        policyId: "0040000534657"
    },
    {
        policy: "MOCK-010",
        receiptId: "1-0040000534658-8-0-MOCK",
        receiptNumber: "39301027",
        receiptDate: "2027-05-01",
        currency: "USD",
        totalAmount: 85.00,
        paymentMethod: "Tarjeta de Crédito",
        status: "EMITIDO PENDIENTE DE PAGO",
        policyId: "0040000534658"
    }
        ];
        var preview = data.map(function(receipt) {
            return {
                key: receipt.policy,
                value: [
                    { key: "Número de recibo", value: receipt.receiptNumber },
                    { key: "Fecha de recibo", value: receipt.receiptDate },
                    { key: "Importe total", value: receipt.totalAmount + " " + receipt.currency }
                ]
            };
        });

        component.set("v.dataTableColumns", columns);
        component.set("v.objectData", data);
        component.set("v.dataTableData", data);
        component.set("v.previewData", preview);
        component.set("v.showLoading", false);
    },
    //teste
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