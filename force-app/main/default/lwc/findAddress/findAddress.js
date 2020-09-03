/* eslint-disable no-unreachable */
/* eslint-disable no-else-return */
/* eslint-disable no-console */
/* eslint-disable @lwc/lwc/no-async-operation */
import { LightningElement, api, track, wire } from "lwc";
import getExistingAddress from "@salesforce/apex/AddressController.getExistingAddress";
import notValidatedIcon from "@salesforce/resourceUrl/NotValidatedIcon";
import validatedIcon from "@salesforce/resourceUrl/ValidatedIcon";
import searchInputPlaceHolderText from "@salesforce/label/c.Address_SearchPlaceHolderText";
import findAddress from "@salesforce/apex/FindAddressController.searchAddress";
import getComponents from "@salesforce/apex/FindAddressController.getAddressComponent";
import isValid from "@salesforce/apex/FindAddressController.isValidAddress";
import saveRecord from "@salesforce/apex/AddressController.saveRecord";

export default class FindAddress extends LightningElement {
    @api configRecord;
    @api configRecordName;
    @api recordId;

    @track address = "";
    @track error;
    @track isProcessing = false;
    @track txtclassname =
        "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click";
    values;
    @track placeHolderText = {
        searchInputPlaceHolderText
    };
    @track imgAltText = "Address is not valid";
    @track selectedStreet = "";
    @track selectedCity = "";
    @track selectedPostcode = "";
    @track selectedState = "";
    @track selectedCountry = "Australia";
    @track isValidAddress = false;
    inputAddressId = '';
    componentInitialized = false;
    ctrlPressed = false;
    initialized = false;
    searchInProgress = false;
    notValidatedIconPath = notValidatedIcon;
    validatedIconPath = validatedIcon;
    formattedAddress = '';

    /**
     * @description Get existing address from record and populate it on input fields
     * */
    @wire(getExistingAddress, {
        recordName: "$configRecordName",
        recordId: "$recordId"
    })
    existingAddress({ error, data }) {
        if (data) {
            console.log(JSON.stringify(data));
            let street = data.street ? data.street + ", " : "";
            let city = data.city ? data.city.toUpperCase() + " " : "";
            let state = data.state ? data.state + " " : "";
            let postcode = data.postcode ? data.postcode + " " : "";
            this.selectedStreet = data.street;
            this.selectedCity = data.city;
            this.selectedState = data.state;
            this.selectedPostcode = data.postcode;

            this.address = street + city + state + postcode;
            /*eslint-disable-next-line*/
            console.log(" this.selectedStreet---->" + this.selectedStreet);
            //remove "," from address at last postion 
            if (this.address.slice(-2) == ', ') {
                this.address = this.address.slice(0, -2);
            }
            if (this.address.slice(-1) == ',') {
                this.address = this.address.slice(0, -1);
            }

            //validate Address only if address present on record
            if (!/^\s*$/.test(this.address)) {
                this.validateAddress();
            }
        } else if (error) {
            this.error = error;
            console.log(" Find Address - get Existing Address Error :>");
            console.log(error);

            this.dispatchEvent(
                new CustomEvent("customtoastevent", {
                    detail: {
                        message: "Please contact admin.  " + JSON.stringify(error),
                        variant: "error"
                    }
                })
            );
        }

        let addresses = [];
        addresses.push({ key: "", value: "" });
        this.values = addresses;
    }

    handleKeyPressOnAddress(event) {
        let keycode = event.keyCode;
        console.log(keycode);
        if (keycode == 40) {
            //down arrow pressed on address list
            let nextElem = event.target.nextElementSibling
            console.log('down arrow pressed ' + nextElem);
            if (nextElem) {
                nextElem.focus();
            } else {
                let liElem = this.template.querySelector('li');
                liElem.focus();
            }
        } else if (keycode == 38) {
            let prevElem = event.target.previousElementSibling
            console.log('up arrow pressed ' + prevElem);
            if (prevElem) {
                prevElem.focus();
            } else {
                this.template.querySelector('input').focus();
            }
        } else if (keycode == 13) {
            event.target.childNodes[0].click();
            this.template.querySelector('input').focus();
            this.template.querySelector('.addressOptions').style = 'display:none';
        }
    }

    onInputChangeHandler(event) {
        //this.address = event.target.value;
        let keycode = event.keyCode;
        console.log('keycode: ' + keycode);
        if(keycode == 9){
            this.template.querySelector('.addressOptions').style = 'display:none';
            return;
        }
        this.selectedStreet = event.target.value;
        this.address = this.selectedStreet;
        console.log('selectedStreet: ' + this.selectedStreet);
        console.log('ctrlPressed: ' + this.ctrlPressed);
        console.log('searchInProgress: ' + this.searchInProgress);
		if(keycode == 17){
            this.ctrlPressed = true;
            return;
        } else if(keycode == 65 && this.ctrlPressed){
            return;
        } else if(keycode == 8 && this.ctrlPressed){
            this.address = '';
            let addresses = [];
            addresses.push({ key: "", value: "" });
            this.values = addresses;
            return;
        }
        if (this.searchInProgress) {
            return;
        }
        this.ctrlPressed = false;
        if (keycode == 40) {
            //down arrow press
            console.log('down arrow pressed');
            let liElem = this.template.querySelector('li');
            console.log(liElem);
            liElem.focus();
            return;
        }
        let addrSearch = event.target.value;

        if (addrSearch.length < 3) {
            let addresses = [];
            addresses.push({ key: "", value: "" });
            this.values = addresses;
            return;
        } else {
            console.log("this.addrSearch---->" + addrSearch);
            //search address using NSW point service
            this.searchAddress(addrSearch);
        }
    }

