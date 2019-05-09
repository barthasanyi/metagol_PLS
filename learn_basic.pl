:- ensure_loaded('learn_lambda.pl').


examples_basic(Pos,Neg,NTerm) :-
  Pos = [
     eval(app(lam(x,var(x)),var(z)),var(z))
    ,eval(app(lam(x,var(y)),var(z)),var(y))
    ,eval(app(app(lam(x,lam(y,var(x))),var(z)),var(w)),var(z))
	],
  Neg = [
    eval(app(lam(x,var(y)),var(z)),var(z))
  ],
  NTerm = [].

learn_basic :-
  examples_basic(Pos,Neg,NTerm),
  learn(Pos,Neg,NTerm,Prog),
  pprint(Prog).





