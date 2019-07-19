:- ensure_loaded('learn_lambda.pl').

:- ensure_loaded('learn_call_by_value.pl').
:- ensure_loaded('learn_list.pl').
:- ensure_loaded('learn_pair.pl').
:- ensure_loaded('learn_if.pl').

learn_all_atonce :-
  examples_call_by_value(P1,N1,NT1),
  examples_list(P2,N2,NT2),
  examples_pair(P3,N3,NT3),
  examples_if(P4,N4,NT4),
  append([P1,P2,P3,P4],P),
  append([N1,N2,N3,N4],N),
  append([NT1,NT2,NT3,NT4],NT),
  learn(P,N,NT,Prog),
  pprint(Prog).
 
 

