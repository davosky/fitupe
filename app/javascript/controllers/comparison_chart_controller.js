import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

// Connects to data-controller="comparison-chart"
export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    labels: Array,
    previousData: Array,
    currentData: Array,
    percentages: Array,
    previousLabel: String,
    currentLabel: String
  }

  connect() {
    this.chart = new Chart(this.canvasTarget, {
      type: "bar",
      data: {
        labels: this.labelsValue,
        datasets: [
          { label: this.previousLabelValue, data: this.previousDataValue, backgroundColor: this.successColor() },
          { label: this.currentLabelValue, data: this.currentDataValue, backgroundColor: this.warningColor() }
        ]
      },
      options: {
        responsive: true,
        layout: { padding: { top: 24 } },
        scales: { y: { beginAtZero: true } }
      },
      plugins: [ this.percentageLabelsPlugin() ]
    })
  }

  disconnect() {
    this.chart?.destroy()
  }

  successColor() {
    return getComputedStyle(document.documentElement).getPropertyValue("--bs-success").trim()
  }

  warningColor() {
    return getComputedStyle(document.documentElement).getPropertyValue("--bs-warning").trim()
  }

  // Disegna sopra ogni colonna della seconda serie (anno corrente) la
  // differenza percentuale rispetto all'anno precedente.
  percentageLabelsPlugin() {
    const percentages = this.percentagesValue

    return {
      id: "percentageLabels",
      afterDatasetsDraw: (chart) => {
        const { ctx } = chart
        const bars = chart.getDatasetMeta(1).data

        ctx.save()
        ctx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue("--bs-body-color").trim()
        ctx.textAlign = "center"
        ctx.font = "600 12px sans-serif"

        bars.forEach((bar, index) => {
          const value = percentages[index]
          if (value === null || value === undefined) return

          const sign = value > 0 ? "+" : ""
          ctx.fillText(`${sign}${value.toFixed(2).replace(".", ",")}%`, bar.x, bar.y - 6)
        })

        ctx.restore()
      }
    }
  }
}
