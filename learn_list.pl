:- ensure_loaded('learn_lambda.pl').

examples_list(Pos,Neg,NTerm) :- 
  Pos = [
    eval(app(lam(x,var(x)),var(z)),var(z))
    ,eval(app(lam(x,var(y)),var(z)),var(y))
    ,eval(app(app(lam(x,lam(y,var(x))),var(z)),var(w)),var(z))
    ,eval( nil , nil)
    ,eval( cons(var(x),nil) , cons(var(x),nil))
    ,eval( head(cons(var(x),nil)),var(x))
    ,eval( tail(cons(var(x),cons(var(y),nil))),cons(var(y),nil))
    ],
  Neg = [
    eval(head(cons(var(x),nil)),nil)
    ,eval(head(cons(var(x),nil)),error)
    ,eval(cons(var(x),nil),nil)
    ,eval(cons(var(x),nil),var(x))
  ],
  NTerm = [].

learn_list :-
  examples_list(Pos,Neg,NTerm),
  learn(Pos,Neg,NTerm,Prog),
  pprint(Prog).





