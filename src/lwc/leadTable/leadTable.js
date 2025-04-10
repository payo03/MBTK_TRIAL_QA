/*************************************************************
 * @author : th.kim
 * @date : 2024-11-07
 * @description :
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-11-07      th.kim          Created
 * 1.1          2024-11-25      jh.jung         Lead, Task 변경
 * 1.2          2024-12-02      jh.jung         ios, android 포커스 문제 해결
 **************************************************************/
import { LightningElement, track, api } from "lwc";
import { showToast, defaultNavigation, navItemPageNavigation } from "c/commonUtil";
import {NavigationMixin} from "lightning/navigation";
import LightningConfirm from "lightning/confirm";

import getTaskListByLeadId from "@salesforce/apex/LeadManagementController.getTaskListByLeadId";
import getLeadListByFilter from "@salesforce/apex/LeadManagementController.getLeadListByFilter";
// import convertByLead from "@salesforce/apex/LeadManagementController.convertByLead";
import createPreQuote from "@salesforce/apex/LeadManagementController.createPreQuote";
import callApprovalProcess from "@salesforce/apex/LeadManagementController.callApprovalProcess";
import saveTask from "@salesforce/apex/LeadManagementController.saveTask";


const taskSubjectDefualtValue = '기타';

export default class leadTable extends NavigationMixin(LightningElement) {

	@track isLoading = false;
	@track filteredLeadList = [];
	@track taskListByCheckedLead = [];

	checkedRecordId = '';
	selectedProductId = '';
	selectedCampaignId = '';
	selectedCampaignList = [];

	isConvertModal = false;
	isTaskModal = false;

	taskSubjectValue = taskSubjectDefualtValue;
	taskDescriptionValue = '';
	taskSubjectOption = [
		{label: '기타', value: '기타'},
		{label: '전화', value: '전화'},
		{label: '메모', value: '메모'},
	];

	myMap = new Map([
		['15', '15일 이내'],
		['30', '15일 ~ 30일'],
		['60', '30일 ~ 60일'],
		['999', '60일 이후']
	]);
	markerFilterValue = '15';

	get selectedValue() {
		return this.myMap.get(this.markerFilterValue) || 'Key not found';
	}

	/**
	 * @description 리드 데이터 가져오기
	 */
	connectedCallback() {
		this.getLeadList();
	}

	getLeadList() {
		this.isLoading = true;
		getLeadListByFilter({num : this.markerFilterValue}).then(res => {
			this.filteredLeadList = res;
			this.filteredLeadList.forEach(lead => {
				lead.url = '/lightning/r/Lead/' + lead.Id + '/view';
			});
			this.isLoading = false;

			// 선택한 리드 값이 있다면 포커싱
			if(this.checkedRecordId !== '') {
				this.getClickDataFromParent(JSON.parse(JSON.stringify({Id : this.checkedRecordId})));
			}
		}).catch(err => {
			console.log("err :: ", err);
			this.isLoading = false;
		});
	}

	/**
	 * @description Main 컴포넌트에서 데이터 받아와서 선택된 row highlight 처리
	 * @param data 맵에서 선택한 리드 데이터
	 */
	@api getClickDataFromParent(data) {

		const allRows = this.template.querySelectorAll('.lead-table-body tr');

		// 각 행에 대해 반복하면서 속성과 클래스를 제거
		allRows.forEach(row => {
			row.removeAttribute('tabindex');
			row.classList.remove("slds-theme_info");
		});

		this.changeCheckedLead(data.Id);

		const targetRow = this.template.querySelector(`tr[data-id="${this.checkedRecordId}"]`);
		const radioInput = this.template.querySelector(`input[type="radio"][data-id="${this.checkedRecordId}"]`);

		// 포커스
		if (targetRow) {
			targetRow.setAttribute('tabindex', '-1');
			targetRow.focus();
			targetRow.classList.add("slds-theme_info");

			// 해당 row가 화면 중앙에 보이도록 스크롤 위치를 조정
			targetRow.scrollIntoView({
				behavior: "smooth",  // 스크롤을 부드럽게 이동
				block: "center",     // 화면의 중앙에 위치하도록 설정
				inline: "nearest"    // 수평 스크롤은 가장 가까운 위치로 조정
			});
		}
		// 라디오 찍어주기
		if (radioInput) {
			radioInput.checked = true;
			radioInput.dispatchEvent(new Event('change'));
		}
	}

