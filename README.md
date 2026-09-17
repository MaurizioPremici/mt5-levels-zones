# Livelli e zone — MetaTrader 5

Pannello grafico in italiano per inserire manualmente prezzi e intervalli, disegnando linee orizzontali e zone trasparenti. Pensato per MT5 desktop, incluso MT5 su Mac tramite Wine.

![Riferimento grafico fornito dall'utente](docs/gui-reference.png)

**L'immagine è il riferimento di progetto, non una schermata del programma in esecuzione.** I prezzi raffigurati sono dimostrativi. Il pannello effettivo usa controlli nativi di MT5 e parte con tutti i prezzi vuoti.

## Funzioni

- Entry Price, Breakout Price, Retest Price, Rejection Price, Support, Resistance, SL, TP 1 e TP 2.
- Campi personalizzati, nomi modificabili, visibilità e blocco dello spostamento.
- Una sola quotazione: linea. Due estremi: zona; gli estremi invertiti vengono ordinati.
- Colori indipendenti per linea/bordo e riempimento, palette e codici HEX.
- Spessore 1–5 pixel, stile continuo o tratteggiato anche con spessori maggiori di uno.
- Trasparenza 0–100%: 0% opaco, 100% invisibile. Valore iniziale 80%.
- Zone estese all'intera area del grafico, anche scorrendo sulle candele passate.
- Etichette a sinistra. I livelli troppo vicini sono raggruppati; il tooltip mostra tutti i dettagli.
- Trascinamento della linea, dei bordi e della maniglia centrale della zona; ESC annulla.
- Salvataggio locale dopo Applica e dopo il rilascio del trascinamento; ripristino al riavvio.
- Sincronizzazione tra grafici dello stesso simbolo **nel medesimo terminale**, con l'indicatore caricato su ciascuno. Cambiare timeframe mantiene i valori. Simboli diversi, inclusi suffissi diversi del broker, sono separati.
- Revisione condivisa per impedire a una bozza vecchia di sovrascrivere una modifica applicata da un altro grafico.

Non contiene invio/modifica/chiusura di ordini, lettura di posizioni o segnali. Il timer aggiorna esclusivamente il disegno rispetto alla scala del grafico e controlla lo stato grafico salvato.

## Installazione

1. In MT5: **File → Apri cartella dati**.
2. Copia la cartella `src` con i sorgenti nella cartella `MQL5/Indicators/LevelsZones` (senza un ulteriore livello `src`).
3. Apri `LevelsZones.mq5` in MetaEditor e compila con **F7**. Usa le librerie standard già incluse in MT5.
4. In MT5, aggiorna il Navigatore e aggiungi **LevelsZones / LevelsZones** a un grafico. Ripeti sui grafici della stessa coppia che vuoi sincronizzare.
5. Se necessario regola l'input **PanelScale**, da 0.75 a 1.75, per il display.

Su Mac con l'installazione Wine standard, gli script `build/compile.py` e `build/install.py` automatizzano compilazione e copia. `install.py --data-dir <cartella>` permette di specificare un'altra cartella dati. Non modificano profili esistenti o altri indicatori.

## Uso

Incolla il prezzo in **Prezzo / Da**. Lascia **A** vuoto per una linea, oppure inserisci il secondo estremo per una zona. Il separatore decimale può essere punto o virgola, senza separatori delle migliaia. Decimali eccedenti quelli del simbolo, testo aggiuntivo e range di ampiezza zero vengono rifiutati.

Premi **Applica** per disegnare, salvare e sincronizzare tutti i campi. Le modifiche nei campi sono una bozza fino a quel momento. Per svuotare un livello cancella entrambi i prezzi e applica; i campi personalizzati possono anche essere eliminati.

**ON/OFF** controlla la visibilità. **L/U** significa bloccato/sbloccato; i tooltip esplicitano l'azione. Scegli **U** e applica per trascinare. Questi pulsanti testuali evitano dipendenze da font di icone non sempre disponibili sotto Wine.

**...** espande le impostazioni. La palette include un campo HEX per qualsiasi colore RGB. I pulsanti **Su/Giu** permettono di raggiungere le righe fuori dal pannello. Il simbolo **x** nasconde il pannello lasciando visibili i disegni; il pulsante **Livelli e zone** lo riapre.

Per una zona usa la maniglia centrale per traslarla mantenendone l'ampiezza, oppure i bordi per regolarne gli estremi. Un trascinamento viene salvato al rilascio. Prima di trascinare applica o scarta eventuali bozze.

Se un altro grafico salva mentre stai modificando i campi, il pannello segnala il conflitto. **Ricarica** scarta la bozza e recupera l'ultima versione salvata; il programma non sovrascrive silenziosamente la versione più recente.

## Dati e limiti

I dati sono conservati in `MQL5/Files/LevelsZones`. Il file `.bak` contiene la precedente versione completa. Un file danneggiato viene segnalato e conservato, non sovrascritto con valori vuoti. Posizione e stato del pannello vengono salvati separatamente per grafico.

Sono supportati fino a 128 campi per simbolo. Per il pannello a scala 1 serve uno spazio di circa 520 pixel in larghezza. Gli elementi esterni creati da altri indicatori non sono gestiti da questo programma: non è garantita l'assenza di sovrapposizioni con qualsiasi oggetto di terzi.

I disegni appartengono all'indicatore e vengono rimossi dal grafico quando lo si rimuove. I livelli salvati restano disponibili per il successivo caricamento.

## Sorgenti e verifiche

- `src/LevelsZones.mq5`: ciclo di vita, eventi, applicazione, sincronizzazione e trascinamento.
- `src/LevelPanel.mqh`: interfaccia nativa.
- `src/LevelRenderer.mqh`: disegno Canvas, trasparenza, tratteggio e hit testing.
- `src/LevelModel.mqh`: modello e validazione dei prezzi.
- `src/LevelStore.mqh`: archiviazione, controllo delle revisioni e backup.
- `tests/LevelTests.mq5`: verifiche MQL5 sulla validazione e sull'archiviazione, con file di prova dedicati.
- `reference/LevelsZonesPanel_UI.mq5`: codice GUI originale fornito dall'utente.
- `docs/gui-reference.png`: immagine di riferimento fornita dall'utente.

Lo stato effettivo delle verifiche viene riportato in `docs/VALIDATION.md`. La sola compilazione non costituisce un collaudo interattivo.
