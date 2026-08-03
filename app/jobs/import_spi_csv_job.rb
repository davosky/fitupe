class ImportSpiCsvJob < ApplicationJob
  queue_as :default

  def perform(path:, zoning_id:, anno:, mese:, overwrite:, token:)
    count = ImportSpis::CsvImporterService.call(
      path: path, zoning_id: zoning_id, anno: anno, mese: mese, overwrite: overwrite,
      progress: ->(percent) { broadcast(token, percent: percent) }
    )
    broadcast(token, count: count)
  rescue StandardError => e
    broadcast(token, error: e.message)
  ensure
    File.delete(path) if File.exist?(path)
  end

  private

  # Persisted alongside the broadcast: the client's ActionCable subscription can
  # take a moment to connect, and a fast (or already finished) job would
  # otherwise broadcast into the void, leaving the progress bar stuck forever.
  # The show action reads this back to render the current state on first load.
  def broadcast(token, locals)
    Rails.cache.write("import_spi_progress_#{token}", locals, expires_in: 1.hour)
    Turbo::StreamsChannel.broadcast_replace_to(
      "import_spi_progress_#{token}",
      target: "import_spi_progress",
      partial: "import_spis/progress",
      locals: locals
    )
  end
end
