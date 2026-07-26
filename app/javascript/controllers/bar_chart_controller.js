import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

// Connects to data-controller="bar-chart"
export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    labels: Array,
    data: Array,
    percentages: { type: Array, default: [] }
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

  // Disegna sopra ogni colonna il valore corrispondente, oppure la
  // percentuale quando viene passato data-bar-chart-percentages-value.
  valueLabelsPlugin() {
    const data = this.dataValue
    const percentages = this.percentagesValue

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
          ctx.fillText(this.label(data, percentages, index), bar.x, bar.y - 12)
        })

        ctx.restore()
      }
    }
  }

  label(data, percentages, index) {
    if (percentages.length === 0) return data[index].toLocaleString("it-IT")

    return `${percentages[index].toFixed(2).replace(".", ",")}%`
  }
}
