import { LightningElement, wire } from 'lwc';
import getPostalRequest from '@salesforce/apex/pdPIPostalRequest.getPostalRequest';

const columns = [
  {
    label: '完了',
    fieldName: 'Completed__c',
    fixedWidth: 120,
    type: 'button',
    typeAttributes: { label: '解除', title: '郵送依頼完了を解除する', variant: 'destructive', iconName: 'utility:check',  class: 'slds-var-m-left_x-small' },
    cellAttributes: { alignment: 'center' },
  },
  {
    label: '郵送依頼日',
    fieldName: 'PostalRequestDate__c',
  },
  {
    label: '郵送依頼数',
    fieldName: 'PostalRequestCount__c',
  },
  {
    label: '発送数',
    fieldName: 'IssueCount__c',
  },
];

export default class PdPIPostalRequest extends LightningElement {
  @wire(getPostalRequest, { completed: false }) postalRequests;
  @wire(getPostalRequest, { completed: true }) postalRequestsCompleted;

  /**
   * 完了郵送依頼データテーブルカラム定義
   */
  columns = columns;

  /**
   * 変更された発送数
   * Idと入力された発送数のペアで格納
   */
  issueCount = {};

  /**
   * 郵送依頼数を返す
   */
  get requestCount() {
    let result = 0;

    if (this.postalRequests.data?.length) {
      result = this.postalRequests.data.length;
    }

    return result.toString();
  }

  /**
   * 完了しているかを返す
   */
  get isCompleted() {
    let result = false;

    if (!this.postalRequests.data?.length) {
      result = true;
    }

    return result;
  }

  /**
   * 完了
   */
  handleClick(event) {
    const target = this.postalRequests.data.find(pr => pr.Id === event.target.value);
    if (target) {
      console.log(target);
    }
  }

  /**
   * 発送数が変更されたら値を設定する
   * @param {*} event 
   */
  handleChange(event) {
    const target = this.postalRequests.data.find(pr => pr.Id === event.target.name);
    if (target) {
      console.log(target);
      this.issueCount[event.target.name] = event.target.value;
      console.log(this.issueCount);
    }
  }
}
