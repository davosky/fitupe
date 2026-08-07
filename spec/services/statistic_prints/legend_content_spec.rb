require "rails_helper"

RSpec.describe StatisticPrints::LegendContent do
  def blocks_for(html)
    legend = build(:legend, description: html)
    described_class.blocks(legend.description)
  end

  it "converte un paragrafo semplice" do
    blocks = blocks_for("<div>Testo semplice</div>")
    expect(blocks).to eq([ { type: :paragraph, text: "Testo semplice" } ])
  end

  it "converte grassetto e corsivo in tag Prawn" do
    blocks = blocks_for("<div>Testo <strong>forte</strong> e <em>enfatizzato</em></div>")
    expect(blocks.first[:text]).to eq("Testo <b>forte</b> e <i>enfatizzato</i>")
  end

  it "converte un elenco puntato in più blocchi list_item" do
    blocks = blocks_for("<ul><li>Uno</li><li>Due</li></ul>")
    expect(blocks).to eq([
      { type: :list_item, text: "Uno", prefix: "•" },
      { type: :list_item, text: "Due", prefix: "•" }
    ])
  end

  it "converte un elenco numerato con prefissi progressivi" do
    blocks = blocks_for("<ol><li>Primo</li><li>Secondo</li></ol>")
    expect(blocks.map { |b| b[:prefix] }).to eq([ "1.", "2." ])
  end

  it "esegue l'escape dei caratteri speciali nel testo" do
    blocks = blocks_for("<div>A &lt; B &amp; C</div>")
    expect(blocks.first[:text]).to eq("A &lt; B &amp; C")
  end

  it "non trasforma l'apostrofo in entità numerica (Prawn non la decodifica)" do
    blocks = blocks_for("<div>L'archivio dell'utente</div>")
    expect(blocks.first[:text]).to eq("L'archivio dell'utente")
  end

  it "converte un link mantenendo il testo e l'href" do
    blocks = blocks_for('<div>Vedi <a href="https://example.com">qui</a></div>')
    expect(blocks.first[:text]).to include('<link href="https://example.com">qui</link>')
  end

  it "converte la sottolineatura in tag Prawn" do
    blocks = blocks_for("<div>Testo <u>sottolineato</u></div>")
    expect(blocks.first[:text]).to eq("Testo <u>sottolineato</u>")
  end

  it "converte un paragrafo <p> in un blocco giustificato" do
    blocks = blocks_for("<p>Paragrafo giustificato</p>")
    expect(blocks).to eq([ { type: :paragraph, text: "Paragrafo giustificato", align: :justify } ])
  end

  it "converte un attachment contenuto <hr> in un blocco rule" do
    html = '<div>Prima</div><action-text-attachment content-type="text/html" content="&lt;hr&gt;"></action-text-attachment><div>Dopo</div>'
    blocks = blocks_for(html)
    expect(blocks.map { |b| b[:type] }).to eq([ :paragraph, :rule, :paragraph ])
  end

  it "ignora un attachment il cui contenuto non è una semplice riga orizzontale" do
    html = '<action-text-attachment content-type="text/html" content="&lt;p&gt;altro&lt;/p&gt;"></action-text-attachment>'
    expect(blocks_for(html)).to eq([])
  end

  it "converte un elenco puntato giustificato (Trix annida <p> dentro <li>)" do
    blocks = blocks_for("<ul><li><p>Punto giustificato</p></li></ul>")
    expect(blocks).to eq([ { type: :list_item, text: "Punto giustificato", prefix: "•", align: :justify } ])
  end

  it "non marca come giustificato un elenco puntato normale" do
    blocks = blocks_for("<ul><li>Punto normale</li></ul>")
    expect(blocks.first).not_to have_key(:align)
  end
end
