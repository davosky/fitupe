import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

// Connects to data-controller="bar-chart"
export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    labels: Array,
    data: Array
  }

  connect() {
    this.chart = new Chart(this.canvasTarget, {
      type: "bar",
      data: { labels: this.labelsValue, datasets: [ { data: this.dataValue, backgroundColor: this.colors() } ] },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        layout: { padding: { top: 24 } },
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: true } }
      },
      plugins: [ this.valueLabelsPlugin() ]
    })
  }

  disconnect() {
    this.chart?.destroy()
  }

  // Cicla sulla palette se le categorie sono più dei colori disponibili.
  colors() {
    const palette = [ "--bs-warning", "--bs-danger", "--bs-success", "--bs-primary", "--bs-info", "--bs-dark" ]
    const style = getComputedStyle(document.documentElement)

    return this.dataValue.map((_, index) => style.getPropertyValue(palette[index % palette.length]).trim())
  }

  // Disegna sopra ogni colonna il valore corrispondente.
  valueLabelsPlugin() {
    const data = this.dataValue

    return {
      id: "barValueLabels",
      afterDatasetsDraw: (chart) => {
        const { ctx } = chart
        const bars = chart.getDatasetMeta(0).data

        ctx.save()
        ctx.textAlign = "center"
        ctx.font = "700 14px sans-serif"
        ctx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue("--bs-body-color").trim()

        bars.forEach((bar, index) => {
          ctx.fillText(data[index].toLocaleString("it-IT"), bar.x, bar.y - 12)
        })

        ctx.restore()
      }
    }
  }
}
