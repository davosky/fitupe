# Documento Prawn A4 orizzontale con il font AsapCondensed registrato, come
# quello preparato da ReportPdf, per provare una singola pagina in isolamento.
module PdfHelpers
  def build_pdf
    pdf = Prawn::Document.new(page_size: "A4", page_layout: :landscape)
    asap_dir = Rails.root.join("app/assets/fonts")
    pdf.font_families.update(
      "AsapCondensed" => {
        normal: asap_dir.join("AsapCondensed-Regular.ttf"), bold: asap_dir.join("AsapCondensed-Bold.ttf"),
        italic: asap_dir.join("AsapCondensed-Italic.ttf"), bold_italic: asap_dir.join("AsapCondensed-BoldItalic.ttf")
      }
    )
    pdf
  end
end

RSpec.configure { |config| config.include PdfHelpers }
