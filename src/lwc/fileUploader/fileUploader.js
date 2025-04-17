import { LightningElement, api, track, wire } from "lwc";
// import fileNameUpdate from "@salesforce/apex/OpptyFileUploaderController.fileNameUpdate";
import getCheckStatus from "@salesforce/apex/OpptyFileUploaderController.getCheckStatus";
import getInit from "@salesforce/apex/OpptyFileUploaderController.getInit";
import checkFile from "@salesforce/apex/OpptyFileUploaderController.checkFile";
import doRollback from "@salesforce/apex/OpptyFileUploaderController.doRollback";
import initFileList from "@salesforce/apex/OpptyFileUploaderController.initFileList";
import updateFileName from "@salesforce/apex/OpptyFileUploaderController.updateFileName";
import updateIsCheck from "@salesforce/apex/OpptyFileUploaderController.updateIsCheck";
import { CloseActionScreenEvent } from "lightning/actions";
import { recordNavigation, showToast } from "c/commonUtil";
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import formFactorPropertyName from "@salesforce/client/formFactor";
import { loadStyle } from "lightning/platformResourceLoader";
import fileStyle from "@salesforce/resourceUrl/fileStyle";

export default class FileUploader extends NavigationMixin(LightningElement) {

	@api recordId;
	file1Details = null;
	file2Details = null;
	@track file3Details = [];
	@track files = [];
	@track listFile = [];
	@track isVATApproved = "";
	username;
	newFiles;
	sectionName;
	isLoading = false;
	isJumin;
	isBus;
	isVAT;
	fileSize = 0;
	fileIndex = 1; // 부가세 후취 파일 인덱스 번호
	acceptedFormats = [".jpg",".jpeg",".png", ".pdf", ".heic"];
	@track storeFileList = [];

	originalCheckValues = {};

	@track deleteFileList = [];
	@track listUploadedFiles = [];

	get isVATFalse() {
		return this.isVATApproved !== "승인됨";
	}

	connectedCallback() {
		loadStyle(this, fileStyle);

		const isReloaded = sessionStorage.getItem("reloaded");
		if (isReloaded) {
			// 새로고침된 경우만 조건문 실행
			sessionStorage.removeItem("reloaded"); // 한 번만 실행
		}
		// 새로고침 플래그 설정
		window.addEventListener("beforeunload", () => {
			sessionStorage.setItem("reloaded", "true");
			// this.refreshCancel();
		});
	}

	@wire(CurrentPageReference)
	getPageReference(pageRef) {
		if (pageRef && pageRef.state) {
			if (formFactorPropertyName === "Large") {
				this.recordId = pageRef.state.recordId;
			} else {
				// alert('12');
				this.recordId = pageRef.state?.c__recordId;
			}
			this.accHandleName();
			this.fetchOpportunityData();
		}
	}

	fetchOpportunityData() {
		getCheckStatus({ recordId: this.recordId }).then(res => {
			if (res) {
				this.isVATApproved = res.VATDefermentStatus__c;
				this.originalCheckValues = {
					IsJumin__c: res.IsJumin__c,
					IsBusiness__c: res.IsBusiness__c,
					IsVAT__c: res.IsVAT__c
				};
			}
		}).catch(err => {
			console.log("err ::: ", JSON.stringify(err));
		});
	}

	accHandleName() {
		console.log("this.recordId :::", this.recordId);
		getInit({ recordId: this.recordId }).then(res => {
			this.username = res.userName;

		}).catch(err => {
			console.log("err :: ", err);
		});
	}

