import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

// Connects to data-controller="pie-chart"
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
      },
      plugins: [ this.dataLabelsPlugin() ]
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

  // Disegna al centro di ciascuna fetta il valore e la percentuale sul
  // totale, per non dover passare dal tooltip per leggerli.
  dataLabelsPlugin() {
    const data = this.dataValue
    const total = data.reduce((sum, value) => sum + value, 0)

    return {
      id: "pieDataLabels",
      afterDatasetsDraw: (chart) => {
        const { ctx } = chart
        const arcs = chart.getDatasetMeta(0).data

        ctx.save()
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        ctx.font = "700 13px sans-serif"
        ctx.fillStyle = "#ffffff"

        arcs.forEach((arc, index) => {
          const value = data[index]
          if (!value) return

          const percent = total === 0 ? 0 : (value / total * 100)
          const { x, y } = arc.tooltipPosition()
          ctx.fillText(`${value.toLocaleString("it-IT")}`, x, y - 8)
          ctx.fillText(`(${percent.toFixed(2).replace(".", ",")}%)`, x, y + 8)
        })

        ctx.restore()
      }
    }
  }
}
