%% This is a copyrighted file under the BSD 3-clause licence, details of which can be found in the root directory.

:- module(metagol,[learn/2,learn/3,learn/4,learn_seq/2,learn_seq2/2, learn_task/2, pprint/1,op(950,fx,'@')]).

:- user:use_module(library(lists)).

:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(pairs)).

:- dynamic
    functional/0,
    print_ordering/0,
    min_clauses/1,
    max_clauses/1,
    max_inv_preds/1,
    max_depth/1,
    function_metavars/0,
    metarule_next_id/1,
    interpreted_bk/2,
    user:prim/1,
    user:base/1,
    user:primcall/2,
    user:extensible/1.

:- discontiguous
    user:metarule/6,
    user:metarule_init/5,
    user:prim/1,
    user:primcall/2,
    user:extensible/1,
    user:noncallable/1.

default(min_clauses(1)).
default(max_clauses(6)).
default(max_depth(inf)).
default(metarule_next_id(1)).
default(max_inv_preds(10)).

learn(Pos1,Neg1):-
    learn(Pos1,Neg1,Prog),
    pprint(Prog).

learn(Pos1,Neg1,Prog):-
    learn(Pos1,Neg1,[],Prog).

learn(Pos1,Neg1,NTerm1,Prog) :-
    maplist(atom_to_list,Pos1,Pos2),
    maplist(atom_to_list,Neg1,Neg2),
    maplist(atom_to_list,NTerm1,NTerm2),
    proveall(Pos2,Sig,Prog),
    nproveall(Neg2,Sig,Prog),
    ntermproveall(NTerm2,Sig,Prog),
    is_functional(Pos2,Sig,Prog).

learn_seq(Seq,Prog):-
    maplist(learn_task,Seq,Progs),
    flatten(Progs,Prog).

learn_task(Pos/Neg,Prog):-
    learn(Pos,Neg,Prog),!,
    maplist(assert_clause,Prog),
    assert_prims(Prog).

proveall(Atoms,Sig,Prog):-
    %target_predicate(Atoms,P/A),
    %format('% learning ~w\n',[P/A]),
    iterator(MaxN),
    %format('% clauses: ~d\n',[MaxN]),
    invented_symbols(MaxN,Sig),
    prove_examples(Atoms,Sig,_Sig,MaxN,0,_N,[],Prog).

%%
learn2((Pos1,Neg1,NTerm1),ProgIn,Prog):-
    maplist(atom_to_list,Pos1,Pos2),
    maplist(atom_to_list,Neg1,Neg2),
    maplist(atom_to_list,NTerm1,NTerm2),
    proveall2(Pos2,Sig,ProgIn,Prog),
    nproveall(Neg2,Sig,Prog),
    ntermproveall(NTerm2,Sig,Prog),
    is_functional(Pos2,Sig,Prog).

learn_seq2(T,Prog) :-
  learn_seq2(T,[],Prog).
learn_seq2([],Prog,Prog).
learn_seq2([T|Ts],ProgIn,Prog) :-
   learn2(T,ProgIn,Prog2),
   learn_seq2(Ts,Prog2,Prog).

proveall2(Atoms,Sig,ProgIn,Prog):-
    %target_predicate(Atoms,P/A),
    %format('% learning ~w\n',[P/A]),
    iterator(MaxN),
    %format('% clauses: ~d\n',[MaxN]),
    invented_symbols(MaxN,Sig),
    prove_examples(Atoms,Sig,_Sig,MaxN,0,_N,ProgIn,Prog).

%%


prove_examples([],_FullSig,_Sig,_MaxN,N,N,Prog,Prog).
prove_examples([Atom|Atoms],FullSig,Sig,MaxN,N1,N2,Prog1,Prog2):-
    get_option(max_depth(MD)),
    catch(
      prove_deduce(MD,[Atom],FullSig,Prog1),
      max_depth_reached,
      fail
    ) , !,
    is_functional([Atom],Sig,Prog1),
    prove_examples(Atoms,FullSig,Sig,MaxN,N1,N2,Prog1,Prog2).
prove_examples([Atom1|Atoms],FullSig,Sig,MaxN,N1,N2,Prog1,Prog2):-
    add_empty_path(Atom1,Atom2),
    get_option(max_depth(MD)),
    catch(
      prove(MD,[Atom2],FullSig,Sig,MaxN,N1,N3,Prog1,Prog3),
      max_depth_reached,
      fail
    ),
    prove_examples(Atoms,FullSig,Sig,MaxN,N3,N2,Prog3,Prog2).

prove_deduce(MD,Atoms1,Sig,Prog):-
    maplist(add_empty_path,Atoms1,Atoms2),
    length(Prog,N),
    prove(MD,Atoms2,Sig,_,N,N,N,Prog,Prog).