    /**
     *@description : Validate address
     */
    validateAddress() {
        /*eslint-disable-next-line*/
        console.log("address to validate---->" + this.address);
        isValid({
                address: this.address
            })
            .then(result => {
                /*eslint-disable-next-line*/
                console.log("result---->" + result);
                this.isValidAddress = result;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.isValidAddress = false;
            });
    }

    /**
     * @description : handle save operation
     */
    handleSave() {
        let stateMap = this.configRecord.State_Code_Mapping__r;
        saveRecord({
                recordId: this.recordId,
                configRecord: this.configRecord,
                selectedStreet: this.selectedStreet,
                selectedCity: this.selectedCity,
                selectedPostcode: this.selectedPostcode,
                selectedState: stateMap[this.selectedState + '__c'] == undefined ? this.selectedState : stateMap[this.selectedState + '__c'],
                selectedCountry: this.selectedCountry == "" ? "Australia" : this.selectedCountry,
                isValidAddress: this.isValidAddress
            })
            .then(result => {
                this.error = undefined;
                this.dispatchEvent(
                    new CustomEvent("customtoastevent", {
                        detail: {
                            message: "Record updated successfully",
                            variant: "success"
                        }
                    })
                );
                this.delayTimeout = setTimeout(() => {
                    self.close();
                    location.reload(true);
                }, 2000);
            })
            .catch(error => {
                this.error = error;
                console.log("Error : ");
                console.log(error);
                this.dispatchEvent(
                    new CustomEvent("customtoastevent", {
                        detail: {
                            message: "Please contact admin.  " + error,
                            variant: "error"
                        }
                    })
                );
            });
    }
    /**
     * @description Search address from given address string
     */
    searchAddress(addressStr) {
        this.selectedStreet = addressStr;
        if (this.searchInProgress) {
            return;
        }
        this.searchInProgress = true;
        findAddress({
                searchKey: addressStr
            })
            .then(result => {
                let addresses = [];
                console.log("Address search performed with below results");
                console.log(JSON.stringify(result));
                this.template.querySelector('.addressOptions').style = 'display:block';
                for (let i = 0; i < result.length; i++) {
                    addresses.push({
                        key: result[i].id,
                        value: result[i].address
                    });
                }
                console.log(addresses);
                this.searchInProgress = false;
                this.address = this.template.querySelector('#' + this.inputAddressId).value;
                console.log('address:' + this.address + 'address');
                this.values = addresses;
                
                this.txtclassname =
                    result.length > 0 ?
                    "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open" :
                    "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click";
                
                if(this.address.length > 3 && this.address != addressStr){
                    //redo the search
                    this.searchAddress(this.address);
                }
                console.log('address:' + this.address + 'address');           
            })
            .catch(error => {
                console.log("Failed to perform address search");
                console.log(error);
                this.searchInProgress = false;
            });
    }

    /**
     * @description get Address component
     */
    getAddressComponent(event) {
            var addressId = event.currentTarget.dataset.id;
            this.isProcessing = true;
            console.log("select address id : " + event.currentTarget.dataset.id);
            console.log("select address string : " + event.currentTarget.dataset.name);

            this.txtclassname =
                "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click";

            this.address = event.currentTarget.dataset.name;
            this.selectedStreet = this.address;

            getComponents({
                    addressId: addressId,
                    configRecord: this.configRecord
                })
                .then(result => {
                    console.log("address components retrieved successfully");
                    console.log(JSON.stringify(result));
                    if (result.data) {
                        let street = "";
                        let addressDetails = result.data.addressDetails;
                        this.formattedAddress = addressDetails.formattedAddress;
                        this.formattedAddress = this.formattedAddress.replace(addressDetails.postcode , '');
                        this.formattedAddress = this.formattedAddress.replace(addressDetails.stateTerritory , '');
                        this.formattedAddress = this.formattedAddress.replace(addressDetails.localityName , '');
                        this.formattedAddress = this.formattedAddress.replace(',' , '');
                        this.formattedAddress = this.formattedAddress.trim();

                        console.log('this.configRecord.Street_Field_To_Use__c ' + this.configRecord.Street_Field_To_Use__c);
                        if (this.configRecord.Street_Field_To_Use__c == 'streetType' && addressDetails.streetType)
                            this.formattedAddress = this.formattedAddress.replace(addressDetails.streetTypeDescription , addressDetails.streetType);

                        console.log(this.formattedAddress);
                        
                        this.selectedStreet = this.formattedAddress;
                        this.selectedCity = addressDetails.localityName;
                        this.selectedPostcode = addressDetails.postcode;
                        this.selectedState = addressDetails.stateTerritory;
                        this.selectedCountry = "Australia";
                        this.isValidAddress = true;
                        this.isProcessing = false;
                    }
                })
                .catch(error => {
                    console.log("Failed to retrieve address details");
                    console.log(error);
                });
        }
    /**
     * @description To clear text in input search text
     */
    @api
    handleClearText() {
        this.address = "";
        this.selectedStreet = "";
        this.selectedCity = "";
        this.selectedState = "";
        this.selectedPostcode = "";
        this.selectedCountry = "";
        this.isValidAddress = false;
        this.txtclassname = "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click";
    }

    @api
    getAddressDetails() {
        let stateMap = this.configRecord.State_Code_Mapping__r;
        return {
            street: this.selectedStreet,
            city: this.selectedCity,
            state: stateMap[this.selectedState + '__c'] == undefined ? this.selectedState : stateMap[this.selectedState + '__c'],
            postcode: this.selectedPostcode,
            country: this.selectedCountry,
            isValid: this.isValidAddress
        };
    }

    renderedCallback() {
        if (this.componentInitialized) {
            return;
        }
        this.componentInitialized = true;
        this.inputAddressId = this.template.querySelector('input').id;        
    }
}