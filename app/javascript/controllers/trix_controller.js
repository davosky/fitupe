import { Controller } from "@hotwired/stimulus"
import Trix from "trix"

const HORIZONTAL_RULE_ACTION = "x-horizontal-rule"

Trix.config.textAttributes.underline = { tagName: "u", inheritable: true }
Trix.config.blockAttributes.justify = { tagName: "p", parse: false }

// Connects to data-controller="trix"
export default class extends Controller {
  extendToolbar({ target: { toolbarElement } }) {
    this.addButton(toolbarElement, "text-tools", this.underlineButtonHTML)
    this.addButton(toolbarElement, "block-tools", this.justifyButtonHTML)
    this.addButton(toolbarElement, "file-tools", this.horizontalRuleButtonHTML)
  }

  performAction({ target: { editor }, actionName }) {
    if (actionName !== HORIZONTAL_RULE_ACTION) return

    editor.insertAttachment(new Trix.Attachment({ content: "<hr>", contentType: "text/html" }))
    editor.insertLineBreak()
  }

  addButton(toolbarElement, group, html) {
    toolbarElement.querySelector(`[data-trix-button-group="${group}"]`).insertAdjacentHTML("beforeend", html)
  }

  get underlineButtonHTML() {
    return '<button type="button" class="trix-button" data-trix-attribute="underline" title="Sottolineato" tabindex="-1"><i class="bi bi-type-underline"></i></button>'
  }

  get justifyButtonHTML() {
    return '<button type="button" class="trix-button" data-trix-attribute="justify" title="Giustificato" tabindex="-1"><i class="bi bi-justify"></i></button>'
  }

  get horizontalRuleButtonHTML() {
    return `<button type="button" class="trix-button" data-trix-action="${HORIZONTAL_RULE_ACTION}" title="Linea orizzontale" tabindex="-1"><i class="bi bi-hr"></i></button>`
  }
}
