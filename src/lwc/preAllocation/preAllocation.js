/*************************************************************
 * @author : chaebeom.do
 * @date : 2024-12-31
 * @description : 견적 레코드 상세 페이지에서 버튼 클릭시 차량 사전배정요청 생성
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-12-31      chaebeom.do     Created
 **************************************************************/
import { api, LightningElement } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";

//library
// import getPreAllocationStatus from "@salesforce/apex/CreateAssignRequestController.getPreAllocationStatus";
// import createApprovalProcess from "@salesforce/apex/CreateAssignRequestController.createApprovalProcess";

// Util
import { showToast } from "c/commonUtil";

export default class PreAllocation extends LightningElement {

  // @api recordId;
  // approvalComment;
  // deposit;

  // defaultModal = true;
  // depositModal = false;

  // handlePreAllocation() {
  //   if (this.deposit == null) {
  //     showToast("필수 입력", "계약금을 입력해주세요.", "error");
  //   } else {
  //     getPreAllocationStatus({recordId: this.recordId}).then(res => {
  //       if (res) {
  //         showToast("", "해당 기회에 진행 중인 승인 프로세스가 있습니다.", "warning");
  //       } else {
  //         let inputMap = { 
  //           recordId: this.recordId, 
  //           comment: this.approvalComment, 
  //           deposit: this.deposit, 
  //           type: 'preAllocation' 
  //         };
  //         createApprovalProcess({inputMap: inputMap}).then(res2 => {
  //           showToast("", res2, "success");
  //           this.handleCancel();
  //           setTimeout(() => {
  //             location.reload();
  //           }, 1000);
  //         }).catch(err => {
  //           console.log("err :: ", err);
  //           showToast("관리자에게 문의바랍니다.", err, "error");
  //         })
  //         // showToast("", "사전 배정 승인을 신청했습니다.", "success");
  //       }
  //     })
  //   }
  // }

  // handleChange(e) {
  //   const value = e.target.value;
  //   const id = e.target.dataset.id;
  //   if (id === "deposit") {
  //     this.deposit = value;
  //   } else {
  //     this.approvalComment = value;
  //   }
  // }

  // handleCancel() {
  //   this.dispatchEvent(new CloseActionScreenEvent());
  // }
}