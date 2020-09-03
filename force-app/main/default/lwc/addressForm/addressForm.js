/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable vars-on-top */
/* eslint-disable no-console */
import { LightningElement, track, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getExistingAddress from "@salesforce/apex/AddressController.getExistingAddress";
import saveRecord from "@salesforce/apex/AddressController.saveRecord";
import checkFieldVisiblity from "@salesforce/apex/AddressController.checkFieldVisiblity";
import getCountries from "@salesforce/apex/CountryStatePicklistUtility.getCountryList";

export default class AddressForm extends NavigationMixin(LightningElement) {
    @api configRecord;
    @api configRecordName;

    @api recordId;

    @track showLoader = false;
    @track falseFlag = false;
    @track showLoader = false;
    @track error;
    @track stateOptions;
    @track isCountryPicklistEnabled = false;
    @track showInputCountry = false;
    @track hideCountry = false;
    @track selectedStreet = null;
    @track selectedCity = null;
    @track selectedPostcode = null;
    @track selectedState = null;
    @track selectedCountry = "Australia";
    @track countries = [];
    @track states = [];
    countryList = [];

    @track validationErrorMessage = {
        street: "Field is required",
        city: "Field is required",
        postcode: "Field is required",
        state: "Field is required",
        country: ""
    };
    @track isFieldInValid = {
        street: false,
        city: false,
        postcode: false,
        state: false
    };
    @track isValid;
    @track fieldVisiblityConfig;

    /**
     * @description Get existing address from record and populate it on input fields
     * */
    @wire(getExistingAddress, {
        recordName: "$configRecordName",
        recordId: "$recordId"
    })
    existingAddress({ error, data }) {
        if (data) {

            if (this.configRecord.City_Field__c === this.configRecord.Street_Field__c) {
                this.selectedStreet = data.street;
                this.selectedCity = null;
                //this.selectedPostcode = null;
                this.selectedState = '';
                this.selectedCountry = null;
                this.setCountry(this.selectedState);
                this.selectedCountry = 'Australia';
                this.setStateOptions();
                this.initializeCountryOptions();
                return;
            }
            console.log('Existing address details: ' + JSON.stringify(data));
            this.selectedStreet = data.street !== undefined ? data.street : null;
            this.selectedCity =
                data.city !== undefined ? data.city.toUpperCase() : null;
            this.selectedPostcode =
                data.postcode !== undefined ? data.postcode : null;
            this.selectedState = data.state !== undefined ? data.state : null;
            this.selectedCountry =
                (data.country !== undefined ? data.country : "Australia");
            this.setCountry(this.selectedState);
            this.setStateOptions();

            if (data.country !== "Australia" || data.state === this.configRecord.State_Code_Mapping__r.Other__c) {
                //this.isCountryPicklistEnabled = true; 
                this.selectedState = this.configRecord.State_Code_Mapping__r.Other__c;
            }
        } else if (error) {
            this.error = error;
            console.log(" getExistingAddress Error :>");
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
    }

    setStateOptions() {
        this.stateOptions = [
            { key: this.configRecord.State_Code_Mapping__r.ACT__c, value: this.configRecord.State_Code_Mapping__r.ACT__c },
            { key: this.configRecord.State_Code_Mapping__r.NSW__c, value: this.configRecord.State_Code_Mapping__r.NSW__c },
            { key: this.configRecord.State_Code_Mapping__r.NT__c, value: this.configRecord.State_Code_Mapping__r.NT__c },
            { key: this.configRecord.State_Code_Mapping__r.QLD__c, value: this.configRecord.State_Code_Mapping__r.QLD__c },
            { key: this.configRecord.State_Code_Mapping__r.SA__c, value: this.configRecord.State_Code_Mapping__r.SA__c },
            { key: this.configRecord.State_Code_Mapping__r.TAS__c, value: this.configRecord.State_Code_Mapping__r.TAS__c },
            { key: this.configRecord.State_Code_Mapping__r.VIC__c, value: this.configRecord.State_Code_Mapping__r.VIC__c },
            { key: this.configRecord.State_Code_Mapping__r.WA__c, value: this.configRecord.State_Code_Mapping__r.WA__c },
            { key: this.configRecord.State_Code_Mapping__r.Other__c, value: this.configRecord.State_Code_Mapping__r.Other__c },
        ];
    }

    /**
     * @description To get the list of contries from
     */
    @wire(getCountries)
    wiredCountries({ error, data }) {
        if (data) {
            console.log("country data : ");
            this.countryList = data;
            this.initializeCountryOptions();
            this.error = undefined;
        } else if (error) {
            this.error = error;
        }
    }

    initializeCountryOptions() {
            this.countries = [];
            this.countries.push({ selected: '', value: '', label: this.configRecord.Placeholder_Text_Country__c });
            for (var r in this.countryList) {
                let countrySelected = '';
                if (this.countryList[r] === this.selectedCountry) {
                    countrySelected = 'selected';
                }
                this.countries.push({ selected: countrySelected, value: this.countryList[r], label: this.countryList[r] });
            }
            console.log(JSON.stringify(this.countries));

        }
        /**
         * @description - renderedCallback
         */
    renderedCallback() {
        /*eslint-disable-next-line*/
        console.log("this.fieldVisiblityConfig---->");
        console.log(JSON.stringify(this.fieldVisiblityConfig));
        if (
            this.fieldVisiblityConfig &&
            this.fieldVisiblityConfig.isReadOnly === true
        ) {
            //disable input elements
            var inputElement = this.template.querySelectorAll("input");
            if (inputElement) {
                for (var i = 0; i < inputElement.length; i++) {
                    if (inputElement[i]) {
                        inputElement[i].setAttribute("disabled", true);
                    }
                }
            }

            //disable select elements
            var selectElement = this.template.querySelectorAll("select");
            if (selectElement) {
                for (var i = 0; i < selectElement.length; i++) {
                    if (selectElement[i]) {
                        selectElement[i].setAttribute("disabled", true);
                    }
                }
            }
        }

        var optionList = this.template.querySelectorAll("option");
        for (var i = 0; i < optionList.length; i++) {
            if (optionList[i].value === this.selectedState) {
                optionList[i].selected = true;
            }
        }
    }

    @wire(checkFieldVisiblity, { recordName: "$configRecordName" })
    fieldVisiblity({ data, error }) {
        if (data) {
            this.fieldVisiblityConfig = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.fieldVisiblityConfig = undefined;
        }
    }

    /**
     * @description : handle input change
     */
    handleInputChange(event) {
        var elementId = event.target.id;
        console.log("---ElementId--" + elementId);
        var value = event.target.value;
        console.log("---value--" + value);

        if (elementId.includes("inputStreet")) {
            this.selectedStreet = value;
        }
        if (elementId.includes("inputCity")) {
            this.selectedCity = value.toUpperCase();
        }
        if (elementId.includes("inputPostcode")) {
            this.selectedPostcode = value;
        }
        if (elementId.includes("inputStandardState")) {
            this.selectedState = value;
        }
        if (elementId.includes("inputState")) {
            this.setCountry(value);
        }
        if (
            elementId.includes("inputCountry") ||
            elementId.includes("inputCountryPicklist")
        ) {
            this.selectedCountry = value;
            this.states = [];
        }
        this.validateFields();
        this.initializeCountryOptions();
    }

    setCountry(value) {
        value = value === null ? "" : value;
        this.hideCountry = false;
        this.showInputCountry = false;
        this.isCountryPicklistEnabled = false;

        if (this.configRecord.Use_Country_State_Picklist__c === true &&
            (value === this.configRecord.State_Code_Mapping__r.Other__c || value === "")) {
            console.log('State selected as ' + value + ' & country picklist enabled');
            this.selectedState = value;
            this.isCountryPicklistEnabled = true;
        } else if (this.configRecord.Use_Country_State_Picklist__c === true &&
            value !== this.configRecord.State_Code_Mapping__r.Other__c &&
            value !== "") {
            console.log('State selected as ' + value + ' & country picklist disabled');
            this.selectedState = value;
            this.hideCountry = true;
            this.selectedCountry = "Australia";
        } else if (this.configRecord.Use_Country_State_Picklist__c === false &&
            (value === this.configRecord.State_Code_Mapping__r.Other__c || value === "")) {
            console.log('State selected as ' + value + ' & country input enabled');
            this.showInputCountry = true;
            this.selectedState = value;
            this.isCountryPicklistEnabled = false;
        } else if (this.configRecord.Use_Country_State_Picklist__c === false &&
            value !== this.configRecord.State_Code_Mapping__r.Other__c && value !== "") {
            console.log('State selected as ' + value + ' & country field hidden');
            this.selectedCountry = "Australia";
            this.selectedState = value;
            this.hideCountry = true;
            /**/
        }
    }

    /**
     * @description : handle save operation
     */
    handleSave() {
        this.validateFields();
        if (this.isValid == true) {
            //show spinner
            this.showLoader = true;
            console.log("In saveRecord method ");

            console.log("this.selectedStreet : " + this.selectedStreet);
            console.log("this.selectedStselectedCityreet : " + this.selectedCity);
            console.log("this.selectedPostcode : " + this.selectedPostcode);
            console.log("this.selectedState : " + this.selectedState);
            console.log("this.selectedCountry : " + this.selectedCountry);

            saveRecord({
                    recordId: this.recordId,
                    configRecord: this.configRecord,
                    selectedStreet: this.selectedStreet,
                    selectedCity: this.selectedCity,
                    selectedPostcode: this.selectedPostcode,
                    selectedState: this.selectedState,
                    selectedCountry: this.selectedCountry,
                    isValidAddress: false
                })
                .then(result => {
                    this.error = undefined;
                    //Hide Spinner
                    this.showLoader = false;
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
                    //Hide Spinner
                    this.showLoader = false;
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
    }

    /**
     * @description : validate fields
     */
    validateFields() {
        this.isValid = true;
        this.resetValidationFlags();
        console.log("==this.selectedCity==" + this.selectedCity);
        if (
            this.configRecord.Is_Street_Required__c == true &&
            (this.selectedStreet === "" || this.selectedStreet === null)
        ) {
            this.isFieldInValid.street = true;
            this.isValid = false;
        }

        if (
            this.configRecord.Is_City_Required__c == true &&
            (this.selectedCity === "" || this.selectedCity === null)
        ) {
            this.isFieldInValid.city = true;
            this.isValid = false;
        }
        if (
            this.configRecord.Is_State_Required__c == true &&
            (this.selectedState === "" ||
                this.selectedState === this.configRecord.Placeholder_Text_State__c ||
                this.selectedState === null)
        ) {
            this.isFieldInValid.state = true;
            this.isValid = false;
        }
        if (
            this.configRecord.Is_Postcode_Required__c == true &&
            (this.selectedPostcode === "" || this.selectedPostcode === null)
        ) {
            this.isFieldInValid.postcode = true;
            this.isValid = false;
        }
        /*eslint-disable-next-line*/
        console.log("this.selectedPostcode---->" + this.selectedPostcode);
        //Postcode can only contain alphanumeric characters
        if (!new RegExp("^[0-9A-z ]*$").test(this.selectedPostcode)) {
            this.isFieldInValid.postcode = true;
            this.isValid = false;
            this.validationErrorMessage.postcode =
                "Postcode can only contain alphanumeric characters";
        }
        console.log(
            "this.selectedState : " +
            this.selectedState +
            " this.selectedCountry : " +
            this.selectedCountry
        );
        //for state outside Australia country should not be Australia
        if (
            this.selectedState === this.configRecord.State_Code_Mapping__r.Other__c &&
            this.selectedCountry === "Australia"
        ) {
            //this.selectedState = null;
            this.isFieldInValid.country = true;
            this.isValid = false;
            this.validationErrorMessage.country = "Please select different country";
        }
    }

    /**
     * @description : Reset Validation Flags
     */
    resetValidationFlags() {
        this.isFieldInValid.street = false;
        this.isFieldInValid.city = false;
        this.isFieldInValid.state = false;
        this.isFieldInValid.postcode = false;
        this.isFieldInValid.country = false;
    }

    /**
     * @description : Reset All input fields
     */
    @api
    resetInputFields() {
        this.selectedStreet = null;
        this.selectedCity = null;
        this.selectedPostcode = null;
        this.selectedState = null;
        this.selectedCountry = "Australia";
        this.initializeCountryOptions();
    }

    @api
    getAddressDetails() {
        return {
            street: this.selectedStreet,
            city: this.selectedCity,
            state: this.selectedState,
            postcode: this.selectedPostcode,
            country: this.selectedCountry,
            isValid: this.isValid
        };
    }
}