import { LightningElement} from 'lwc';
import EventRegisterAttendee from "c/eventRegisterAttendee";
import EventRegisterEventTalk from "c/eventRegisterEventTalk";
import EventRegisterPreferences from "c/eventRegisterPreferences";
import EventRegisterSummary from "c/eventRegisterSummary";
import {validateEmail} from "c/eventRegisterValidators";

export default class EventRegisterWizardRegistry extends LightningElement {
    _pageRegistry = {
    EventRegisterAttendee,
    EventRegisterEventTalk,
    EventRegisterPreferences,
    EventRegisterSummary
  };
  _validatorRegistry = {
    ValidateEmail: validateEmail
  };
}