	// Map에서 선택한 필터 값을 받아와 리드 목록 초기화,
	@api getLeadListFromParent(data) {
		this.markerFilterValue = data;
		// 초기화 후 목록 다시 불러오기
		this.changeCheckedLead('');
		this.getLeadList();
	}

	handleRowCheckboxChange(e) {
		const leadId = e.target.dataset.id;

		// Task 불러오기
		this.getTaskList(leadId);

		this.filteredLeadList = this.filteredLeadList.map(lead => {
			lead.checked = false;
			if (lead.Id === leadId) {
				return { ...lead, checked: true };
			}
			return lead;
		});

		this.changeCheckedLead(leadId)

		// 12/06 다시 확인 필요
		// 선택한 리드 값이 있다면 포커싱
		// if(this.checkedRecordId !== '') {
		// 	this.getClickDataFromParent(JSON.parse(JSON.stringify({Id : this.checkedRecordId})));
		// }
	}

	getTaskList(leadId) {
		this.isLoading = true;

		getTaskListByLeadId({leadId : leadId}).then(res => {
			this.taskListByCheckedLead = res;
			// Todo: 정보 바뀌면 수정 필요
			this.taskListByCheckedLead.forEach(task => {
				task.Subject = (task.Subject != null) ? task.Subject : '';
				task.ActivityDate = (task.ActivityDate != null) ? task.ActivityDate : '';
				task.Description = (task.Description != null) ? task.Description : '';
			});
			this.isLoading = false;
		}).catch(err => {
			console.log("err :: ", err);
			this.isLoading = false;
		});
	}

	convertHandler() {

		const checkedLead = this.filteredLeadList
			.filter(lead => lead.checked)
			.map(({ checked, url, ...lead }) => lead);

		if(checkedLead.length === 0) {
			showToast("기회 변환 Error", "선택한 리드가 없습니다.", "warning");
			return;
		}

		if(this.selectedProductId === '' || typeof this.selectedProductId === 'undefined') {
			showToast("Error", "선택한 차종이 없습니다.", "warning");
			return;
		}

		this.isLoading = true;
		// convertByLead({
		// 	checkedLead : checkedLead[0],
		// 	productId : this.selectedProductId,
		// 	campaignListString : JSON.stringify(this.selectedCampaignList)
		// }).then(res => {
		const inputMap = {
			'leadId' : checkedLead[0]['Id']
			, 'productId' : this.selectedProductId
			, 'campaignIdList' : JSON.stringify(this.selectedCampaignList.map(item => item.id))
			, 'financeId' : null
			, 'totalLoan' : 0
			, 'interestRate' : 0
			, 'duration' : 0
		};

		console.log('inputMap ::: ' + JSON.stringify(inputMap));
		createPreQuote({'inputMap' : inputMap}).then(res => {
			console.log('res ::: ' + JSON.stringify(res))
			const dupType = res['dupType'];
			const accountId = res['accountId'];

			if(dupType === 'error') {
				showToast("Error.", "관리자에게 문의.", "error");
				return;
			}

			// 다른 SA가 소유한 계정 -> 승인 프로세스
			if (dupType === 'otherAcc') {
				// 변경 확인 문구
				LightningConfirm.open({
					message: "담당 매니저에게 승인 요청을 보내겠습니까?",
					// variant: "headerless",
					label: '이미 존재하는 계정 입니다.' // 모달 제목
				}).then(res => {
					if (res) {
						const inputMap = {
							'accountId' : accountId
							, 'leadId' : checkedLead[0]['Id']
						}
						this.isLoading = true;
						callApprovalProcess({'inputMap' : inputMap}).then(res => {
							console.log('res ::: ' + JSON.stringify(res));
							const isSuccess = res['isSuccess'];
							const value = res['value'];
							if(isSuccess) {
								showToast("승인프로세스 요청 성공", value, "success");
							} else {
								showToast("승인프로세스 요청 실패", value, "warning");
							}
						}).catch(err => {
							console.log('err ::: ' + JSON.stringify(err))
						}).finally(() => {
							this.isLoading = false;
							this.isConvertModal = false;
						})
					}
				});
			} else {
				showToast("Success", "견적이 생성 되었습니다.", "success");
				defaultNavigation(this, "Quote", '', res['value']);
			}
		}).catch(err => {
			console.log("err :: ", err);
		}).finally(() => {
			this.isLoading = false;
		});

		// 화면 전환이 없어진다면
		// this.closeModal({ target: { name: 'ConvertOppty' } });
	}