	async handleOnUploadFinished(e) {

		this.sectionName = e.target.dataset.name;

		const files = e.detail.files;
		const fileIds = files.map(file => file.contentVersionId);
		this.listUploadedFiles = await initFileList({ cvList: fileIds });
		const res = await checkFile({ recordId: this.recordId, sectionName: this.sectionName, cvList: fileIds });

		this.isJumin = res["주민등록증"] || false;
		this.isBus = res["사업자등록증"] || false;
		this.isVAT = res["부가세후취"] || false;

		if (this.sectionName === "주민등록증" && this.isJumin) {
			showToast("주민등록증 파일이 이미 존재합니다.", "기존 파일을 삭제 후 업로드하세요.", "warning");
			this.listUploadedFiles.forEach(el => {
				this.deleteFileList.push(el.ContentDocumentId);
			});

			if (this.deleteFileList.length > 0) {
				this.doRollbackData(this.deleteFileList);
			}

			return;

		} else if (this.sectionName === "사업자등록증" && this.isBus) {
			showToast("사업자등록증 파일이 이미 존재합니다.", "기존 파일을 삭제 후 업로드하세요.", "warning");
			this.listUploadedFiles.forEach(el => {
				this.deleteFileList.push(el.ContentDocumentId);
			});

			if (this.deleteFileList.length > 0) {
				this.doRollbackData(this.deleteFileList);
			}

			return;

		} else if (this.sectionName === "부가세후취" && this.file3Details.length + this.listUploadedFiles.length < 6) {
			showToast("Warning", "부가세후취 파일은 6개 이상부터 업로드 가능합니다.", "warning");
		}

		this.storeFileList = [...this.storeFileList, ...this.listUploadedFiles];

		const fileData = {
			title: files[0].name,
			ContentDocumentId: files[0].documentId,
			key: files[0].documentId || `temp-0`
		};

		if (this.sectionName === "주민등록증") {
			this.file1Details = fileData;
			this.originalCheckValues.IsJumin__c = true;
		} else if (this.sectionName === "사업자등록증") {
			this.file2Details = fileData;
			this.originalCheckValues.IsBusiness__c = true;
		} else {
			this.originalCheckValues.IsVAT__c = true;
			this.file3Details.push(
				...files.map((file, index) => ({
					title: file.name,
					ContentDocumentId: file.documentId,
					key: file.documentId || `temp-${index}`
				}))
			);
		}

		try {
			this.isLoading = true;
			await updateFileName({
				fileIds: fileIds,
				sectionName: this.sectionName,
				username: this.username,
				fileIndex: this.fileIndex
			}).then(res => {
				console.log("updateFileName res :: ", res);
				this.isLoading = false;
			}).catch(err => {
				console.log("err :: ", err);
			});

			this.fileIndex = this.file3Details.length + 1;

		} catch (error) {
			console.error("파일 이름 변경 오류:", error);
		}

		if (this.deleteFileList.length > 0) {
			this.doRollbackData(this.deleteFileList);
			return;
		}
	}

	doRollbackData(listId) {
		doRollback({ setSaveId: listId }).then(res => {
			if (res === "success") {
				this.deleteFileList = [];
			}
		}).catch(err => {
			console.log("err ::: ", err);
		});
	}

	refreshCancel(e) {

		this.isLoading = true;
		const storeIdList = [];

		this.storeFileList.forEach(el => {
			storeIdList.push(el.ContentDocumentId);
		});

		if (this.storeFileList.length > 0) {
			this.doRollbackData(storeIdList);
		} else {
			console.log("여기 찍혀??");
		}

		this.isLoading = false;

		this.dispatchEvent(new CloseActionScreenEvent());
		this.mobileReturnPage();

	}

	handleCancel(e) {
		this.refreshCancel();
	}

	handleSave() {
		if (this.file3Details.length != 0 && this.file3Details.length < 6) {
			showToast("Warning", "부가세후취 파일은 6개 이상부터 저장 가능합니다.", "warning");
			return;
		}

		updateIsCheck({ opportunityId: this.recordId, opportunityFieldMap: this.originalCheckValues }).then(res => {
			console.log("res ::: ", res);
		}).catch(err => {
			console.log("err ::: ", err);
		});

		this.dispatchEvent(new CloseActionScreenEvent());

		this.mobileReturnPage();

		setTimeout(() => {
			window.location.reload();   // 새로고침
		}, 1500);
	}

	handleRemove(e) {
		const name = e.target.dataset.name;
		const key = e.target.dataset.key;
		if (name === "vat") {
			const removedFile = this.file3Details.find(el => el.key === key);

			if (removedFile) {
				this.deleteFileList.push(removedFile.ContentDocumentId);
				this.file3Details = this.file3Details.filter(el => el.key !== key);
			}
		} else {
			// this.files = this.files.filter(el => el.key !== key);
			let removedFile = null;

			if (name === "regNum") {
				removedFile = this.file1Details;
				this.deleteFileList.push(removedFile.ContentDocumentId);
				this.file1Details = null;
			} else if (name === "bizNum") {
				removedFile = this.file2Details;
				this.deleteFileList.push(removedFile.ContentDocumentId);
				this.file2Details = null;
			}

		}

		if (this.deleteFileList.length > 0) {
			this.doRollbackData(this.deleteFileList);
		}
	}

	mobileReturnPage() {
		if (formFactorPropertyName === "Small") {
			recordNavigation(this, "Opportunity", this.recordId);
		}
	}

}