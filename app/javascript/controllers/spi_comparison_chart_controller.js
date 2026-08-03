import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

// Connects to data-controller="spi-comparison-chart"
// Come comparison-chart ma con 4 serie (Iscritti/Deleghe x anno precedente/
// corrente) raggruppate per comprensorio nello stesso grafico, distinte per
// colore.
export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    labels: Array,
    iscrittiPreviousData: Array,
    iscrittiCurrentData: Array,
    deleghePreviousData: Array,
    delegheCurrentData: Array,
    iscrittiPercentages: Array,
    deleghePercentages: Array,
    previousLabel: String,
    currentLabel: String
  }

  connect() {
    this.chart = new Chart(this.canvasTarget, {
      type: "bar",
      data: {
        labels: this.labelsValue,
        datasets: [
          { label: `Iscritti ${this.previousLabelValue}`, data: this.iscrittiPreviousDataValue, backgroundColor: this.successColor() },
          { label: `Iscritti ${this.currentLabelValue}`, data: this.iscrittiCurrentDataValue, backgroundColor: this.warningColor() },
          { label: `Deleghe ${this.previousLabelValue}`, data: this.deleghePreviousDataValue, backgroundColor: this.infoColor() },
          { label: `Deleghe ${this.currentLabelValue}`, data: this.delegheCurrentDataValue, backgroundColor: this.dangerColor() }
        ]
      },
      options: {
        responsive: true,
        layout: { padding: { top: 24 } },
        scales: {
          x: { ticks: { font: { style: "italic" } } },
          y: { beginAtZero: true }
        }
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

  infoColor() {
    return getComputedStyle(document.documentElement).getPropertyValue("--bs-info").trim()
  }

  dangerColor() {
    return getComputedStyle(document.documentElement).getPropertyValue("--bs-danger").trim()
  }

  // Disegna sopra le colonne dell'anno corrente (Iscritti e Deleghe, dataset 1
  // e 3) la differenza percentuale rispetto all'anno precedente.
  percentageLabelsPlugin() {
    const iscrittiPercentages = this.iscrittiPercentagesValue
    const deleghePercentages = this.deleghePercentagesValue

    return {
      id: "percentageLabels",
      afterDatasetsDraw: (chart) => {
        const { ctx } = chart
        const successColor = this.successColor()
        const dangerColor = this.dangerColor()

        ctx.save()
        ctx.textAlign = "center"
        ctx.font = "600 12px sans-serif"

        this.drawLabels(ctx, chart.getDatasetMeta(1).data, iscrittiPercentages, successColor, dangerColor)
        this.drawLabels(ctx, chart.getDatasetMeta(3).data, deleghePercentages, successColor, dangerColor)

        ctx.restore()
      }
    }
  }

  drawLabels(ctx, bars, percentages, successColor, dangerColor) {
    bars.forEach((bar, index) => {
      const value = percentages[index]
      if (value === null || value === undefined) return

      const sign = value > 0 ? "+" : ""
      ctx.fillStyle = value < 0 ? dangerColor : successColor
      ctx.fillText(`${sign}${value.toFixed(2).replace(".", ",")}%`, bar.x, bar.y - 8)
    })
  }
}