	// 화면 전환
	redirectHandler() {
		navItemPageNavigation(this,'Lead_Acquisition');
	}

	// 모달 열기
	openModal(e) {
		const targetName = e.target.name;

		const checkedLead = this.filteredLeadList
			.filter(lead => lead.checked)
			.map(({checked, url, ...lead}) => lead);

		if (checkedLead.length === 0) {
			const target = (targetName === "CreateTask") ? 'Task 생성' : '견적 생성';
			showToast(target + " Error", "선택한 리드가 없습니다.", "warning");
			return;
		}

		this.checkedLead = checkedLead;
		if(targetName === "CreateTask") { this.isTaskModal = true; }
		if(targetName === "ConvertOppty") {
			this.isConvertModal = true;
			requestAnimationFrame(() => {
				const convertModalEl = this.template.querySelector("c-product-campaign-table");
				convertModalEl.getProductByLead(this.checkedLead);
			})
		}

	}

	// 모달 닫기
	closeModal(e) {
		if(e.target.name === "CreateTask") { this.isTaskModal = false; }
		if(e.target.name === "ConvertOppty") {
			this.isConvertModal = false;
			this.cleanModal('convert');
		}
	}

	// task 생성
	createTask() {
		if(this.taskDescriptionValue === '') {
			showToast("Error", "내용을 입력하세요.", "warning");
			return;
		}

		saveTask({leadId : this.checkedRecordId, Subject : this.taskSubjectValue, description : this.taskDescriptionValue}).then(res => {
			showToast("Success", "Task가 생성되었습니다.", "success");
			this.getTaskList(this.checkedRecordId);
			this.closeModal({ target: { name: 'CreateTask' } });
			this.cleanModal('task');

			// 리드 목록 초기화
			this.getLeadList();

		}).catch(err => {
			console.log('createTask err ::: ' + err)
		})
	}

	// task subject 값 받기
	handleTaskSubjectChange(e) {
		this.taskSubjectValue = e.detail.value;
	}

	// task description 값 받기
	handleTaskDescriptionChange(e) {
		this.taskDescriptionValue = e.target.value;
	}

	// 선택한 리드 값 변경 or 초기화
	changeCheckedLead(leadId) {
		this.checkedRecordId = leadId;
		this.cleanModal('task');
	}

	// 모달 내부 값 초기화
	cleanModal(obj) {
		if(obj === "task") {
			this.taskDescriptionValue = '';
			this.taskSubjectValue = taskSubjectDefualtValue;
		} else if(obj === "convert") {
			this.selectedProductId = '';
			this.selectedCampaignId = '';
			this.selectedCampaignList = [];
		}
	}

	// productCampaignTable에서 이벤트 받기
	handleRowSelect(e) {
		if (e.detail.type === "product") {
			this.selectedProductId = e.detail.id;
			this.selectedCampaignId = '';
			this.selectedCampaignList = [];
		}
		if (e.detail.type === "campaign") {
			this.selectedCampaignId = e.detail.id;
			this.selectedCampaignList = e.detail.selectedRow;
		}
	}

	getProductIdByChild(e) {
		this.selectedProductId = e.detail.productId;
		this.selectedCampaignId = '';
		this.selectedCampaignList = [];
	}
}