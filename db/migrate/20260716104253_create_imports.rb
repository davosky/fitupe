class CreateImports < ActiveRecord::Migration[8.1]
  def change
    create_table :imports do |t|
      t.string :categoria_sindacale
      t.string :cognome
      t.string :cognome_acquisito
      t.string :nome
      t.string :consenso_1_com_dati_sensibili
      t.string :consenso_2_promozione
      t.string :consenso_3_mandato
      t.string :consenso_4_profilazione
      t.string :documento_privacy
      t.string :codice_fiscale
      t.string :codice_fiscale_errato
      t.string :iscritto_digita
      t.string :sesso
      t.string :altro_sesso
      t.string :stato_civile
      t.date :data_nascita
      t.date :data_decesso
      t.string :nato_a
      t.string :titolo_di_studio
      t.string :telefono
      t.string :cellulare
      t.string :cellulare_servizi
      t.string :email
      t.string :email_servizi
      t.string :indirizzo
      t.string :frazione
      t.string :localita_postale
      t.string :cap
      t.string :comune
      t.string :provincia
      t.string :nazionalita
      t.string :nazione
      t.string :tipologia_status
      t.string :tipologia_rapporto_lavoro
      t.date :data_inizio_lavoro
      t.date :data_fine_lavoro
      t.string :motivo_cessazione_lavoro
      t.string :tipologia_iscrizione
      t.string :tipologia_delega
      t.date :data_inizio_iscrizione
      t.date :data_fine_iscrizione
      t.date :data_inizio_trattenuta
      t.date :data_fine_trattenuta
      t.string :tipologia_versamento
      t.string :motivo_cessazione_iscrizione
      t.string :provvisoria
      t.string :status_confermato_da_nastro
      t.string :concomitante_spi_anno
      t.string :codice_categoria_pensione
      t.string :categoria_pensione
      t.string :sede_primaria
      t.string :numero_pensione
      t.string :ente
      t.string :sap
      t.string :codice_azzonamento_comprensoriale
      t.string :descrizione_azzonamento_comprensoriale
      t.string :codice_azzonamento_completo
      t.string :descrizione_azzonamento_completo
      t.string :codice_azzonamento_regione
      t.string :descrizione_azzonamento_regione
      t.string :stampa_tessera
      t.string :anno_stampa
      t.date :data_contabilizzazione_tessera
      t.string :struttura_attivazione_iscrizione
      t.string :evento_attivazione_iscrizione
      t.string :rata
      t.string :codice_pratica_inca

      t.string :anno_di_riferimento
      t.string :mese_di_riferimento
      t.references :azzonamento_di_riferimento, null: false, foreign_key: { to_table: :zonings }

      t.timestamps
    end

    add_index :imports, [ :azzonamento_di_riferimento_id, :anno_di_riferimento, :mese_di_riferimento ],
      name: "index_imports_on_azzonamento_and_periodo"
    add_index :imports, :codice_fiscale
  end
end
