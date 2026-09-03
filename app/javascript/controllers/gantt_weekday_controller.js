import { Controller } from "@hotwired/stimulus"

const WEEKDAY_LABELS = ["日", "月", "火", "水", "木", "金", "土"]

export default class extends Controller {
  static targets = ["label"]
  static values = { date: String }

  connect() {
    const date = new Date(`${this.dateValue}T00:00:00`)
    this.labelTarget.textContent = WEEKDAY_LABELS[date.getDay()]
  }
}
