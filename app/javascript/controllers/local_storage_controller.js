import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "output"]
  static values = { key: String }

  connect() {
    this.render()
  }

  save() {
    localStorage.setItem(
      this.keyValue,
      this.inputTarget.value
    )

    this.render()
  }

  clear() {
    localStorage.removeItem(this.keyValue)
    this.inputTarget.value = ""
    this.render()
  }

  render() {
    const value =
      localStorage.getItem(this.keyValue) ||
      "未保存"

    this.outputTarget.textContent = value
  }
}
