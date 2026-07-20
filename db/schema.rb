# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_20_121416) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "imports", force: :cascade do |t|
    t.string "altro_sesso"
    t.string "anno_di_riferimento"
    t.string "anno_stampa"
    t.bigint "azzonamento_di_riferimento_id", null: false
    t.string "cap"
    t.string "cap_unita_locale"
    t.string "categoria"
    t.string "categoria_pensione"
    t.string "categoria_sindacale"
    t.string "cellulare"
    t.string "cellulare_servizi"
    t.string "cellulare_servizio"
    t.string "codice_azzonamento_completo"
    t.string "codice_azzonamento_comprensoriale"
    t.string "codice_azzonamento_regionale"
    t.string "codice_azzonamento_regione"
    t.string "codice_categoria_pensione"
    t.string "codice_fiscale"
    t.string "codice_fiscale_azienda"
    t.string "codice_fiscale_errato"
    t.string "codice_pratica_inca"
    t.string "cognome"
    t.string "cognome_acquisito"
    t.string "comune"
    t.string "comune_unita_locale"
    t.string "concomitante_spi_anno"
    t.string "condizione_status"
    t.string "condizione_unita_locale"
    t.string "consenso1"
    t.string "consenso2"
    t.string "consenso3"
    t.string "consenso4"
    t.string "consenso_1_com_dati_sensibili"
    t.string "consenso_2_promozione"
    t.string "consenso_3_mandato"
    t.string "consenso_4_profilazione"
    t.string "contratto_nazionale"
    t.datetime "created_at", null: false
    t.date "data_contabilizzazione_tessera"
    t.date "data_decesso"
    t.date "data_fine_iscrizione"
    t.date "data_fine_lavoro"
    t.date "data_fine_trattenuta"
    t.date "data_inizio_iscrizione"
    t.date "data_inizio_lavoro"
    t.date "data_inizio_trattenuta"
    t.date "data_nascita"
    t.string "descrizione_azzonamento_completo"
    t.string "descrizione_azzonamento_comprensoriale"
    t.string "descrizione_azzonamento_regionale"
    t.string "descrizione_azzonamento_regione"
    t.string "descrizione_reparto"
    t.string "documento_privacy"
    t.string "email"
    t.string "email_azienda"
    t.string "email_servizi"
    t.string "email_servizio"
    t.string "ente"
    t.string "eta"
    t.string "evento_attivazione_iscrizione"
    t.string "frazione"
    t.string "funzionario"
    t.string "indirizzo"
    t.string "indirizzo_unita_locale"
    t.string "iscritto_digita"
    t.string "livello"
    t.string "localita_postale"
    t.string "luogo_nascita"
    t.string "mese_di_riferimento"
    t.string "motivo_cessazione_iscrizione"
    t.string "motivo_cessazione_lavoro"
    t.string "motivononoccupazione"
    t.string "nato_a"
    t.string "nazionalita"
    t.string "nazione"
    t.string "nome"
    t.string "nome_unita_locale"
    t.string "nome_unita_locale_fruitrice"
    t.string "numero_pensione"
    t.string "part_time"
    t.string "partita_iva_azienda"
    t.string "provincia"
    t.string "provincia_unita_locale"
    t.string "provvisoria"
    t.string "qualifica"
    t.string "ragione_sociale_azienda"
    t.string "ragione_sociale_azienda_fruitrice"
    t.string "rata"
    t.string "sap"
    t.string "sede_primaria"
    t.string "sesso"
    t.string "settore_lavorativo"
    t.string "stampa_tessera"
    t.string "stato_civile"
    t.string "status_confermato_da_nastro"
    t.string "struttura_attivazione_iscrizione"
    t.string "telefono"
    t.string "telefono_azienda"
    t.string "tipologia_azienda"
    t.string "tipologia_delega"
    t.string "tipologia_iscrizione"
    t.string "tipologia_rapporto_lavoro"
    t.string "tipologia_status"
    t.string "tipologia_versamento"
    t.string "titolo_di_studio"
    t.string "titolo_studio"
    t.datetime "updated_at", null: false
    t.index ["azzonamento_di_riferimento_id", "anno_di_riferimento", "mese_di_riferimento"], name: "index_imports_on_azzonamento_and_periodo"
    t.index ["azzonamento_di_riferimento_id"], name: "index_imports_on_azzonamento_di_riferimento_id"
    t.index ["codice_fiscale"], name: "index_imports_on_codice_fiscale"
  end

  create_table "integration_filleas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "subscribers_ce", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "year", null: false
    t.bigint "zoning_id", null: false
    t.index ["zoning_id", "year"], name: "index_integration_filleas_on_zoning_year", unique: true
    t.index ["zoning_id"], name: "index_integration_filleas_on_zoning_id"
  end

  create_table "integration_flcs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "month", null: false
    t.bigint "subscribers_af", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "year", null: false
    t.bigint "zoning_id", null: false
    t.index ["zoning_id", "year", "month"], name: "index_integration_flcs_on_zoning_year_month", unique: true
    t.index ["zoning_id"], name: "index_integration_flcs_on_zoning_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "first_name"
    t.string "gender"
    t.string "last_name"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "locked_at"
    t.boolean "manager", default: false, null: false
    t.string "province"
    t.string "region"
    t.boolean "regular", default: false, null: false
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.string "username", default: "", null: false
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "zonings", force: :cascade do |t|
    t.string "codice_azzonamento", null: false
    t.datetime "created_at", null: false
    t.string "descrizione_azzonamento", null: false
    t.datetime "updated_at", null: false
    t.index ["codice_azzonamento"], name: "index_zonings_on_codice_azzonamento", unique: true
  end

  add_foreign_key "imports", "zonings", column: "azzonamento_di_riferimento_id"
  add_foreign_key "integration_filleas", "zonings"
  add_foreign_key "integration_flcs", "zonings"
end
