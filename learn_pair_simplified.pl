:- ensure_loaded('learn_lambda.pl').

examples_pair(Pos,Neg,NTerm) :-	
  Pos = [
eval( app( lam(x,fst(var(x))) , 
           pair( app( lam(x,pair( app( lam( z, var(z)),var(x)),var(y))) , var(z)) , var(x)) ) , 
      pair(var(z),var(y)) ) 
  ],
  Neg = [],
  NTerm = [].

learn_pair_simplified :-
  examples_pair(Pos,Neg,NTerm),
  learn(Pos,Neg,NTerm,Prog),
  pprint(Prog).





