({
    initializeData : function(component) {
        var columns = (component.get('v.dataTableColumnsMODAL') || []).map(function(column) {
            var displayColumn = Object.assign({}, column);
            if (displayColumn.fieldName && displayColumn.type !== 'action' && displayColumn.type !== 'button') {
                displayColumn.sortable = true;
            }
            return displayColumn;
        });
        var data = (component.get('v.dataTableDataMODAL') || []).slice();

        component.set('v.displayColumns', columns);
        component.set('v.originalData', data);
        component.set('v.searchTerm', '');
        component.set('v.sortedBy', null);
        component.set('v.sortedDirection', 'asc');
        component.set('v.displayData', data);
    },

    filterData : function(component) {
        var searchTerm = this.normalizeValue(component.get('v.searchTerm'));
        var columns = component.get('v.displayColumns') || [];
        var data = component.get('v.originalData') || [];
        var filteredData = data.filter(function(row) {
            return !searchTerm || columns.some(function(column) {
                return column.fieldName && this.normalizeValue(this.getFieldValue(row, column.fieldName)).indexOf(searchTerm) !== -1;
            }, this);
        }, this);

        component.set('v.displayData', filteredData);
        this.sortData(component);
    },

    sortData : function(component) {
        var fieldName = component.get('v.sortedBy');
        if (!fieldName) {
            return;
        }

        var direction = component.get('v.sortedDirection') === 'desc' ? -1 : 1;
        var data = (component.get('v.displayData') || []).slice();
        data.sort(function(firstRow, secondRow) {
            var firstValue = this.getFieldValue(firstRow, fieldName);
            var secondValue = this.getFieldValue(secondRow, fieldName);
            if (firstValue === secondValue) {
                return 0;
            }
            if (firstValue === null || firstValue === undefined) {
                return -1 * direction;
            }
            if (secondValue === null || secondValue === undefined) {
                return direction;
            }
            if (typeof firstValue === 'number' && typeof secondValue === 'number') {
                return (firstValue - secondValue) * direction;
            }
            return String(firstValue).localeCompare(String(secondValue), undefined, {
                numeric: true,
                sensitivity: 'base'
            }) * direction;
        }.bind(this));
        component.set('v.displayData', data);
    },

    getFieldValue : function(row, fieldName) {
        return fieldName.split('.').reduce(function(value, key) {
            return value === null || value === undefined ? null : value[key];
        }, row);
    },

    normalizeValue : function(value) {
        return value === null || value === undefined
            ? ''
            : String(value).normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
    },

	basetoBlobDownload : function(wrap){

        var byteCharacters = atob(wrap.documentContent);
                
        const buf = new Array(byteCharacters.length);
        for (var i = 0; i != byteCharacters.length; ++i) buf[i] = byteCharacters.charCodeAt(i);// & 0xFF;
        
        const view = new Uint8Array(buf);
        
        const blob = new Blob([view], {
            type: 'application/octet-stream'
        });
        
        // Automatically download the file by appending an a element,
        // 'clicking' it, and removing the element
        const a = window.document.createElement('a');
        a.href = window.URL.createObjectURL(blob);
        a.download = wrap.name + '.pdf';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
    },preview : function(component,wrap){
	 	var modalBody;

        $A.createComponent(
            "c:cmp_pdfviewer",
            	{
                	"pdfData": wrap.documentContent
            	},
            	function(pdfViewer, status, errorMessage){
                	if (status === "SUCCESS") {

                        component.find('overlayLib').showCustomModal({
                            header: wrap.name,
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
        
        
        
        
    },
    
       
})