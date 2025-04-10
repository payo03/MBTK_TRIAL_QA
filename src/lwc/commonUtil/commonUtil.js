/*************************************************************
 * @author : th.kim
 * @date : 2024-11-06
 * @description : LWC 공통 유틸
 * @target : Utility
 ==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-11-06      th.kim          Created
 **************************************************************/

// Library
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import {
	defaultNavigation,
	recordNavigation,
	objectNavigation,
	externalNavigation,
	componentNavigation,
	navItemPageNavigation
} from "./navigationUtil";

// Label
import LightningHost from "@salesforce/label/c.LightningHost";
import VFHost from "@salesforce/label/c.VFHost";

// Static Resource
import JQEURY from "@salesforce/resourceUrl/jQuery";
import CustomTableStyle from "@salesforce/resourceUrl/CustomTableStyle";

/**
 * @author th.kim
 * @description Label 리스트
 * @type {{test: string}}
 */
const labelList = {
	LightningHost,
	VFHost
};

/**
 * @author th.kim
 * @description Static Resource 리스트
 * @type {{sheetJs: string, jquery: string}}
 */
const resourceList = {
	JQEURY,
	CustomTableStyle
};

/**
 * @author th.kim
 * @description ShowToast Util
 * @param title 토스트 제목
 * @param message 토스트 내용
 * @param variant 토스트 스타일 (success, warning, error)
 * @param mode 토스트 메시지 모드 (
 *                              pester - 3초간 유지 닫기 버튼 X
 *                              dismissible - 3초간 유지 닫기 버튼 O
 *                              sticky - 닫기 버튼 누를 때까지 유지
 *                             )
 * @param messageData 메시지에 링크 표시 ex)
 * messageData:[
 *                 'Salesforce',
 *                 {
 *                     url: 'http://www.salesforce.com/',
 *                     label: 'here',
 *                 },
 *             ]
 *
 */
const showToast = (title, message, variant, mode, messageData) => {
	const showToastEvent = new ShowToastEvent({
		title: title,
		message: message,
		variant: variant,
		mode: mode,
		messageData: messageData
	});
	window.dispatchEvent(showToastEvent);
};

/**
 * @author th.kim
 * @description 데이터 테이블에서 해당 필드 기준으로 리스트 정렬하는 함수
 * @param listData 정렬할 데이터 리스트
 * @param fieldName 정렬에 사용될 필드명
 * @param direction 'asc' 또는 'desc' 정렬 방향
 * @returns {*[]}
 */
const sortData = (listData, fieldName, direction) => {
	// 데이터 복사
	console.log("listData:", listData);
	const sortList = [...listData];
	console.log("sortList:", sortList);
	// 정렬 방향 설정 (asc: 1, desc: -1)
	const isReverse = direction === "asc" ? 1 : -1;

	// 데이터 정렬
	sortList.sort((a, b) => {
		const valueA = a[fieldName];
		const valueB = b[fieldName];

		// 숫자 정렬 처리
		if (!isNaN(valueA) && !isNaN(valueB)) {
			return (Number(valueA) - Number(valueB)) * isReverse;
		}

		// 문자열 정렬 처리 (null 값 처리 및 대문자로 변환)
		const strA = (valueA || "").toString().toUpperCase();
		const strB = (valueB || "").toString().toUpperCase();

		if (strA < strB) {
			return -1 * isReverse;
		}
		if (strA > strB) {
			return 1 * isReverse;
		}
		return 0; // 값이 동일한 경우
	});
	console.log("sortList::", sortList);
	return sortList;
};

/**
 * @description 깊은 복사
 * @param data 복사할 데이터
 */
const deepClone = (data) => {
	return JSON.parse(JSON.stringify(data));
};

const getTodayFormatted = () => getFormattedDate(new Date());

/**
 * @description 날짜 데이터 YYYY-MM-DD 형식으로 변환하기
 * @param date new Date() 형식
 */
const getFormattedDate = (date) => {

	// UTC+9 (KST)로 변환
	const offsetDate = new Date(date.getTime() + 9 * 60 * 60 * 1000);

	return offsetDate.toISOString().split("T")[0];
};

/**
 * @description 해당 년, 월의 시작 날짜, 마지막 날짜 가져오기
 * @param year 해당 년도
 * @param month 해당 월
 */
const getMonthStartAndEnd = (year, month) => ({
	startDate: getFormattedDate(new Date(year, month - 1, 1)), // 해당 월의 1일
	endDate: getFormattedDate(new Date(year, month, 0)) // 해당 월의 마지막 날
});

export {
	labelList,
	resourceList,
	showToast,
	sortData,
	defaultNavigation,
	recordNavigation,
	objectNavigation,
	externalNavigation,
	componentNavigation,
	navItemPageNavigation,
	deepClone,
	getTodayFormatted,
	getFormattedDate,
	getMonthStartAndEnd
};