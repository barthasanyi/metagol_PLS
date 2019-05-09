:- use_module('metagolPLS').

metagol:max_clauses(30).
metagol:max_inv_preds(10).
metagol:function_metavars.
metagol:max_depth(100).

% Lambda calculus implementation is based on:
% https://userpages.uni-koblenz.de/~laemmel/paradigms1011/resources/pdf/lambda-prolog.pdf

:- dynamic value/1.
:- dynamic step/2.

value(X) :- integer(X).

value(var(_X)).
value(lam(_X,_T)).

variable(X) :- atom(X).

plus(X,Y,Z) :- integer(X), integer(Y), Z is X+Y.
step(plus(X,Y),Z) :- plus(X,Y,Z).
step(app(lam(X,T1),V),T2) :-
   argcond(V),
   substitute(V,X,T1,T2).
step(app(T1,T2),app(T3,T2)) :-
   step(T1,T3).
eval(X,X) :- value(X).
eval(X,Z) :- 
  step(X,Y),
  eval(Y,Z).

substitute(N,X,var(X),N).
substitute(_,X,var(Y),var(Y)) :-
    \+ X == Y.
substitute(_,_,I,I) :- integer(I).
substitute(N,X,app(M1,M2),app(M3,M4)) :-
    substitute(N,X,M1,M3),
    substitute(N,X,M2,M4).
substitute(_,X,lam(X,M),lam(X,M)).

substitute(N,X,lam(Y,M1),lam(Y,M2))
 :-
    \+ X == Y,
    freevars(N,Xs),
    \+ member(Y,Xs),
    substitute(N,X,M1,M2).

substitute(N,X,lam(Y,M1),lam(Z,M3))
 :-
    \+ X == Y,
    freevars(N,Xs),
    member(Y,Xs),
    freshvar(Xs,Z),
    substitute(var(Z),Y,M1,M2),
    substitute(N,X,M2,M3).

%unary case, non-var
substitute(N,X,A,B) :-
    A =.. [H,C] ,
    H \= var,
    substitute(N,X,C,D),
    B =.. [H,D].
%binary case, non-lambda
substitute(N,X,A,B) :-
    A =.. [H,M1,M2],
    H \= lam,
    substitute(N,X,M1,M3),
    substitute(N,X,M2,M4),
    B =.. [H,M3,M4].

freevars(var(X),[X]) :- variable(X).
freevars(lambda(X,T), R) :- 
  variable(X),
  freevars(T,F),
  delete(F,X,R).
freevars(A,L) :-
   A =.. [H,C] ,
   H \= var,
   freevars(C,L).
freevars(A,L) :-
    A =.. [H,M1,M2],
    H \= lam,
    freevars(M1,L1),
    freevars(M2,L2),
    union(L1,L2,L).


freshvar(Xs,X) :-
    freshvar(Xs,X,0).
freshvar(Xs,N,N) :- 
    \+ member(N,Xs).
freshvar(Xs,X,N1) :- 
    member(N1,Xs),
    N2 is N1 + 1,
    freshvar(Xs,X,N2). 

accept(_X) :- true.

left(A,_,A).
right(_,B,B).

%Set up metagol

prim(left/3).
prim(right/3).
prim(plus/3).
prim(accept/1).
prim(integer/1).
prim(substitute/4).

interpreted(eval/2).
interpreted(value/1).
interpreted(step/2).
extensible(step/2).
extensible(value/1).
extensible(argcond/1).
noncallable(eval/2).
noncallable(step/2).
noncallable(argcond/1).
noncallable(integer/1).
noncallable(substitute/4).
noncallable(plus/3).

metarule(argcond,[argcond,P],([argcond,X]:-[[P,X]])).
metarule(step1,[step,H],([step,[H,L],[H,L1]]:-[[step,L,L1]])).
metarule(step2l,[step,H],([step,[H,L,R],[H,L1,R]]:-[[step,L,L1]])).
metarule(step2r,[step,H],([step,[H,L,R],[H,L,R1]]:-[[step,R,R1]])).
metarule(value0,[value,A],([value,A]:-[])) :- atom(A).
metarule(value1,[value,H],([value,[H,L]]:-[[value,L]])).
metarule(value2,[value,H],([value,[H,L,R]]:-[[value,L],[value,R]])).
metarule(ext1,[P,Q,H],([P,[H,L],B]:-[[Q,L,B]])).
metarule(ext2,[P,Q,H],([P,[H,L,R],B]:-[[Q,L,R,B]])).
metarule(ext3v,[P,Q,A],([P,A,B,C]:-[[Q,B,C]])).

