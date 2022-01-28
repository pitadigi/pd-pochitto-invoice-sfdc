import { LightningElement, wire } from 'lwc';
import getPostalRequest from '@salesforce/apex/pdPIPostalRequest.getPostalRequest';

export default class PdPIPostalRequest extends LightningElement {
  @wire(getPostalRequest, { completed: false }) postalRequests;
  @wire(getPostalRequest, { completed: true }) postalRequestsCompleted;

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
}
