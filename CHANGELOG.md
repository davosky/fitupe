# Changelog

Tutte le modifiche degne di nota a questo progetto saranno documentate in questo file.

Il formato è basato su [Keep a Changelog](https://keepachangelog.com/it/1.1.0/).

## [Non rilasciato]

### Aggiunto

- Statistiche SPI: nuova sezione "Provvisorie" con tabella (Regionale e Comprensori, percentuale sul totale deleghe del periodo) e grafici a torta — a livello Regionale, Provvisorie contro Deleghe Confermate; a livello Comprensori, un'unica torta con una fetta colorata per ciascun comprensorio (percentuale reale, non ri-normalizzata) più la quota aggregata di Deleghe Confermate.
- Statistiche SPI: nuova sezione "Cessazioni" con tabella (Regionale e Comprensori) che conta le cessazioni per motivo (Altra Motivazione Ente, Cambio Situazione Pensionistica, Cessazione Posizione Pensionistica, Chiusura Iscrizione Provvisoria, Decesso, Revoca) e la relativa percentuale sul totale deleghe del periodo.
- Statistiche SPI: nuova sezione "Tipologie Delega" con tabella (Regionale e Comprensori) che conta le deleghe per tipologia (Ordinaria, Concomitante, Invalidi Civili, BreviManu, Altro), più un grafico a barre unico con tutti i comprensori raggruppati per colore e la relativa percentuale sul totale deleghe.
- Statistiche SPI: nuova sezione "Deleghe Multiple" con tabella (Regionale e Comprensori) che conta i pensionati con più di una delega nello stesso periodo (doppia/tripla/quadrupla/quintupla), riconciliati per comprensorio con la stessa tecnica DISTINCT ON usata per gli iscritti.
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
- Statistiche SPI: le card "Iscritti"/"Deleghe" (Regionale e Comprensori) sono state unificate in un'unica card con il nome della zona/"Comprensori" in cima seguito dalle sezioni Iscritti e Deleghe, ciascuna con icona dedicata (persona/documento) e badge CGIL SPI, invece di due card separate.
- Statistiche SPI: le tabelle mostrano ora "iscritti" o "deleghe" nell'intestazione della colonna differenza, a seconda della metrica rappresentata, invece del testo fisso "iscritti".
- Statistiche SPI: rifinite icona di pagina, icona e layout delle card "Deleghe Multiple" (Regionale e Comprensori) e colori dell'icona `multiplespi.svg` (icona definitiva al posto del placeholder).

### Corretto

- Corretta una vulnerabilità high (DoS) in `brace-expansion` (dipendenza transitiva di `nodemon`) forzando la versione patchata via `resolutions` in `package.json`.
- Aggiornato Rails a 8.1.3.1 per risolvere la CVE-2026-66066 su Active Storage.
- Corretta una vulnerabilità moderate in `postcss` (lettura di file `.map` non previsti quando `from` non è impostato) e una nuova vulnerabilità high in `brace-expansion` che aggirava la mitigazione precedente, aggiornando le versioni minime richieste rispettivamente a `^8.5.23` e `^5.0.9`.
- Statistiche Con Integrazioni: le sezioni "Attivi/Pensionati" e "Tipologie Iscrizione" non venivano ricalibrate con le correzioni FILLEA/FLC, per cui la loro somma non coincideva con il totale corretto (es. somma Categorie 40210 contro Attivi 38781). Ora la correzione viene sommata rispettivamente alla riga "Attivi" e alla riga "Delega".

### Sicurezza

- Aggiunta la gemma `secure_headers` con header di sicurezza HTTP applicativi: HSTS, X-Frame-Options, X-Content-Type-Options, X-Download-Options, X-Permitted-Cross-Domain-Policies, Referrer-Policy, cookie con flag Secure (in produzione)/HttpOnly/SameSite, e una Content-Security-Policy (nessun asset esterno, solo risorse self-hosted).
