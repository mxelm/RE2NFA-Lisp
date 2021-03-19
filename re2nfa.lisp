;;;; Messuri_Elettra_847008
;;:; Fagadau_Ionut_Daniel_845279


;;;; -*- Mode: Lisp -*-
;;;; nfa.lisp --





;;;; 1. IS-REGEXP
              
                                          
;;; Caso base: e' epsilon o e' atomica
;;; Caso ricorsivo: e' una lista

(defun is-regexp (RE)
  (cond ((equal RE 'epsilon) T)
        ((atom RE) T) 
        ((listp RE) (is-regexp-op RE))
        NIL))


;;; Controllo del car della lista per identificare 
;;; l'"operatore" dell'espressione regolare

(defun is-regexp-op (L)
  (cond ((or (and (equal 'seq (car L)) 
                  (>= (list-length (cdr L)) 1))	
             (and (equal 'or (car L)) 
                  (>= (list-length (cdr L)) 1))); Caso seq e or 
         (eval (append '(and) (mapcar #'is-regexp (cdr L)))))
        ((or (equal 'plus (car L))
             (equal 'star (car L)))	; Caso plus e star
         (and (equal (list-length (cdr L)) 1) (is-regexp(car (cdr L)))))
        (T T)))  ; Caso lista senza car riservato




;;;; 2. NFA-REGEXP-COMP
	

;;; Compilazione regexp e creazione rispettivo NFA

(defun nfa-regexp-comp (RE)
  (cond ((is-regexp RE)	; come prima cosa deve essere una regexp
         (cond ((atom RE) (atom-nfa-create RE))
               ((equal (car RE) 'seq)
                (seq-nfa-create 
                 (map 'list #'nfa-regexp-comp (cdr RE)))) ; NFA per seq
               ((equal (car RE) 'or) 
                (or-nfa-create 
                 (map 'list #'nfa-regexp-comp (cdr RE)))) ; NFA per or
               ((equal (car RE) 'plus) 
                (plus-nfa-create 
                 (nfa-regexp-comp (car (cdr RE)))))	; NFA per plus
               ((equal (car RE) 'star)
                (star-nfa-create 
                 (nfa-regexp-comp (car (cdr RE)))))	; NFA per star
               ((listp RE) (sexp-nfa-create RE)) ; NFA per una sexp
               NIL))
        NIL))

(setf state-number -1) ; Assegnamento dello stato iniziale


;;; Creazione NFA per regexp atomica

(defun atom-nfa-create (RE)
  (let   ((initial-state (increment-state-number))
          (final-state (increment-state-number)))
   (list (list 'initial initial-state)
 	 (list 'final final-state)
	 (list 'delta (list initial-state RE final-state)))))
	

;;; Creazione NFA per una sexp

(defun sexp-nfa-create (sexp)
  (let ((initial-state (increment-state-number))
        (final-state (increment-state-number)))
    (list (list 'initial initial-state)
          (list 'final final-state)
          (list 'delta (list initial-state sexp final-state)))))


;;; Creazione NFA per seq

(defun seq-nfa-create (nfa-list)
  (seq-temp (car nfa-list) (cdr nfa-list)))	

(defun seq-temp (final-nfa list-of-nfa)
  (cond
   ((null list-of-nfa) final-nfa)
   (T (seq-temp (nfa-merge final-nfa (car list-of-nfa))
		(cdr list-of-nfa)))))

(defun nfa-merge (first-nfa second-nfa)
  (let* ((initial-1 (nfa-initial-state first-nfa))
	 (initial-2 (nfa-initial-state second-nfa))
	 (final-1 (nfa-final-state first-nfa))
	 (final-2 (nfa-final-state second-nfa))
	 (new-transition (list final-1 'epsilon initial-2))
	 (delta (append (get-transitions first-nfa)
			(get-transitions second-nfa)
			(list new-transition))))
   (nfa-create initial-1 final-2 delta)))


;;; Creazione NFA per or

(defun or-nfa-create (nfa-list)
  (let* ((initial-state (increment-state-number))
	 (final-state (increment-state-number))
	 (delta 
	  (append (initial-e-transitions initial-state nfa-list)
		  (final-e-transitions final-state nfa-list))))
    (nfa-create initial-state final-state 
               (append (or-nfa-transitions nfa-list) delta))))
	 
(defun or-nfa-transitions (nfa-list)
  (cond
   ((null nfa-list) '())
   (T (append (get-transitions (car nfa-list)) 
	      (or-nfa-transitions (cdr nfa-list))))))
			
			 
;;; Creazione NFA per plus

(defun plus-nfa-create (nfa)
  (let* ((initial-state (increment-state-number))
	 (final-state (increment-state-number))
	 (tr1 (list initial-state 'epsilon (nfa-initial-state nfa)))
	 (tr2 (list (nfa-final-state nfa) 'epsilon final-state))
	 (tr3 (list final-state 'epsilon initial-state))
	 (delta (list tr1 tr2 tr3)))
   (nfa-create initial-state final-state 
               (append (get-transitions nfa) delta))))
			
			
;;; Creazione NFA per star

(defun star-nfa-create (nfa)
  (let* ((initial-state (increment-state-number))
	 (final-state (increment-state-number))
	 (tr1 (list initial-state 'epsilon (nfa-initial-state nfa)))
	 (tr2 (list (nfa-final-state nfa) 'epsilon final-state))
	 (tr3 (list final-state 'epsilon initial-state))
	 (tr4 (list initial-state 'epsilon final-state))
	 (delta (list tr1 tr2 tr3 tr4)))
    (nfa-create initial-state final-state
                (append (get-transitions nfa) delta))))



;;;; FUNZIONI VARIE CREAZIONE/GESTIONE E-NFA


;;; Creazione di un NFA

(defun nfa-create (initial-state final-state delta)
  (list (list 'initial initial-state) 
	(list 'final final-state)
	(append (list 'delta) delta)))
  

;;; Stato iniziale dell'automa

(defun nfa-initial-state (nfa)
  (car (cdr (car nfa))))


;;; Stato successivo

(defun increment-state-number ()
  (incf state-number)
  state-number)


;;; Stato finale dell'automa

(defun nfa-final-state (nfa)
  (car (cdr (car (cdr  nfa)))))


;;; Lista delle transizioni dell'NFA

(defun get-transitions (nfa)
  (cdr (car (last nfa))))


;;; Controlla se contiene almeno uno stato finale

(defun contains-final-state (nfa state-list)
  (cond
   ((null state-list) nil)
   ((state-is-final nfa (car state-list)) T)
   (T (contains-final-state nfa (cdr state-list)))))

;;; Verifica se lo stato e' finale

(defun state-is-final (nfa state)
  (= state (nfa-final-state nfa)))


;;; Azzeramento stati degli NFA

(defun reset-all-nfa ()
  (setq state-number -1))

	
;;; Lista delle epsilon transizioni

(defun initial-e-transitions (state nfa-list)
  (cond	
   ((null nfa-list) '())
   (T (append (list (list state 'epsilon (nfa-initial-state 
                                          (car nfa-list))))
	      (initial-e-transitions state (cdr nfa-list))))))

(defun final-e-transitions (state nfa-list)
  (cond	
   ((null nfa-list) '())
   (T (append (list (list (nfa-final-state 
                           (car nfa-list)) 'epsilon state)) 
	      (final-e-transitions state (cdr nfa-list))))))

	
				 	   		 		  
;;;; 3. NFA-TEST


;;; Verifica dell'input per vedere se e' accettato dall'NFA

(defun nfa-test (FA input)
	(cond
         ((atom FA) 
          (format t "Error: ~A is not a finite state automata"  FA))

	 ((not (and (listp (car FA)) 
                    (listp (second FA)) 
                    (listp (third FA))))
	 (format t "Error: ~A is not a finite state automata"  FA))
         ((not (and (eql (car (car FA)) 'INITIAL)
               (eql (car (second FA)) 'FINAL)
               (eql (car (third FA)) 'DELTA)))
          (format t "Error: ~A is not a finite state automata"  FA))
         ((not (listp input)) NIL)
         (T (nfa-matrix FA (list-of-eclosure-states FA '() 
                           (list (nfa-initial-state FA))) input))))
	

;;; Simulazione NFA

(defun nfa-matrix (nfa input-state input)
  (cond
   ((null input) (contains-final-state nfa input-state))
   ((null (list-of-next-states nfa input-state (car input))) NIL)
   (T (nfa-matrix nfa 
                     (list-of-next-states nfa input-state (car input)) 
                     (cdr input)))))
		
					
;;; E-closure degli stati in input

(defun list-of-eclosure-states (nfa closure states)
  (cond
   ((null states) closure)
   ((null (member (car states) closure))
   (list-of-eclosure-states nfa 
			  (append closure (list (car states))) 
			  (append (cdr states)
				  (transition-finder (get-transitions nfa)
						    (car states) 'epsilon))))
   (T (list-of-eclosure-states nfa closure (cdr states)))))


;;; Possibili transizioni

(defun transition-finder (transitions state input)
  (cond
   ((null transitions) '())
   ((and (= state (car (car transitions)))
         (equal input (car (cdr (car transitions)))))
                          (append (list (car (cdr (cdr (car transitions)))))
	                          (transition-finder 
                                   (cdr transitions) state input)))
   (T (transition-finder (cdr transitions) state input))))


;;; Stati successivi a quello corrente

(defun list-of-next-states (nfa input-state input-sym)
  (list-of-eclosure-states nfa '()
                         (list-of-nfa-states nfa input-state input-sym)))

(defun list-of-nfa-states (nfa states input)
  (cond
   ((null states) '())
   ((null (transition-finder (get-transitions nfa)
                            (car states) input ))
      (list-of-nfa-states nfa (cdr states) input))
   (T (append (transition-finder (get-transitions nfa)
                                (car states) input)
	      (list-of-nfa-states nfa (cdr states) input)))))
