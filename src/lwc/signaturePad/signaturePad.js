/*************************************************************
 * @author : th.kim
 * @date : 2025-02-25
 * @description :
 * @target :
 ==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-02-25      th.kim          Initial Version
 **************************************************************/
import { api, LightningElement, track } from "lwc";

// Library
import formFactorPropertyName from "@salesforce/client/formFactor";
import { CloseActionScreenEvent } from "lightning/actions";

// Controller
import signSave from "@salesforce/apex/SignatureController.signSave";

// Util
import { recordNavigation, showToast } from "c/commonUtil";

export default class SignaturePad extends LightningElement {

	// 그림 데이터 변수
	@api canvasWidth;
	@api canvasHeight;
	@track drawingData = [];
	canvas;
	ctx;
	isDrawing = false;
	prevX = 0;
	currX = 0;
	prevY = 0;
	currY = 0;
	dot_flag = false;

	get signatureLoaded() {
		return this.canvasWidth && this.canvasHeight;
	}

	renderedCallback() {
		if (!this.canvas) {
			// 캔버스 요소를 가져오고 초기화
			this.canvas = this.template.querySelector(".drawing-pad");
			if (this.canvas) {
				const ratio = Math.max(window.devicePixelRatio || 1, 1);
				this.canvas.width = this.canvas.width * ratio;
				this.canvas.height = this.canvas.height * ratio;
				this.ctx = this.canvas.getContext("2d");

				// 모바일 터치 이벤트 리스너 추가
				this.canvas.addEventListener("touchstart", this.handleTouchStart.bind(this), false);
				this.canvas.addEventListener("touchend", this.handleTouchEnd.bind(this), false);
				this.canvas.addEventListener("touchmove", this.handleTouchMove.bind(this), false);
			}
		}
	}

	/**
	 * @description 그림 지우기 함수
	 */
	@api
	doErase() {
		this.drawingData = [];
		this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
	}

	@api
	async doSave(recordId, type) {
		const canvas = this.template.querySelector(".drawing-pad");
		const dataURL = canvas.toDataURL("image/png");
		let result;
		await signSave({
			url: dataURL,
			param: recordId,
			type: type.value
		}).then(res => {
			console.log("res :: ", res);
			// if (formFactorPropertyName === "Large") {
			// 	this.dispatchEvent(new CloseActionScreenEvent());
			// } else {
			// 	recordNavigation(this, "VehicleStock__c", recordId);
			// }
			showToast("서명이 저장되었습니다.", "", "success");
			result = true;
		}).catch(err => {
			console.log("err :: ", err);
			showToast("ERROR", "저장 중 문제가 발생하였습니다.", "warning");
			result = false;
		});
		return result;
	}

	/**
	 * @description 마우스 클릭으로 그리기 시작
	 * @param e onmousedown 이벤트
	 */
	startDrawing(e) {
		this.findXy("down", e);
	}

	/**
	 * @description 마우스 드래그 중 그리기
	 * @param e onmousemove 이벤트
	 */
	draw(e) {
		if (this.isDrawing) {
			this.findXy("move", e);
		}
	}

	/**
	 * @description 마우스 버튼을 놓으면 그리기 종료
	 * @param e onmouseup, onmouseleave, onmouseout 이벤트
	 */
	stopDrawing(e) {
		console.log("stop");
		this.findXy("up", e);
	}

	/**
	 * @description 터치 시작 이벤트 처리
	 * @param e touchstart 이벤트
	 */
	handleTouchStart(e) {
		const touch = e.touches[0];
		const mouseEvent = new MouseEvent("mousedown", {
			clientX: touch.clientX,
			clientY: touch.clientY
		});
		this.canvas.dispatchEvent(mouseEvent);
		e.preventDefault();
	}

	/**
	 * @description 터치 종료 이벤트 처리
	 * @param e handleTouchEnd 이벤트
	 */
	handleTouchEnd(e) {
		const mouseEvent = new MouseEvent("mouseup", {});
		this.canvas.dispatchEvent(mouseEvent);
	}