prove(_MaxD,[],_FullSig,_Sig,_MaxN,N,N,Prog,Prog).
prove(MaxD,[Atom|Atoms],FullSig,Sig,MaxN,N1,N2,Prog1,Prog2):-
    prove_aux(MaxD,Atom,FullSig,Sig,MaxN,N1,N3,Prog1,Prog3),
    prove(MaxD,Atoms,FullSig,Sig,MaxN,N3,N2,Prog3,Prog2).

count_depth(inf,inf) :- !.
count_depth(D1,D2) :- (succ(D2,D1),!) ; throw(max_depth_reached).

prove_aux(_MaxD,'@'(Atom),_FullSig,_Sig,_MaxN,N,N,Prog,Prog):-!,
    user:call(Atom).

%% prove primitive atom
prove_aux(_MaxD,p(prim,P,A,Args,_Atom,_Path),_FullSig,_Sig,_MaxN,N,N,Prog,Prog):-
    (nonvar(P)-> (user:prim(P/A),!); true),
    ( get_option(function_metavars) ->
      (
        maplist(list2term,Args,TArgs),
        copy_term(TArgs,TArgs2),
        (var(P) ->
          (user:primcall(P,TArgs2), \+ user:noncallable(P/A)) ;
          user:primcall(P,TArgs2) ),
        maplist(term2list,TArgs2,Args)
       ) ; user:primcall(P,Args)
     ).

%% use interpreted BK - can we skip this if no interpreted_bk?
%% only works if interpreted/2 is below the corresponding definition
prove_aux(MaxD,p(inv,P,A,_Args,Atom,Path),FullSig,Sig,MaxN,N1,N2,Prog1,Prog2):-
    
    (var(P) -> 
        (interpreted_bk(Atom,Body1), \+ user:noncallable(P/A));
         interpreted_bk(Atom,Body1) ),
    add_path_to_body(Body1,[Atom|Path],Body2),
    count_depth(MaxD,M),
    prove(M,Body2,FullSig,Sig,MaxN,N1,N2,Prog1,Prog2).

%% use existing abduction
prove_aux(MaxD,p(inv,P,A,_Args,Atom,Path),FullSig,Sig1,MaxN,N1,N2,Prog1,Prog2):-
    select_lower(P,A,FullSig,Sig1,Sig2),
    (var(P) -> 
        (member(sub(Name,P,A,MetaSub),Prog1), \+ noncallable(P/A)) ;
         member(sub(Name,P,A,MetaSub),Prog1) ),
    user:metarule_init(Name,MetaSub,(Atom:-Body1),Recursive,[Atom|Path]),
    (Recursive==true -> \+memberchk(Atom,Path); true),
    count_depth(MaxD,M),
    prove(M,Body1,FullSig,Sig2,MaxN,N1,N2,Prog1,Prog2).

%% new abduction
prove_aux(MaxD,p(inv,P,A,_Args,Atom,Path),FullSig,Sig1,MaxN,N1,N2,Prog1,Prog2):-
    N1 < MaxN,
    bind_lower(P,A,FullSig,Sig1,Sig2),
    user:metarule(Name,MetaSub,(Atom:-Body1),FullSig,Recursive,[Atom|Path]),
    (Recursive==true -> \+memberchk(Atom,Path); true),
    check_new_metasub(Name,P,A,MetaSub,Prog1),
    succ(N1,N3),
    count_depth(MaxD,M),
    prove(M,Body1,FullSig,Sig2,MaxN,N3,N2,[sub(Name,P,A,MetaSub)|Prog1],Prog2).

add_empty_path([P|Args],p(inv,P,A,Args,[P|Args],[])):-
    size(Args,A).

select_lower(P,A,FullSig,_Sig1,Sig2):-
    nonvar(P),!,
    append(_,[sym(P,A,_)|Sig2],FullSig),!.

select_lower(P,A,_FullSig,Sig1,Sig2):-
    append(_,[sym(P,A,U)|Sig2],Sig1),
    (var(U)-> !,fail;true ).

bind_lower(P,A,FullSig,_Sig1,Sig2):-
    nonvar(P),!,
    append(_,[sym(P,A,_)|Sig2],FullSig),!.

bind_lower(P,A,_FullSig,Sig1,Sig2):-
    append(_,[sym(P,A,U)|Sig2],Sig1),
    (var(U)-> U = 1,!;true).

check_new_metasub(Name,P,A,MetaSub,Prog):-
    memberchk(sub(Name,P,A,_),Prog),!,
    last(MetaSub,X),
    when(nonvar(X),\+memberchk(sub(Name,P,A,MetaSub),Prog)).
