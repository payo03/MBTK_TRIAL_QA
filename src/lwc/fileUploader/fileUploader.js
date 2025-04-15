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

	// 테스트
	@api recordId;
	// @wire(CurrentPageReference) pageRef;
	file1Details = null;
	file2Details = null;
	@track file3Details = [];
	// file1Uploaded = false;
	// file2Uploaded = false;
	// file3Uploaded = false;
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
	acceptedFormats = [".jpg", ".png", ".pdf", ".heic"];
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
			console.log("새로고침 이후 조건문 실행됨");
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
				console.log("this.isVATApproved ::: ", this.isVATApproved);
				console.log("res ::: ", JSON.stringify(res));
				this.originalCheckValues = {
					IsJumin__c: res.IsJumin__c,
					IsBusiness__c: res.IsBusiness__c,
					IsVAT__c: res.IsVAT__c
				};
				console.log("originalCheckValues ::: ", JSON.stringify(this.originalCheckValues));
			}
		}).catch(err => {
			console.log("err ::: ", JSON.stringify(err));
		});
	}

	accHandleName() {
		console.log("this.recordId :::", this.recordId);
		getInit({ recordId: this.recordId }).then(res => {
			this.username = res.userName;
			console.log("res ::: ", res);

		}).catch(err => {
			console.log("err :: ", err);
		});
	}

	async handleOnUploadFinished(e) {
		console.log("파일 업로드 시작");

		this.sectionName = e.target.dataset.name;

		const files = e.detail.files;
		const fileIds = files.map(file => file.contentVersionId);
		this.listUploadedFiles = await initFileList({ cvList: fileIds });

		console.log("this.listUploadedFiles:::: ", JSON.stringify(this.listUploadedFiles));

		const res = await checkFile({ recordId: this.recordId, sectionName: this.sectionName, cvList: fileIds });

		console.log("checkFile 결과 ::: ", JSON.stringify(res));

		this.isJumin = res["주민등록증"] || false;
		this.isBus = res["사업자등록증"] || false;
		this.isVAT = res["부가세후취"] || false;

		console.log("this.sectionName ::: ", this.sectionName);
		console.log("this.isJumin ::: ", this.isJumin);
		console.log("this.isBus ::: ", this.isBus);
		console.log("this.isVAT ::: ", this.isVAT);
		console.log("부가 조건 체크:", this.sectionName, this.listUploadedFiles.length);

		if (this.sectionName === "주민등록증" && this.isJumin) {
			console.log("주민");
			showToast("주민등록증 파일이 이미 존재합니다.", "기존 파일을 삭제 후 업로드하세요.", "warning");
			this.listUploadedFiles.forEach(el => {
				this.deleteFileList.push(el.ContentDocumentId);
			});

			if (this.deleteFileList.length > 0) {
				this.doRollbackData(this.deleteFileList);
			}

			return;

		} else if (this.sectionName === "사업자등록증" && this.isBus) {
			console.log("사업");
			showToast("사업자등록증 파일이 이미 존재합니다.", "기존 파일을 삭제 후 업로드하세요.", "warning");
			this.listUploadedFiles.forEach(el => {
				this.deleteFileList.push(el.ContentDocumentId);
			});

			if (this.deleteFileList.length > 0) {
				this.doRollbackData(this.deleteFileList);
			}

			console.log("사업자 deleteFileList ::: ", JSON.stringify(this.deleteFileList));
			console.log("사업자 listUploadedFiles ::: ", JSON.stringify(this.listUploadedFiles));

			return;

		} else if (this.sectionName === "부가세후취" && this.file3Details.length + this.listUploadedFiles.length < 6) {
			console.log("부가");
			showToast("Warning", "부가세후취 파일은 6개 이상부터 업로드 가능합니다.", "warning");
			console.log("list len  ::: ", this.listUploadedFiles.length);
			console.log("file3  ::: ", this.file3Details.length);
			// showToast("Warning", "부가세후취 파일.", "warning");
			// this.listUploadedFiles.forEach(el => {
			//     this.deleteFileList.push(el.ContentDocumentId);
			// });

			// if (this.deleteFileList.length > 0) {
			//     this.doRollbackData(this.deleteFileList);
			// }
			// return;
		}

		this.storeFileList = [...this.storeFileList, ...this.listUploadedFiles];

		const fileData = {
			title: files[0].name,
			ContentDocumentId: files[0].documentId,
			key: files[0].documentId || `temp-0`
		};

		if (this.sectionName === "주민등록증") {
			this.file1Details = fileData;
			console.log("this.file1Details ::: ", JSON.stringify(this.file1Details));
			// await updateIsCheck({ opportunityId: this.recordId, fieldToUpdate: 'IsJumin__c', value: true });
			this.originalCheckValues.IsJumin__c = true;
		} else if (this.sectionName === "사업자등록증") {
			this.file2Details = fileData;
			console.log("this.file2Details ::: ", JSON.stringify(this.file2Details));
			this.originalCheckValues.IsBusiness__c = true;
			// await updateIsCheck({ opportunityId: this.recordId, fieldToUpdate: 'IsBusiness__c', value: true });
		} else {
			// await updateIsCheck({ opportunityId: this.recordId, fieldToUpdate: 'IsVAT__c', value: true });
			this.originalCheckValues.IsVAT__c = true;
			this.file3Details.push(
				...files.map((file, index) => ({
					title: file.name,
					ContentDocumentId: file.documentId,
					key: file.documentId || `temp-${index}`
				}))
			);
			console.log("this.file3Details ::: ", JSON.stringify(this.file3Details));
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
			console.log("updateFileName 실행");

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
			console.log("res :: ", res);
			if (res === "success") {
				this.deleteFileList = [];
			}
		}).catch(err => {
			console.log("err ::: ", err);
		});
	}

	refreshCancel(e) {
		console.log("취소");

		this.isLoading = true;

		console.log("storeFileList ::::", JSON.stringify(this.storeFileList));

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

		console.log("닫기");

		this.dispatchEvent(new CloseActionScreenEvent());
		this.mobileReturnPage();

	}

	handleCancel(e) {
		this.refreshCancel();
	}

	handleSave() {
		console.log("저장 버튼 클릭");
		if (this.file3Details.length != 0 && this.file3Details.length < 6) {
			showToast("Warning", "부가세후취 파일은 6개 이상부터 저장 가능합니다.", "warning");
			return;
		}

		updateIsCheck({ opportunityId: this.recordId, opportunityFieldMap: this.originalCheckValues }).then(res => {
			console.log("res ::: ", res);
		}).catch(err => {
			console.log("err ::: ", err);
		});

		// if(this.file1Details === null ) {
		//     await updateIsCheck({
		//         opportunityId: this.recordId,
		//         fieldToUpdate: 'IsJumin__c',
		//         value: this.originalCheckValues.IsJumin__c
		//     });
		// }
		// if(this.file2Details === null) {
		//     await updateIsCheck({
		//         opportunityId: this.recordId,
		//         fieldToUpdate: 'IsBusiness__c',
		//         value: this.originalCheckValues.IsBusiness__c
		//     });
		// }
		// if(this.file3Details.length == 0) {
		//     await updateIsCheck({
		//         opportunityId: this.recordId,
		//         fieldToUpdate: 'IsVAT__c',
		//         value: this.originalCheckValues.IsVAT__c
		//     });
		// }

		this.dispatchEvent(new CloseActionScreenEvent());

		this.mobileReturnPage();

		setTimeout(() => {
			window.location.reload();   // 새로고침
		}, 1500);
	}

	handleRemove(e) {
		console.log("handleRemove ");
		const name = e.target.dataset.name;
		const key = e.target.dataset.key;
		console.log("key ::: ", key);
		if (name === "vat") {
			const removedFile = this.file3Details.find(el => el.key === key);
			console.log("removedFile :: ", JSON.stringify(removedFile));

			if (removedFile) {
				this.deleteFileList.push(removedFile.ContentDocumentId);
				console.log("삭제된 파일 ID 목록 ::: ", JSON.stringify(this.deleteFileList));

				this.file3Details = this.file3Details.filter(el => el.key !== key);
				console.log("남은 file3Details ::: ", JSON.stringify(this.file3Details));
			}
		} else {
			// this.files = this.files.filter(el => el.key !== key);
			let removedFile = null;

			if (name === "regNum") {
				removedFile = this.file1Details;
				console.log("removedFile :: ", JSON.stringify(removedFile));
				this.deleteFileList.push(removedFile.ContentDocumentId);
				this.file1Details = null;
				console.log("this.file1Details :: ", JSON.stringify(this.file1Details));
			} else if (name === "bizNum") {
				removedFile = this.file2Details;
				this.deleteFileList.push(removedFile.ContentDocumentId);
				this.file2Details = null;
				console.log("removedFile :: ", JSON.stringify(removedFile));
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