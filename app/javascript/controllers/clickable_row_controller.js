import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  navigate(event) {
    if (event.type === "click" && event.target.closest("a, button, input, select, textarea")) return
    if (event.type === "keydown" && !["Enter", " "].includes(event.key)) return
    event.preventDefault()
    window.location.assign(this.urlValue)
  }
}
