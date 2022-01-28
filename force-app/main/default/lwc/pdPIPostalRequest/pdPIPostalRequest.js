import { LightningElement, wire } from 'lwc';
// import getPostalRequest from '@salesforce/apex/pdPIPostalRequest/getPostalRequest';

export default class PdPIPostalRequest extends LightningElement {
    selected = true;
    unSelected = false;

    /**
     * 完了フラグ
     */
    completed = false;
    
    // @wire(getPostalRequest, , { completed: '$completed' }) postalRequests;
}
