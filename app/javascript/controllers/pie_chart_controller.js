import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

// Connects to data-controller="pie-chart"
export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    labels: Array,
    data: Array,
    // Quando true, i valori in `data` sono già percentuali (non conteggi da
    // rapportare alla somma del dataset) — usato per confrontare un tasso già
    // calcolato tra più fette (es. una percentuale diversa per comprensorio),
    // dove la dimensione della fetta serve solo al confronto visivo relativo
    // e l'etichetta deve riportare il valore così com'è, non una sua ulteriore
    // percentuale sul totale del grafico.
    rawPercentages: Boolean
  }

  connect() {
    this.chart = new Chart(this.canvasTarget, {
      type: "pie",
      data: { labels: this.labelsValue, datasets: [ { data: this.dataValue, backgroundColor: this.colors() } ] },
      options: {
        responsive: true,
        maintainAspectRatio: false,
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

  // Cicla sulla palette se le fette sono più dei colori disponibili.
  colors() {
    const palette = [ "--bs-success", "--bs-warning", "--bs-danger", "--bs-primary", "--bs-info", "--bs-dark", "--bs-secondary" ]
    const style = getComputedStyle(document.documentElement)

    return this.dataValue.map((_, index) => style.getPropertyValue(palette[index % palette.length]).trim())
  }

  formatPercent(value) {
    return `${value.toFixed(2).replace(".", ",")}%`
  }

  tooltipLabel(context) {
    if (this.rawPercentagesValue) return `${context.label}: ${this.formatPercent(context.parsed)}`

    const total = context.dataset.data.reduce((sum, value) => sum + value, 0)
    const percent = total === 0 ? 0 : (context.parsed / total * 100)

    return `${context.label}: ${context.parsed.toLocaleString("it-IT")} (${this.formatPercent(percent)})`
  }

  // Disegna al centro di ciascuna fetta il valore e la percentuale sul
  // totale, per non dover passare dal tooltip per leggerli.
  dataLabelsPlugin() {
    const data = this.dataValue
    const rawPercentages = this.rawPercentagesValue
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

          const { x, y } = arc.tooltipPosition()

          if (rawPercentages) {
            ctx.fillText(this.formatPercent(value), x, y)
            return
          }

          const percent = total === 0 ? 0 : (value / total * 100)
          ctx.fillText(`${value.toLocaleString("it-IT")}`, x, y - 8)
          ctx.fillText(`(${this.formatPercent(percent)})`, x, y + 8)
        })

        ctx.restore()
      }
    }
  }
}
