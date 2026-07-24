# Changelog

Tutte le modifiche degne di nota a questo progetto saranno documentate in questo file.

Il formato è basato su [Keep a Changelog](https://keepachangelog.com/it/1.1.0/).

## [Non rilasciato]

### Aggiunto

- Statistiche: nuova sezione "Status Lavorativo" con tabella e grafico a barre, valori dinamici dal campo `tipologia_status` (es. Dipendente, Pensionato, ...) in ordine alfabetico, sul solo anno corrente.
- Statistiche: nuova sezione "Provvisorie / Revoche" con tabella e grafico a barre sul solo anno corrente, più tabella con la percentuale sul totale iscritti a fianco del grafico.
- Statistiche: nuova sezione "Sesso" con tabella e grafico a torta (FEMMINE, MASCHI) sul solo anno corrente, senza confronto con l'anno precedente.
- Statistiche: nuova sezione "Nazionalità" con tabella e grafico a torta (ITALIANA, UE, EXTRAUE) sul solo anno corrente, senza confronto con l'anno precedente.
- Statistiche: nuova sezione "Tipologie Delega" con tabella e grafico a barre, che confronta anno su anno Ordinaria, Ordinaria C.E., NASPI, DS Agricola, Delega Tesoro, Concomitante e Conc. SPI Anno.
- Statistiche: la sezione "Attivi / Pensionati" mostra ora anche una tabella con la percentuale sul totale iscritti a fianco del grafico.
- Request spec per la pagina Statistiche: header/icona dinamici e stile grassetto verde/rosso su iscritti e %.

### Modificato

- Statistiche: le etichette percentuali nei grafici a barre (Comprensori, Categorie, Attivi/Pensionati) sono ora verdi per i valori positivi e rosse per i negativi.
- Statistiche: le colonne "iscritti" e "%" di tutte le tabelle sono in grassetto, verde se positive e rosso se negative.
- Statistiche: la card principale mostra il nome dell'azzonamento selezionato al posto dell'etichetta statica "Regionale", con icona `regionale.svg` per gli azzonamenti regionali e `comprensori.svg` per quelli provinciali.
- Statistiche: aumentati dimensione del font (12px → 14px) e margine (6px → 12px) delle etichette percentuali nei grafici a barre, per una migliore leggibilità.
- Statistiche: i grafici a torta mostrano ora valore e percentuale direttamente su ciascuna fetta.
- Statistiche: il grafico a barre della sezione "Status Lavorativo" è più largo e usa una palette di colori ciclica (con `--bs-dark` al posto di `--bs-secondary`, poco visibile nel tema Lumen).
