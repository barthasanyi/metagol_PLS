:- ensure_loaded('learn_lambda.pl').

examples_call_by_value(Pos,Neg,NTerm) :-
  Pos = [
    eval(app(app(lam(x,lam(y,var(x))),var(z)),plus(5,5)),var(z))
	],
  Neg = [],
  NTerm = [
    eval(app(lam(x,var(y)),app(lam(x,app(var(x),var(x))),lam(x,app(var(x),var(x))))),var(y))
          ].

learn_call_by_value :-
  examples_call_by_value(Pos,Neg,NTerm),
  learn(Pos,Neg,NTerm,Prog),
  pprint(Prog).





