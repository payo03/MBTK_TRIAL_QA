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

export default class customDataTable extends LightningDatatable {

	static customTypes = {
		helpTextType: {
			template: helpTextColumn,
			standardCellLayout: true,
			typeAttributes: ["optionQty", "defaultOptionQty", "specialQty"]
		}
	};
}