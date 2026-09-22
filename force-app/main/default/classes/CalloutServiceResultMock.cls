global with sharing class CalloutServiceResultMock {

    global static Map<String, Object> getMockData(String serviceName) {

        List<Map<String, Object>> columns = new List<Map<String, Object>>{
            new Map<String, Object>{
                'label' => 'Id recibo',
                'fieldName' => 'receiptId',
                'type' => 'text'
            },
            new Map<String, Object>{
                'label' => 'Número de recibo',
                'fieldName' => 'receiptNumber',
                'type' => 'text'
            },
            new Map<String, Object>{
                'label' => 'Fecha de recibo',
                'fieldName' => 'receiptDate',
                'type' => 'date'
            },
            new Map<String, Object>{
                'label' => 'Moneda',
                'fieldName' => 'currency',
                'type' => 'text'
            },
            new Map<String, Object>{
                'label' => 'Importe total',
                'fieldName' => 'totalAmount',
                'type' => 'currency'
            },
            new Map<String, Object>{
                'label' => 'Método de pago',
                'fieldName' => 'paymentMethod',
                'type' => 'text'
            },
            new Map<String, Object>{
                'label' => 'Estado',
                'fieldName' => 'status',
                'type' => 'text'
            },
            new Map<String, Object>{
                'label' => 'Id póliza',
                'fieldName' => 'policyId',
                'type' => 'text'
            }
        };

        List<Map<String, Object>> data = new List<Map<String, Object>>{
            new Map<String, Object>{
                'policy' => 'MOCK-001',
                'receiptId' => '1-0040000534655-10-0-MOCK',
                'receiptNumber' => '39301050',
                'receiptDate' => '2027-04-02',
                'currency' => 'UYU',
                'totalAmount' => 335.25,
                'paymentMethod' => 'Pagos online',
                'status' => 'EMITIDO PENDIENTE DE PAGO',
                'policyId' => '0040000534655'
            },
            new Map<String, Object>{
                'policy' => 'MOCK-002',
                'receiptId' => '1-0040000534649-5-0-MOCK',
                'receiptNumber' => '39301019',
                'receiptDate' => '2027-03-02',
                'currency' => 'UYU',
                'totalAmount' => 787.97,
                'paymentMethod' => 'Pagos online',
                'status' => 'NOVO VALOR ADICIONADO',
                'policyId' => '0040000534649'
            }
        };

        Map<String, Object> response = new Map<String, Object>();

        response.put('columns', JSON.serialize(columns));
        response.put('data', JSON.serialize(data));

        Map<String, Map<String, String>> preview =
            new Map<String, Map<String, String>>();

        Integer index = 0;

        for (Map<String, Object> row : data) {

            Map<String, String> previewRow =
                new Map<String, String>();

            for (Map<String, Object> column : columns) {

                String fieldName = (String) column.get('fieldName');
                String label = (String) column.get('label');

                if (row.containsKey(fieldName) && row.get(fieldName) != null) {
                    previewRow.put(
                        label,
                        String.valueOf(row.get(fieldName))
                    );
                }
            }

            preview.put(String.valueOf(index), previewRow);
            index++;
        }

        response.put('preview', preview);

        return response;
    }
}