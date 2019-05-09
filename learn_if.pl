:- ensure_loaded('learn_lambda.pl').

examples_if(Pos,Neg,NTerm) :-
  Pos = [
     eval( if(app(lam(x,var(x)),true),thenelse(true,false)),true)
    ,eval(app(lam(x,var(x)),var(z)),var(z))
    ,eval(app(lam(x,var(y)),var(z)),var(y))
    ,eval(app(app(lam(x,lam(y,var(x))),var(z)),var(w)),var(z))
    ,eval( true , true)
    ,eval( false, false)
    ,eval( if(true,thenelse(var(x),var(y))) , var(x))
    ,eval( if(false,thenelse(var(x),var(y))) , var(y))
    ],
  Neg = [
      eval( if(true,thenelse(var(x),var(y))) , var(y))
     ,eval( if(false,thenelse(var(x),var(y))) , var(x))
  ],
  NTerm = [].

learn_if :-
  examples_if(Pos,Neg,NTerm),
  learn(Pos,Neg,NTerm,Prog),
  pprint(Prog).





