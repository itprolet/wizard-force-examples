/**
 * Created by asen on 5.09.25.
 */

import { LightningElement, api } from "lwc";

export default class WizardPage3 extends LightningElement {
  @api wizardId;
  @api title;
  @api page;

  get name() {
    return this.title || "Page 3";
  }

  @api model;

  @api
  processChange(name) {
    console.log("WizardPage3:processChange", name);
  }

  @api handlePage(dir) {
    // console.log('wizardPage3:pageHandler:', dir, this.wizardId, this.title);
    this.dispatchEvent(
      new CustomEvent("pagechange", { detail: { direction: dir } })
    );
  }

  activeTab = "firstTab";

  handleTabChange(event) {
    this.activeTab = event.detail.value;
  }

  @api prop1;
  @api prop2;
}
