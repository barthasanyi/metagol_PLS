:- ensure_loaded('learn_lambda.pl').

examples_pair(Pos,Neg,NTerm) :-	
  Pos = [
    eval(
    pair( app(lam(x,var(x)),var(z)) , app(lam(y,var(y)),var(z)))
    , pair(var(z),var(z))
    )
    ,eval(
    fst( app( lam(x, snd( app( lam(y,pair(var(y),var(x))) ,var(z)) )),
              pair(var(z),var(y)) ))
    , var(z)
    )
    ,eval(
    app( lam(x,snd( app( lam(y,fst(var(y))), pair(var(x),var(z))) )) , pair( app( lam(x,var(y)) , var(z)) , var(x)) )
    , var(x)
    )
    ,eval(snd(snd(pair(var(x),pair(var(y),var(z))))),var(z))
    ,eval(fst(fst(pair(pair(var(x),var(y)),var(z)))),var(x))
    ,eval(snd(fst(pair(pair(var(x),var(y)),var(z)))),var(y))
  ],
  Neg = [],
  NTerm = [].

learn_pair :-
  examples_pair(Pos,Neg,NTerm),
  learn(Pos,Neg,NTerm,Prog),
  pprint(Prog).