check_new_metasub(_Name,_P,_A,_MetaSub,_Prog).

size([],0) :-!.
size([_],1) :-!.
size([_,_],2) :-!.
size([_,_,_],3) :-!.
size(L,N):- !,
  length(L,N).

nproveall([],_PS,_Prog):- !.
nproveall([Atom|Atoms],PS,Prog):-
    get_option(max_depth(MD)),
    catch(
      \+ prove_deduce(MD,[Atom],PS,Prog),
      max_depth_reached,
      fail	      
    ),
    nproveall(Atoms,PS,Prog).

terminates(MD,Atom,PS,Prog) :-
	catch(
	  (prove_deduce(MD,[Atom],PS,Prog); true),
          max_depth_reached,
	  fail
	).

ntermproveall([],_PS,_Prog):- !.
ntermproveall([Atom|Atoms],PS,Prog) :-
    get_option(max_depth(MD)),
    \+ terminates(MD,Atom,PS,Prog),
    ntermproveall(Atoms,PS,Prog).


iterator(N):-
    get_option(min_clauses(MinN)),
    get_option(max_clauses(MaxN)),
    between(MinN,MaxN,N).

target_predicate([[P|Args]|_],P/A):-
    length(Args,A).

invented_symbols(MaxClauses,Sig):-
    NumSymbols is MaxClauses-1,
    get_option(max_inv_preds(MaxInvPreds)),
    M is min(NumSymbols,MaxInvPreds),
    findall(sym(InvSym1,_Artiy1,_Used1),(between(1,M,I),atomic_list_concat(['pred_',I],InvSym1)),Sig1),
    findall(sym(InvSym2,Arity2,_Used2),extensible(InvSym2/Arity2),Sig2),
    append(Sig2,Sig1,Sig).


pprint(Prog1):-
    map_list_to_pairs(arg(2),Prog1,Pairs),
    keysort(Pairs,Sorted),
    pairs_values(Sorted,Prog2),
    maplist(pprint_clause,Prog2).

pprint_clause(Sub):-
    construct_clause(Sub,Clause),
    numbervars(Clause,0,_),
    format('~q.~n',[Clause]).

%% construct clause is horrible and needs refactoring
construct_clause(sub(Name,_,_,MetaSub),Clause):-
    user:metarule_init(Name,MetaSub,(HeadList:-BodyAsList1),_,_),
    add_path_to_body(BodyAsList2,_,BodyAsList1),
    %atom_to_list(Head,HeadList),
    list_to_atom(HeadList,Head),
    (BodyAsList2 == [] ->Clause=Head;(pprint_list_to_clause(BodyAsList2,Body),Clause = (Head:-Body))).

pprint_list_to_clause(List1,Clause):-
    atomsaslists_to_atoms(List1,List2),
    list_to_clause(List2,Clause).

atomsaslists_to_atoms([],[]).
atomsaslists_to_atoms(['@'(Atom)|T1],Out):- !,
    (get_option(print_ordering) -> Out=[Atom|T2]; Out=T2),
    atomsaslists_to_atoms(T1,T2).
atomsaslists_to_atoms([AtomAsList|T1],[Atom|T2]):-
    list_to_atom(AtomAsList,Atom),
    atomsaslists_to_atoms(T1,T2).

list_to_clause([Atom],Atom):-!.
list_to_clause([Atom|T1],(Atom,T2)):-!,
    list_to_clause(T1,T2).

list_to_atom(AtomList,Atom):-
    list2term(AtomList,Atom).
%    Atom =..AtomList.
atom_to_list(Atom,AtomList):-
    term2list(Atom,AtomList).
	%    Atom =..AtomList.

is_functional(Atoms,Sig,Prog):-
    (get_option(functional) -> is_functional_aux(Atoms,Sig,Prog); true).
is_functional_aux([],_Sig,_Prog).
is_functional_aux([Atom|Atoms],Sig,Prog):-
    user:func_test(Atom,Sig,Prog),
    is_functional_aux(Atoms,Sig,Prog).

get_option(Option):-call(Option), !.
get_option(Option):-default(Option).

set_option(Option):-
    functor(Option,Name,Arity),
    functor(Retract,Name,Arity),
    retractall(Retract),
    assert(Option).

gen_metarule_id(Id):-
    get_option(metarule_next_id(Id)),
    succ(Id,IdNext),
    set_option(metarule_next_id(IdNext)).

user:term_expansion(interpreted(P/A),L2):-
    functor(Head,P,A),
    findall((Head:-Body),user:clause(Head,Body),L1),
    maplist(convert_to_interpreted,L1,L2).

