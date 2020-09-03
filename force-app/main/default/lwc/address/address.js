import { LightningElement, api, wire, track } from 'lwc';
import getConfigRecord from '@salesforce/apex/AddressController.getfieldConfig';
import addressNotFoundText from '@salesforce/label/c.Address_AddressNotFoundText';
import findAddressLinkLabel from '@salesforce/label/c.Address_FindAddressLinkLabel';
import clearLinkLabel from '@salesforce/label/c.Address_ClearLinkLabel';

export default class Address extends LightningElement {
    @api recordId;
    @api objectApiName;

    @api configRecordName = '';
    @track configRecord;
    @track addressLabel;
    @track linkLabel = { addressNotFoundText, findAddressLinkLabel, clearLinkLabel };
    @track isAddressNotFound = false;
    @track toastMessage = '';
    @track toastVariant = 'success';
    @track toastAutoCloseTime = '3000';


    @wire(getConfigRecord, { recordName: '$configRecordName', obejctName: '$objectApiName' })
    wiredContacts({ error, data }) {
        if (data) {
            console.log('===RecordId===' + this.recordId);
            console.log(JSON.stringify(data));
            this.configRecord = data;
            console.log(this.configRecord);
            this.configRecordName = this.configRecord.Label;
            console.log('===RecordId ===' + this.configRecordName);
            this.addressLabel = this.configRecord.Address_Label__c;
        } else if (error) {
            console.log('Failed to retrieve configuration details');
            console.log(error);
        }
    }

    /**
     * @description This method is responsible to set isAddressNotFound flag 
     */
    addressNotFoundHandler() {
        this.isAddressNotFound = true;
    }

    /**
     * @description This method is responsible to reset isAddressNotFound flag
     */
    rerenderFindAddressComponentHandler() {
        this.isAddressNotFound = false;
    }
    /**
     *  @description To clear all the input field 
     */
    clearText() {
        this.template.querySelector('c-find-address').handleClearText();
    }

    clearFormTextFields() {
        this.template.querySelector('c-address-form').resetInputFields();
    }

    /**
     * @description show custom toast message as this component is placed on visualforce page 
     */
    showCustomToastMessage(event) {
        this.toastMessage = event.detail.message;
        this.toastVariant = event.detail.variant;
        //Here we are calling  child component method
        this.template.querySelector('c-toast').showCustomNotice();
    }

    @api
    getAddressDetails(){
        if(this.isAddressNotFound == true){
            return this.template.querySelector('c-address-form').getAddressDetails();
        } else {
            return this.template.querySelector('c-find-address').getAddressDetails();
        }
    }
}