	/**
	 * @description 터치 이동 이벤트 처리
	 * @param e touchmove 이벤트
	 */
	handleTouchMove(e) {
		const touch = e.touches[0];
		const mouseEvent = new MouseEvent("mousemove", {
			clientX: touch.clientX,
			clientY: touch.clientY
		});
		this.canvas.dispatchEvent(mouseEvent);
		e.preventDefault();
	}

	/**
	 * @description 그림 저장 함수
	 */
	handleClick(e) {
		// const name = e.target.dataset.name;
		// if (name === "erase") {
		// 	this.drawingData = [];
		// 	this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
		// } else if (name === "save") {
		// 	const pad = this.canvas;
		// 	const dataUrl = pad.toDataURL();
		// 	const strDataURI = dataUrl.replace(/^data:image\/(png|jpg);base64,/, "");
		// 	saveSignature({ signatureBody: strDataURI }).then(() => {
		// 		showToast("Saved successfully.", "", "success");
		// 	}).catch(err => {
		// 		console.log("err :: ", err);
		// 		showToast("Error", "", "error");
		// 	});
		// }
	}

	/**
	 * @description 그리기 상태와 좌표를 관리
	 * @param type 이벤트 유형
	 * @param e
	 */
	findXy(type, e) {
		const rect = this.canvas.getBoundingClientRect();
		if (type === "down") {
			// 마우스 버튼 눌렀을 때
			this.prevX = this.currX;
			this.prevY = this.currY;
			this.currX = e.clientX - rect.left;
			this.currY = e.clientY - rect.top;

			this.isDrawing = true;
			this.dot_flag = true;
			if (this.dot_flag) {
				// 시작점 그리기
				this.drawStart();
				this.dot_flag = false;

				// 시작점 데이터 저장
				const startData = {
					type: "start",
					prevX: this.prevX,
					prevY: this.prevY,
					currX: this.currX,
					currY: this.currY
				};
				this.drawingData.push({ startData });
			}
		}
		if (type === "up" || type === "out") {
			// 마우스 버튼 뗐을 때
			const endData = { type: "end" };
			this.drawingData.push({ endData });
			this.isDrawing = false;
		}
		if (type === "move") {
			// 마우스 드래그 할 때
			if (this.isDrawing) {
				this.prevX = this.currX;
				this.prevY = this.currY;
				this.currX = e.clientX - rect.left;
				this.currY = e.clientY - rect.top;
				this.drawLine();

				// draw 데이터 저장
				const drawingData = {
					type: "drawing",
					prevX: this.prevX,
					prevY: this.prevY,
					currX: this.currX,
					currY: this.currY
				};
				this.drawingData.push({ drawingData });
			}
		}
	}

	/**
	 * @description 선 그리기 함수
	 */
	drawLine() {
		this.ctx.beginPath();
		this.ctx.moveTo(this.prevX, this.prevY);
		this.ctx.lineTo(this.currX, this.currY);
		this.ctx.strokeStyle = "black";
		this.ctx.lineWidth = 2;
		this.ctx.stroke();
		this.ctx.closePath();
	}

	/**
	 * @description 시작점 그리기 함수
	 */
	drawStart() {
		this.ctx.beginPath();
		this.ctx.fillStyle = "black";
		this.ctx.fillRect(this.currX, this.currY, 2, 2);
		this.ctx.closePath();
	}

	/**
	 * @description 저장된 데이터 가져와서 그려주기
	 */
	drawFromData() {
		this.drawingData.forEach(data => {
			// 데이터 유형 구분
			const xyData = data.startData ?? data.drawingData ?? data.endData;
			// xy 데이터 가져오기
			const { prevX, prevY, currX, currY } = xyData;
			this.prevX = prevX;
			this.prevY = prevY;
			this.currX = currX;
			this.currY = currY;

			if (data.startData) {
				// 선 시작 지점
				this.drawStart();
			} else if (data.drawingData) {
				// 선 드래그 지점
				this.drawLine();
			} else if (data.endData) {
				// 선 끝 지점
				this.isDrawing = false;
			}
		});
		this.isDrawing = false;
	}
}