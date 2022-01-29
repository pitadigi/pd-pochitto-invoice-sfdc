import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

import getPostalRequest from '@salesforce/apex/pdPIPostalRequest.getPostalRequest';
import registPostalRequest from '@salesforce/apex/pdPIPostalRequest.registPostalRequest';

const columns = [
  {
    label: '完了',
    fieldName: 'Completed__c',
    fixedWidth: 120,
    type: 'button',
    typeAttributes: { label: '解除', name: 'uncompleted', title: '郵送依頼完了を解除する', variant: 'destructive', iconName: 'utility:check',  class: 'slds-var-m-left_x-small' },
    cellAttributes: { alignment: 'center' },
    hideLabel: true,
    iconName: 'utility:check',
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
  postalRequests;
  @wire(getPostalRequest, { completed: false }) wiredPostalRequests(data) {
    this.postalRequests = data;
    this.setIssueCount();
  }
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

    if (this.postalRequests?.data?.length) {
      result = this.postalRequests.data.length;
    }

    return result.toString();
  }

  /**
   * 完了しているかを返す
   */
  get isCompleted() {
    let result = false;

    if (!this.postalRequests?.data?.length) {
      result = true;
    }

    return result;
  }

  /**
   * 発行数を設定する
   */
  setIssueCount() {
    if (!this.postalRequests?.data) {
      return;
    }

    this.issueCount = {};
    for (let i = 0; i < this.postalRequests.data.length; i++) {
      const pr = this.postalRequests.data[i];
      if (pr.IssueCount__c) {
        this.issueCount[pr.Id] = pr.IssueCount__c;
      }
    }
  }

  /**
   * 完了
   */
  handleClickCompleted(event) {
    const target = this.postalRequests.data.find(pr => pr.Id === event.target.value);
    if (target) {
      if (this.issueCount[target.Id] === null || this.issueCount[target.Id] === undefined) {
        this.error('発送数が入力されていません');
      } else if (this.issueCount[target.Id] !== target.PostalRequestCount__c) {
        this.error('郵送依頼数と発送数が一致していません');
      } else {
        this.regist(target.Id, this.issueCount[target.Id], true);
      }
    }
  }

  /**
   * 発送数が変更されたら値を設定する
   * @param {*} event 
   */
  handleChangeIssueCount(event) {
    const target = this.postalRequests.data.find(pr => pr.Id === event.target.name);
    if (target) {
      this.issueCount[event.target.name] = Number(event.target.value);
    }
  }

  /**
   * 完了を解除する
   * @param {*} event 
   */
  handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;

    if (actionName === 'uncompleted') {
      this.regist(row.Id, row.IssueCount__c, false);
    }
  }

  /**
   * 郵送依頼を登録する
   */
  regist(id, issueCount, completed) {
    registPostalRequest({
      id: id,
      issueCount: issueCount,
      completed: completed,
    })
    .then(async () => {
      await refreshApex(this.postalRequests);
      await refreshApex(this.postalRequestsCompleted);
      this.success(`郵送依頼を${completed ? '完了' : '解除'}しました`);
    })
    .catch((e) => {
      this.error('郵送依頼を登録できません', e);
    });
  }

  /**
   * エラーメッセージを表示する
   */
  error(message, e = {}) {
    const event = new ShowToastEvent({
        title: 'エラー',
        variant: 'error',
        message: message,
        messageData: e,
    });
    this.dispatchEvent(event);
  }

  /**
   * 成功メッセージを表示する
   */
   success(message) {
    const event = new ShowToastEvent({
        title: '完了',
        variant: 'success',
        message: message,
    });
    this.dispatchEvent(event);
  }
}