convert_to_interpreted((Head:-true),metagol:(interpreted_bk(HeadAsList,[]))):-!,
    ho_atom_to_list(Head,HeadAsList).
convert_to_interpreted((Head:-Body),metagol:(interpreted_bk(HeadAsList,BodyList2))):-
    ho_atom_to_list(Head,HeadAsList),
    clause_to_list(Body,BodyList1),
    maplist(ho_atom_to_list,BodyList1,BodyList2).

term2list(T,L) :- ( get_option(function_metavars) -> term2listR(T,L) ; T =.. L).

list2term(L,T) :- ( get_option(function_metavars) -> list2termR(L,T) ; T =.. L).


term2listR(T,T)  :- var(T), !.
term2listR(T,T)  :- atomic(T), !.
term2listR(@T,T) :- !.
term2listR(T,[F|Ls]) :- 
  T =.. [F|Args],
  maplist(term2listR,Args,Ls).
list2termR(T,T) :- \+ is_list(T), !.
list2termR(L,T) :-
  maplist(list2termR,L,Ts),
  T =.. Ts.

user:term_expansion(prim(P/A),[user:prim(P/A),user:(primcall(P,Args):-user:Call)]):-
    functor(Call,P,A),
    Call =.. [P|Args].

user:term_expansion(base(P/A),[user:base(P/A),user:(primcall(P,Args):-user:Call)]):-
    functor(Call,P,A),
    Call =.. [P|Args].



user:term_expansion(metarule(MetaSub,Clause),Asserts):-
    get_asserts(_Name,MetaSub,Clause,_,_PS,Asserts).
user:term_expansion(metarule(Name,MetaSub,Clause),Asserts):-
    get_asserts(Name,MetaSub,Clause,_,_PS,Asserts).
user:term_expansion((metarule(MetaSub,Clause):-Body),Asserts):-
    get_asserts(_Name,MetaSub,Clause,Body,_PS,Asserts).
user:term_expansion((metarule(Name,MetaSub,Clause):-Body),Asserts):-
    get_asserts(Name,MetaSub,Clause,Body,_PS,Asserts).
user:term_expansion((metarule(Name,MetaSub,Clause,PS):-Body),Asserts):-
    get_asserts(Name,MetaSub,Clause,Body,PS,Asserts).

get_asserts(Name,MetaSub,Clause1,MetaBody,PS,[MRule,metarule_init(AssertName,MetaSub,Clause2,Recursive,Path)]):-
    Clause1 = (Head:-Body1),
    Head = [P|_],
    is_recursive(Body1,P,Recursive),
    add_path_to_body(Body1,Path,Body3),
    Clause2 = (Head:-Body3),
    (var(Name)->gen_metarule_id(AssertName);AssertName=Name),
    (var(MetaBody) ->
        MRule = metarule(AssertName,MetaSub,Clause2,PS,Recursive,Path);
        MRule = (metarule(AssertName,MetaSub,Clause2,PS,Recursive,Path):-MetaBody)).

is_recursive([],_,false).
is_recursive([[Q|_]|_],P,true):-
    Q==P,!.
is_recursive([_|T],P,Res):-
    is_recursive(T,P,Res).

add_path_to_body([],_Path,[]).
add_path_to_body(['@'(Atom)|Atoms],Path,['@'(Atom)|Rest]):-
    add_path_to_body(Atoms,Path,Rest).
add_path_to_body([[P|Args]|Atoms],Path,[p(_,P,A,Args,[P|Args],Path)|Rest]):-
    size(Args,A),
    add_path_to_body(Atoms,Path,Rest).

assert_program(Prog):-
    maplist(assert_clause,Prog).

assert_clause(Sub):-
    construct_clause(Sub,Clause),
    assert(user:Clause).

assert_prims(Prog):-
    findall(P/A,(member(sub(_Name,P,A,_MetaSub),Prog)),Prims),!,
    list_to_set(Prims,PrimSet),
    maplist(assert_prim,PrimSet).

assert_prim(Prim):-
    prim_asserts(Prim,Asserts),
    maplist(assertz,Asserts).

prim_asserts(P/A,[user:prim(P/A), user:(primcall(P,Args):-user:Call)]):-
    functor(Call,P,A),
    %term2list(Call,[P|Args]).
    Call =.. [P|Args].

clause_to_list((Atom,T1),[Atom|T2]):-
    clause_to_list(T1,T2).
clause_to_list(Atom,[Atom]):- !.

ho_atom_to_list(Atom,T):-
    term2list(Atom,AtomList),
    %Atom=..AtomList,
    AtomList = [call|T],!.
ho_atom_to_list(Atom,AtomList):-
    term2list(Atom,AtomList).
    %Atom=..AtomList.
