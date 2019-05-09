:- ensure_loaded('learn_lambda.pl').

:- ensure_loaded('learn_call_by_value.pl').
:- ensure_loaded('learn_list.pl').
:- ensure_loaded('learn_pair.pl').
:- ensure_loaded('learn_if.pl').

main :-
  examples_call_by_value(P1,N1,NT1),
  examples_list(P2,N2,NT2),
  examples_pair(P3,N3,NT3),
  examples_if(P4,N4,NT4),
  learn_seq2([
   (P1,N1,NT1)
   ,(P2,N2,NT2)
   ,(P3,N3,NT3)
   ,(P4,N4,NT4)
  ],Prog),
  pprint(Prog).
 
 

