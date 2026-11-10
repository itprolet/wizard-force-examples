import { api } from "lwc";
import WizardPageBase from "prolet/wizardPageBase";
const DIETARY_OPTIONS = [
  { label: "No restriction", value: "none" },
  { label: "Vegetarian", value: "vegetarian" },
  { label: "Vegan", value: "vegan" },
  { label: "Gluten-free", value: "gluten-free" }
];

const SHIRT_SIZES = ["XS", "S", "M", "L", "XL", "XXL"].map((s) => ({
  label: s,
  value: s
}));

const ACCOMMODATION_OPTIONS = [
  { label: "No accommodation needed", value: "none" },
  { label: "Single room", value: "single" },
  { label: "Double room (shared)", value: "double" }
];

export default class ShowcasePreferences extends WizardPageBase {
  @api prop1;

  @api prop2;

  // --- page data ---
  data = {
    dietaryOption: null,
    shirtSize: null,
    accommodation: "none",
    shuttle: false
  };

  // --- options ---
  get dietaryOptions() {
    return DIETARY_OPTIONS;
  }

  get shirtSizeOptions() {
    return SHIRT_SIZES;
  }

  get accommodationOptions() {
    return ACCOMMODATION_OPTIONS;
  }

  // --- conditional ---
  get isAccommodationBooked() {
    return this.data.accommodation && this.data.accommodation !== "none";
  }
}
