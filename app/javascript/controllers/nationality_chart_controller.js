import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

// Connects to data-controller="nationality-chart"
export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    labels: Array,
    data: Array
  }

  connect() {
    this.chart = new Chart(this.canvasTarget, {
      type: "pie",
      data: { labels: this.labelsValue, datasets: [ { data: this.dataValue, backgroundColor: this.colors() } ] },
      options: {
        responsive: true,
        plugins: {
          legend: { position: "bottom" },
          tooltip: { callbacks: { label: (context) => this.tooltipLabel(context) } }
        }
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }

  colors() {
    const style = getComputedStyle(document.documentElement)
    return [ "--bs-success", "--bs-warning", "--bs-danger" ].map((name) => style.getPropertyValue(name).trim())
  }

  tooltipLabel(context) {
    const total = context.dataset.data.reduce((sum, value) => sum + value, 0)
    const percent = total === 0 ? 0 : (context.parsed / total * 100)

    return `${context.label}: ${context.parsed.toLocaleString("it-IT")} (${percent.toFixed(2).replace(".", ",")}%)`
  }
}
