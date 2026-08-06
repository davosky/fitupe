import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

// Connects to data-controller="grouped-bar-chart"
// Un grafico a barre con più serie raggruppate per etichetta (es. una serie
// per tipologia, un gruppo per comprensorio), a differenza di bar-chart che
// disegna una sola serie.
export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    labels: Array,
    datasetLabels: Array,
    data: Array
  }

  connect() {
    const colors = this.colors()

    this.chart = new Chart(this.canvasTarget, {
      type: "bar",
      data: {
        labels: this.labelsValue,
        datasets: this.datasetLabelsValue.map((label, index) => ({
          label,
          data: this.dataValue[index],
          backgroundColor: colors[index % colors.length]
        }))
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        layout: { padding: { top: 24 } },
        plugins: { legend: { position: "bottom" } },
        scales: { y: { beginAtZero: true } }
      },
      plugins: [ this.valueLabelsPlugin() ]
    })
  }

  disconnect() {
    this.chart?.destroy()
  }

  colors() {
    const palette = [ "--bs-warning", "--bs-danger", "--bs-success", "--bs-primary", "--bs-info", "--bs-dark" ]
    const style = getComputedStyle(document.documentElement)

    return palette.map((name) => style.getPropertyValue(name).trim())
  }

  // Disegna sopra ogni colonna la sua percentuale, per non dover passare dal
  // tooltip per leggerla.
  valueLabelsPlugin() {
    const data = this.dataValue

    return {
      id: "groupedBarValueLabels",
      afterDatasetsDraw: (chart) => {
        const { ctx } = chart

        ctx.save()
        ctx.textAlign = "center"
        ctx.font = "700 11px sans-serif"
        ctx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue("--bs-body-color").trim()

        data.forEach((series, datasetIndex) => {
          const bars = chart.getDatasetMeta(datasetIndex).data

          bars.forEach((bar, index) => {
            const value = series[index]
            if (!value) return

            ctx.fillText(`${value.toFixed(2).replace(".", ",")}%`, bar.x, bar.y - 6)
          })
        })

        ctx.restore()
      }
    }
  }
}
