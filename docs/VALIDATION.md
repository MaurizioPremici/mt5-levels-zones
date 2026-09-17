# Stato delle verifiche

Data: 17 settembre 2026.

## Completato

- Compilazione dell'indicatore completo con MetaEditor installato su MT5/Wine: **0 errori, 0 avvisi**, destinazione X64 Regular.
- Compilazione del test MQL5 `LevelTests.mq5`: **0 errori, 0 avvisi**.
- Controllo dei sorgenti di produzione: nessuna chiamata a funzioni di ordine, posizione, conto, rete, notifiche o importazione DLL.
- Copia di sorgenti, dipendenze locali ed eseguibile EX5 nella cartella Indicators/LevelsZones del terminale installato.

## Da completare prima della pubblicazione

Il collaudo interattivo non è completato. macOS ha negato l'accesso di automazione all'interfaccia e la cattura disponibile non ha mostrato il contenuto delle finestre.

È stato tentato anche un terminale portatile separato senza credenziali: il test è stato caricato, ma non è stato ottenuto un report di esecuzione. I test MQL5 sono quindi **compilati, non dichiarati superati**.

Verifiche funzionali ancora richieste:

1. Incolla nei campi, Applica e corrispondenza dei livelli alla scala prezzi.
2. Palette/HEX, colore di riempimento, slider della trasparenza, tratteggio e spessori.
3. Spostamento della linea, di ciascun estremo e dell'intera zona; aggiornamento dei campi, salvataggio e annullamento con ESC.
4. Gruppi di etichette vicine e tooltip.
5. Aggiunta, modifica, visibilità, blocco ed eliminazione dei campi personalizzati.
6. Cambio timeframe e due grafici dello stesso simbolo, con sincronizzazione e conflitto fra bozze.
7. Isolamento tra EURUSD e USDJPY o altri simboli.
8. Riavvio e recupero dei dati; chiusura/riapertura del pannello.
9. Scorrimento storico, zoom, ridimensionamento e scala del pannello sul display del Mac.

La pubblicazione pubblica su GitHub rimane subordinata al buon esito di queste verifiche, come richiesto dall'utente. Il materiale locale include già la foto di riferimento da allegare.
