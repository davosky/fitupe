# Changelog

Tutte le modifiche degne di nota a questo progetto saranno documentate in questo file.

Il formato è basato su [Keep a Changelog](https://keepachangelog.com/it/1.1.0/).

## [Non rilasciato]

### Aggiunto

- Statistiche Con Integrazioni: nuova dashboard che ricalibra i conteggi di Statistiche con le integrazioni FILLEA/Cassa Edile (differenza sul dato "Ordinaria Cassa Edile") e FLC/Anagrafe (somma pura con un mese di ritardo), applicate a Totale, Comprensori, Categorie, Tipologie Delega, Attivi/Pensionati e Tipologie Iscrizione.
- Stampa Statistiche: nuovo report PDF (Prawn, A4 orizzontale) con copertina dinamica, pagina Legenda opzionale (da testo ricco), Regionale/Comprensori, Categorie, Attivi/Pensionati, Tipologie, Provvisorie/Revoche, Sesso/Nazionalità, Status Lavorativo/Fasce d'Età, controcopertina e ripetizione automatica del report per ciascun comprensorio quando l'azzonamento scelto è regionale.
- Stampa Statistiche Con Integrazioni: lo stesso report PDF di Stampa Statistiche, con i numeri ricalibrati dalle integrazioni FILLEA/FLC.
- Importazioni SPI: nuova sezione di importazione CSV a schema dinamico dedicata ai dati dei pensionati SPI, con tabella e modello separati da Importazioni.
- Statistiche SPI: nuova dashboard (Regionale/Comprensori) per i dati SPI con distinzione tra iscritti e deleghe (una persona SPI può avere più deleghe) e un unico grafico con le colonne raggruppate per colore.
- CodeGuide: guida bilingue (italiano/inglese) sul funzionamento e le decisioni di design della feature Statistiche, con un file per ciascun servizio in `app/services/statistics/`.
- Statistiche: nuova sezione "Status Lavorativo" con tabella e grafico a barre, valori dinamici dal campo `tipologia_status` (es. Dipendente, Pensionato, ...) in ordine alfabetico, sul solo anno corrente.
- Statistiche: nuova sezione "Provvisorie / Revoche" con tabella e grafico a barre sul solo anno corrente, più tabella con la percentuale sul totale iscritti a fianco del grafico.
- Statistiche: nuova sezione "Sesso" con tabella e grafico a torta (FEMMINE, MASCHI) sul solo anno corrente, senza confronto con l'anno precedente.
- Statistiche: nuova sezione "Nazionalità" con tabella e grafico a torta (ITALIANA, UE, EXTRAUE) sul solo anno corrente, senza confronto con l'anno precedente.
- Statistiche: nuova sezione "Tipologie Delega" con tabella e grafico a barre, che confronta anno su anno Ordinaria, Ordinaria C.E., NASPI, DS Agricola, Delega Tesoro, Concomitante e Conc. SPI Anno.
- Statistiche: nuova sezione "Fasce d'Età" con tabella e grafico a barre, che raggruppa gli iscritti per fascia d'età (calcolata da `data_nascita`) da GIOVANI (< 30 anni) a HIGHLANDERS (oltre 100 anni), sul solo anno corrente. Le etichette dati del grafico mostrano la percentuale sul totale iscritti anziché il conteggio.
- Statistiche: la sezione "Attivi / Pensionati" mostra ora anche una tabella con la percentuale sul totale iscritti a fianco del grafico.
- Request spec per la pagina Statistiche: header/icona dinamici e stile grassetto verde/rosso su iscritti e %.

### Modificato

- Statistiche: le etichette percentuali nei grafici a barre (Comprensori, Categorie, Attivi/Pensionati) sono ora verdi per i valori positivi e rosse per i negativi.
- Statistiche: le colonne "iscritti" e "%" di tutte le tabelle sono in grassetto, verde se positive e rosso se negative.
- Statistiche: la card principale mostra il nome dell'azzonamento selezionato al posto dell'etichetta statica "Regionale", con icona `regionale.svg` per gli azzonamenti regionali e `comprensori.svg` per quelli provinciali.
- Statistiche: aumentati dimensione del font (12px → 14px) e margine (6px → 12px) delle etichette percentuali nei grafici a barre, per una migliore leggibilità.
- Statistiche: i grafici a torta mostrano ora valore e percentuale direttamente su ciascuna fetta.
- Statistiche: il grafico a barre della sezione "Status Lavorativo" è più largo e usa una palette di colori ciclica (con `--bs-dark` al posto di `--bs-secondary`, poco visibile nel tema Lumen).
- Rifinite l'icona e la navbar di Statistiche Con Integrazioni e di Stampa Statistiche (icona definitiva al posto del placeholder).
- Aggiornato il testo della pagina crediti.

### Corretto

- Corretta una vulnerabilità high (DoS) in `brace-expansion` (dipendenza transitiva di `nodemon`) forzando la versione patchata via `resolutions` in `package.json`.
- Aggiornato Rails a 8.1.3.1 per risolvere la CVE-2026-66066 su Active Storage.
- Statistiche Con Integrazioni: le sezioni "Attivi/Pensionati" e "Tipologie Iscrizione" non venivano ricalibrate con le correzioni FILLEA/FLC, per cui la loro somma non coincideva con il totale corretto (es. somma Categorie 40210 contro Attivi 38781). Ora la correzione viene sommata rispettivamente alla riga "Attivi" e alla riga "Delega".
