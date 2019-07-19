# metagol_PLS

Case studies for the paper submitted to the ILP 2019 conference titled
__Towards meta-interpretive learning of programming language semantics__ . 

Tested with SWI Prolog.

Source files:

* __metagolPLS.pl__
   A modified version of the Metagol ILP library. The original can be found at https://github.com/metagol/metagol .

* __learn_lambda.pl__
   Specifies the BK (interpreter for the lambda calculus with simple integer arithmetic, and two auxiliary predicates, and the hypothesis space (the set of meta-rules). Included by all case studies.


The rest of the files contain tests/case studies, all of them includes the "learn_lambda.pl" file. The target predicates for each test coincides with the name of the file (without the pl extension). So to run e.g. the test of learning the semantics of pairs, run

swipl -t "learn_pair" learn_pair.pl

* __learn_pair.pl__
  Learning the semantics of pairs and fst/snd destructors.
* __learn_pair_simplified.pl__
  A simplified version, included in the paper as an example.
* __learn_list.pl__
  Learning the semantics of lists, with cons/nil constructors and head/tail destructors.
* __learn_if.pl__
  Learn the semantics of conditional expressions in the form of if(A,thenelse(B,C)).
* __learn_basic.pl__
  Choose lazy evaluation strategy by default.
* __learn_call_by_value.pl__
  Choose the call_by_value (eager) evaluation strategy if non-terminating examples requires this.
* __learn_all_atonce.pl__
  Attempt to learn four tests (call_by_value, lists, pairs, if) at once. Will not terminate in a reasonable time. Demonstrates scalability issues.
* __learn_all.pl__
  Learn the same four tests, but this time sequentially. Demonstrates the sequential learning capability of the framework.







