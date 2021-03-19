# RE2NFA - LISP

## INTRODUZIONE

Un’espressione regolare rappresenta in maniera finita un linguaggio, ossia un insieme potenzialmente infinito di sequenze di *simboli* tratto da un alfabeto Sigma.

In generale, se `<re1>`, `<re2>` ... `<rek>` sono delle regexp, lo saranno anche

- `<re1>` `<re2>`...`<rek>`	*(sequenza)*
- `<re1>`| `<re2>`				*(or)*
- `<re1>*`							*(chiusura di Kleene)*
- `<re1>+`							*(ripetizione 1 o più volte)*

Ad ogni regexp corrisponde un automa a stati finiti non-deterministico *(o NFA)* in grado di determinare se una sequenza di “simboli” appartiene o no all’insieme definito dall’espressione regolare, in un tempo asintoticamente lineare rispetto alla lunghezza della stringa.

In particolare, in Lisp, le espressioni regolari saranno espresse come:

- `<re1>` `<re2>`...`<rek>` diventa `(seq re1 re2 ... rek)`
- `<re1>`| `<re2>`	diventa `(or re1 re2 ... rek)`
- `<re1>*` diventa `(star re1)`
- `<re1>+` diventa `(plus re1)`

L’alfabeto dei “simboli” Sigma è costituito da S-exps Lisp.

nfa.lisp permette di effettuare la compilazione di espressioni regolari in automi non deterministici secondo l'algoritmo di Thompson.
E' composta da tre funzioni principali:

1. `is-regexp (RE)`: verifica che l'input sia un'espressione regolare.
2. `nfa-regexp-comp (RE)`: compila l'espressione regolare in un automa (differente in base al caso).
3. `nfa-test (FA input)`: verifica che l'espressione regolare passata sia riconosciuta dall'automa, ossia che consumandola completamente l'automa si trovi in uno stato finale.



## DESCRIZIONE PROGETTO

1. `is-regexp (RE)`
   Funzione che serve per verificare se l'input sia o meno un'espressione regolare; innazitutto si considerano i due casi base, ossia:

   - epsilon è un'espressione regolare 
   - un simbolo atomico è un'espressione regolare.

   In questi due casi viene ritornato T.
   Il caso ricorsivo si verifica quando l'input è una lista, in tale evenienza viene chiamata la funzione d'appoggio `is-regexp-op`.

   1. `is-regexp-op (L)`
      La funzione riconosce l' "operatore" in questione, prendendo in considerazione il `car` della lista.
      In particolare, per plus e star si è prestata attenzione al fatto che l'espressione regolare fosse composta da un solo elemento.

2. `nfa-regexp-comp (RE)`
   Per prima cosa si verifica nuovamente che l'input sia una un'espressione regolare, in caso positivo si ricontrolla il `car` di `RE` per identificare l'operatore in questione e chiamare di conseguenza la funzione atta alla generazione dell'automa ad esso corrispondente, sempre secondo l'algoritmo di Thompson.

   `(setf state-number -1)`
   Si è impostata la variabile che indica il numero dello stato corrente `(state-number)` a -1, dal momento che viene utlizzata la funzione `increment-state-number` per creare i nuovi stati dal nome univoco (partendo da 0).

   1. `atom-nfa-create (RE)`
      	Genera l'NFA corrispondente a una regexp atomica, creando una lista contenente:
       - stato iniziale
       - stato finale
       - la delta, che è ovviamente una sola ed è composta dallo stato iniziale, dall'espressione regolare atomica stessa (come input da consumare per cambiare stato) e dallo stato finale.
   2. `sexp-nfa-create (sexp)`
      Funziona in maniera analoga alla funzione `atom-nfa-create`; ma la delta ha come input da consumare la lista stessa (`sexp`), ossia un'espressione regolare senza il `car` riservato (seq, or, plus, ...).
   3. `seq-nfa-create (nfa-list)` & `seq-temp (final-nfa list-of-nfa)`
      Costruisce l'NFA corrispondente ad una sequenza di espressioni regolari (`<RE1><RE2>...<REn>`)facendo uso di una funzione d'appoggio `nfa-merge (first-nfa second-nfa)` che con due espressioni regolari genera due NFA e successivamente li unisce in un unico NFA.
   4. `or-nfa-create (nfa-list)`
      Generazione dell'NFA per le regexp in `or (<RE1>|<RE2>|...|<REn>)`.
      1. `or-nfa-transitions (nfa-list)`
         Funzione che crea una lista delle delta per le regexp in or.
   5. `plus-nfa-create (nfa)`
      Creazione dell'NFA corrispondente a `plus (<RE>+)`, ossia una ripetizione (1 o più volte).
   6. `star-nfa-create (nfa)`
      Costruzione dell'NFA corrispondente a `star (<RE>*)`, ovvero alla chiusura di Kleene (ripetizione 0 o più volte).
   7. `nfa-create (initial-state final-state delta)`
      Crea una lista di stati iniziali, una di stati finali e aggiunge ogni delta ad una lista di delta.
   8. `nfa-initial-state (nfa)`
      Ritorna lo stato iniziale dell'automa in input.
   9. `increment-state-number ()`
      E' un semplice incremento (per poter iniziare con lo stato iniziale = 0).
   10. `nfa-final-state (nfa)`
       Ritorna lo stato finale dell'automa in input.
   11. `get-transitions (nfa)`
       Ottiene e ritorna la lista delle transizioni dell'NFA passato come input.
   12. `contains-final-state (nfa state-list)`
       Ritorna true se almeno uno stato tra quelli passati in input è finale.
   13. `state-is-final (nfa state)`
       Controlla se lo stato passato come input è finale, in tal caso ritorna T.
   14. \* `reset-all-nfas ()`
       Funzione che fa ripartire da -1 (permettendo di stampare di nuovo da 0) i valori degli stati degli NFA già definiti, rendendoli sovrascrivibili.
       \*Se la si vuole usare, va chiamata dal listener.
   15. `initial-e-transitions (state nfa-list)` & `final-e-transitions (state nfa-list)`
       Crea una lista delle epsilon-transizioni dallo stato corrente (input) verso lo stato iniziale/finale degli automi compilati.

3. `nfa-test (FA input)`
   Dato un input e un NFA restituisce:

   - T se l'NFA, consumando l'input, si trova poi in uno stato finale.
   - NIL altrimenti

   Si è anche aggiunto un controllo per verificare che l'input `FA` rispetti la struttura di un automa, in caso contrario stampa un messaggio d'errore.

   1. `nfa-matrix`
      Funzione d'appoggio a `nfa-test` che "simula" l'esecuzione dell'NFA passato come input.
   2. `list-of-eclosure-states (nfa closure states)`
      Funzione che effettua le e-closures, ossia produce un insieme degli stati raggiungibili da un certo stato q tramite le epsilon-transizioni, degli stati in input restituendole come lista.
   3. `transition-finder (transitions state input)`
      Cerca e trova tutte le possibili transizioni di uno stato q (stato corrente) consumando un simbolo in input.
   4. `list-of-next-states (nfa input-state input-sym)` & `list-of-nfa-states (nfa states input)`
      Entrambe le funzioni servono a ritornare una lista degli stati successivi allo stato corrente dopo aver consumato un simbolo in input.