/*************************************************************
 * @author : th.kim
 * @date : 2025-02-03
 * @description :
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-02-03      th.kim          Initial Version
 **************************************************************/
import LightningDatatable from "lightning/datatable";
import helpTextColumn from "./helpTextColumn.html";
import nameHelpTextTemplate from "./nameHelpTextTemplate.html";
// Test
export default class customDataTable extends LightningDatatable {

	static customTypes = {
		helpTextType: {
			template: helpTextColumn,
			standardCellLayout: true,
			typeAttributes: ["optionQty", "defaultOptionQty", "specialQty"]
		},
		nameHelpTextType: {
			template: nameHelpTextTemplate,
			standardCellLayout: true,
			typeAttributes: ["content"]
		},
	};
}