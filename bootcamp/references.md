# Research references and connections to the code

[Bootcamp](README.md) / Research references

Use this page when a tutorial has introduced an algorithm and you want to
understand why it works. Read the relevant tutorial's small example first,
then choose a paper from the reading map and follow its code connection.
The bibliography is a reference to consult by topic; understanding all of it
is not a prerequisite for working through the guide.

Research papers often describe a **calculus**, a collection of inference rules
stating what follows from which premises. A **decision procedure** organizes
reasoning into an algorithm that settles inputs in a specified fragment.
An implementation adds representations, scheduling and optimizations around
those ideas. Each entry separates the paper from the current code so you can
follow that translation. CVC4 is cvc5's predecessor, so older CVC4 papers can
explain ideas still used by current components.

This bibliography connects **92 publications** to components in the
pinned cvc5 `main` source. Start with [CVC5-2022](#cvc5-2022) for the system,
[SMT-TUTORIAL-2024](#smt-tutorial-2024) for SMT foundations, and the topic you
are changing. Each entry links the paper, identifies a concrete implementation
reading stop, and explains which part of the paper that code helps illuminate.

## Scope and provenance

The literature pass was made on **2026-09-18** against the tutorials’
[source baseline](source-baseline.md). Inclusion requires an identifiable
algorithm, representation, semantic contract or exported proof format in that
source. A paper’s use of CVC4/cvc5, or its presence in a project publication
list, is insufficient. Research-only extensions and application papers without
such a connection are excluded. Where only part of a paper maps to `main`,
the connection note names that part explicitly.

Discovery sources were the [CVC4 publication catalog](https://cvc4.github.io/publications.html),
the [cvc5 publications page](https://cvc5.github.io/publications.html), and the
publication lists of [Clark Barrett](https://theory.stanford.edu/~barrett/pubs/index.html),
[Andrew Reynolds](https://homepage.divms.uiowa.edu/~ajreynol/),
[Mathias Preiner](https://cs.stanford.edu/~preiner/publications.html),
[Haniel Barbosa](https://hanielbarbosa.com/) and [Hans-Jörg Schurr](https://schurr.io/).
These catalogs are discovery aids, not assertions that every listed prototype
was merged. Primary manuscripts and publisher records supply the paper links
and publication metadata below.

Historical CVC4 papers remain when their calculus or implementation component
has a concrete successor here. Selected external foundations remain where
they explain a current algorithm or semantics. Conference, workshop and
journal versions are separate publications, not necessarily separate
algorithms. Paper experiments, option defaults and completeness assumptions
must not be transferred to the current implementation without checking them.

## Reading map

The capitalized keys, such as `CVC5-2022`, are stable labels used by links
throughout the chapters. Each entry gives publication information, a **Main
connection** pointing to source files, and a reading note explaining what to
look for there. Start with the note to decide whether the paper addresses the
question you are investigating.

| Literature topic | Tutorial |
| --- | --- |
| [Systems and architectural background](#systems-and-architectural-background) | [The path of a query](query.md) |
| [Theory combination and extensions](#theory-combination-and-extensions) | [The common theory interface](theory-development/interface.md) |
| [Arrays](#arrays) | [Arrays](theory-development/arrays.md) |
| [Datatypes and codatatypes](#datatypes-and-codatatypes) | [Datatypes](theory-development/datatypes.md) |
| [Arithmetic](#arithmetic) | [Arithmetic](theory-development/arithmetic.md) |
| [Bit-vectors](#bit-vectors) | [Bit-vectors](theory-development/bit-vectors.md) |
| [Floating point](#floating-point) | [Floating point](theory-development/floating-point.md) |
| [Finite fields](#finite-fields) | [Finite fields](theory-development/finite-fields.md) |
| [Strings and sequences](#strings-and-sequences) | [Strings and sequences](theory-development/strings.md) |
| [Sets relations bags and tables](#sets-relations-bags-and-tables) | [Sets and relations](theory-development/sets.md) |
| [Separation logic](#separation-logic) | [Separation logic](theory-development/separation-logic.md) |
| [Quantifiers and higher-order reasoning](#quantifiers-and-higher-order-reasoning) | [Quantifiers](theory-development/quantifiers.md) |
| [Synthesis and abduction](#synthesis-and-abduction) | [Synthesis](theory-development/quantifiers.md#synthesis) |
| [Rewriting and proof production](#rewriting-and-proof-production) | [Making and investigating a change](development.md) |
| [Solver integration and configuration](#solver-integration-and-configuration) | [Development workflow](development.md) |

For a reading exercise, take the rule used in a tutorial input, find its side
conditions in the paper, and inspect the linked implementation for where those
conditions are checked and explained. Then change the input so a side condition
fails. An inductive datatype cycle, a set union and a bag union each make a
small, concrete example; none exercises an entire paper’s procedure.

## Systems and architectural background

### CVC4-2011

[CVC4](https://cvc4.github.io/publications/2011/BCD+11.pdf).
Clark Barrett, Christopher L. Conway, Morgan Deters, Liana Hadarean, Dejan Jovanović, Tim King,
Andrew Reynolds, Cesare Tinelli.
*CAV, 2011.*

**Main connection:** [solver_engine.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/solver_engine.h), [theory_engine.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/theory_engine.cpp).

The SAT/theory architecture survives in SolverEngine and TheoryEngine. Use the system paper for
the division of responsibilities, then the query tutorial for current ownership and callback
order; historical class names and defaults are not a description of this snapshot.
Read with [The path of a query](query.md).

### CVC5-2022

[cvc5: A Versatile and Industrial-Strength SMT Solver](https://cs.stanford.edu/~preiner/publications/2022/BarbosaBBKLMMMN-TACAS22.pdf).
Haniel Barbosa, Clark Barrett, Martin Brain, Gereon Kremer, Hanna Lachnitt, Makai Mann,
Abdalrhman Mohamed, Mudathir Mohamed, Aina Niemetz, Andres Nötzli, Alex Ozdemir, Mathias
Preiner, Andrew Reynolds, Ying Sheng, Cesare Tinelli, Yoni Zohar.
*TACAS, 2022.*

**Main connection:** [solver_engine.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/solver_engine.h), [theory_engine.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/theory_engine.cpp).

The SAT/theory architecture survives in SolverEngine and TheoryEngine. Use the system paper for
the division of responsibilities, then the query tutorial for current ownership and callback
order; historical class names and defaults are not a description of this snapshot.
Read with [The path of a query](query.md).

### SMT-TUTORIAL-2024

[Satisfiability Modulo Theories: A Beginner's Tutorial](https://cs.stanford.edu/~preiner/publications/2024/BarrettTBNPRZ-FM24.pdf).
Clark Barrett, Cesare Tinelli, Haniel Barbosa, Aina Niemetz, Mathias Preiner, Andrew Reynolds,
Yoni Zohar.
*FM tutorial, 2024.*

**Main connection:** [linear_arith.smt2](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/examples/api/smtlib/linear_arith.smt2), [theory_engine.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/theory_engine.cpp).

The linear-arithmetic example and theory-engine boundary make the tutorial’s SMT syntax,
satisfiability and theory-combination concepts concrete. Read this before tracing the C++ query
path.
Read with [The path of a query](query.md).

## Theory combination and extensions

### SHARING-2011

[Sharing is caring: Combination of theories](https://cvc4.github.io/publications/2011/JB11-FroCoS.pdf).
Dejan Jovanović, Clark Barrett.
*FroCoS, 2011.*

**Main connection:** [combination_care_graph.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/combination_care_graph.cpp).

CombinationCareGraph obtains care pairs and introduces equality splits on shared terms. Relate
the paper’s relevant equality arrangements to the common-interface example with f(x) and f(y).
The journal paper expands the conference account.
Read with [The common theory interface](theory-development/interface.md).

### CAREFUL-2013

[Being careful about theory combination](https://cvc4.github.io/publications/2013/JB13.pdf).
Dejan Jovanovic, Clark Barrett.
*Formal Methods in System Design, 2013.*

**Main connection:** [combination_care_graph.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/combination_care_graph.cpp).

CombinationCareGraph obtains care pairs and introduces equality splits on shared terms. Relate
the paper’s relevant equality arrangements to the common-interface example with f(x) and f(y).
The journal paper expands the conference account.
Read with [The common theory interface](theory-development/interface.md).

### POLITE-2010

[Polite Theories Revisited](https://cvc4.github.io/publications/2010/JB10-LPAR.pdf).
Dejan Jovanović, Clark Barrett.
*LPAR, 2010.*

**Main connection:** [theory_datatypes.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/datatypes/theory_datatypes.cpp), [combination_care_graph.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/combination_care_graph.cpp).

The connection is the combination contract for datatype models with fields owned by other
theories. Read the witness and domain-size conditions beside constructor expansion and shared-
term care pairs; an equality-engine callback alone does not establish those mathematical
conditions.
Read with [The common theory interface](theory-development/interface.md).

### EXTENSIONS-2017

[Designing theory solvers with extensions](https://cvc4.github.io/publications/2017/RTJ+17.pdf).
Andrew Reynolds, Cesare Tinelli, Dejan Jovanović, Clark Barrett.
*FroCoS, 2017.*

**Main connection:** [nonlinear_extension.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arith/nl/nonlinear_extension.h), [monomial_bounds_check.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arith/nl/ext/monomial_bounds_check.h).

These headers explicitly relate nonlinear refinement to the paper. Follow an abstract candidate
through a monomial bound check to a valid lemma excluding that candidate; the arithmetic
tutorial’s x = 2, x*x = 3 variation isolates this obligation.
Read with [The common theory interface](theory-development/interface.md).

## Arrays

### ARRAYS-2001

[A Decision Procedure for an Extensional Theory of Arrays](https://theory.stanford.edu/~barrett/pubs/SBDL01.pdf).
Aaron Stump, Clark W. Barrett, David L. Dill, and Jeremy Levitt.
*LICS, 2001.*

**Main connection:** [theory_arrays.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arrays/theory_arrays.cpp).

The extensional-array axioms remain visible in read-over-write consequences and the disequality
witness generated by notifyFact. This is a connection to the retained theory calculus, not a
claim that the original CVC search algorithm is the current implementation.
Read with [Arrays](theory-development/arrays.md).

### WEAK-ARRAYS-2014

[Weakly Equivalent Arrays](https://ceur-ws.org/Vol-1163/paper-06.pdf).
Jürgen Christ, Jochen Hoenicke.
*SMT workshop, 2014.*

**Main connection:** [theory_arrays.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arrays/theory_arrays.cpp).

The arraysWeakEquivalence route maintains weak-equivalence links and explains paths between
reads. Follow that route explicitly: the option is off by default at this source baseline, so
the paper does not describe every default array check.
Read with [Arrays](theory-development/arrays.md).

### ARRAYS-GENERALIZED-2009

[Generalized, Efficient Array Decision Procedures](https://www.microsoft.com/en-us/research/publication/generalized-efficient-array-decision-procedures/).
Leonardo de Moura, Nikolaj Bjørner.
*FMCAD, 2009.*

**Main connection:** [theory_arrays.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arrays/theory_arrays.cpp).

Algorithmic background for lazy read-over-write and extensionality reasoning: compare the
paper’s axiom instances with queued row lemmas and extensionality witnesses. The tutorial’s
unequal-index input needs one such read-over-write instance.
Read with [Arrays](theory-development/arrays.md).

## Datatypes and codatatypes

### CODATATYPES-2015

[A Decision Procedure for (Co)datatypes in SMT Solvers](https://cvc4.github.io/publications/2015/RB15.pdf).
Andrew Reynolds, Jasmin Christian Blanchette.
*CADE, 2015.*

**Main connection:** [theory_datatypes.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/datatypes/theory_datatypes.cpp).

Constructor clashes, injectivity, cycle checks and codatatype model construction implement the
corresponding parts of this calculus. Compare the tutorial’s impossible inductive cycle with a
permitted coinductive cycle. These conference, short and journal accounts concern the same line
of work.
Read with [Datatypes](theory-development/datatypes.md).

### CODATATYPES-2017

[A decision procedure for (co)datatypes in SMT solvers](https://cvc4.github.io/publications/2017/RB17.pdf).
Andrew Reynolds, Jasmin Christian Blanchette.
*Journal of Automated Reasoning, 2017.*

**Main connection:** [theory_datatypes.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/datatypes/theory_datatypes.cpp).

Constructor clashes, injectivity, cycle checks and codatatype model construction implement the
corresponding parts of this calculus. Compare the tutorial’s impossible inductive cycle with a
permitted coinductive cycle. These conference, short and journal accounts concern the same line
of work.
Read with [Datatypes](theory-development/datatypes.md).

### SHARED-SELECTORS-2018

[Datatypes with shared selectors](https://cvc4.github.io/publications/2018/RVB+18.pdf).
Andrew Reynolds, Arjun Viswanathan, Haniel Barbosa, Cesare Tinelli, Clark Barrett.
*IJCAR, 2018.*

**Main connection:** [dtype.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/expr/dtype.cpp), [dtype_cons.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/expr/dtype_cons.cpp).

Shared-selector construction and per-constructor selector mappings give the direct
implementation connection. Trace an internal selector back to its constructor field before
applying a selector equation; sharing representation does not identify arbitrary surface
selectors.
Read with [Datatypes](theory-development/datatypes.md).

### DATATYPE-POLITENESS-2020

[Politeness for the Theory of Algebraic Datatypes](https://cvc4.github.io/publications/2020/SZR+20.pdf).
Ying Sheng, Yoni Zohar, Christophe Ringeissen, Jane Lange, Pascal Fontaine, Clark Barrett.
*IJCAR, 2020.*

**Main connection:** [theory_datatypes.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/datatypes/theory_datatypes.cpp).

Read the combination result beside computeCareGraph and collectModelValues: constructor
skeletons constrain both datatype values and field-theory values. The paper supplies the
mathematical conditions for compatible models, not an automatic property of the callback
interface.
Read with [Datatypes](theory-development/datatypes.md).

### DATATYPE-POLITENESS-2022

[Polite Combination of Algebraic Datatypes](https://doi.org/10.1007/s10817-022-09625-3).
Ying Sheng, Yoni Zohar, Christophe Ringeissen, Jane Lange, Pascal Fontaine, and Clark Barrett.
*Journal of Automated Reasoning, 2022.*

**Main connection:** [theory_datatypes.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/datatypes/theory_datatypes.cpp).

Read the combination result beside computeCareGraph and collectModelValues: constructor
skeletons constrain both datatype values and field-theory values. The paper supplies the
mathematical conditions for compatible models, not an automatic property of the callback
interface.
Read with [Datatypes](theory-development/datatypes.md).

### CODATATYPES-IJCAI-2016

[A Decision Procedure for (Co)Datatypes in SMT Solvers](https://homepage.divms.uiowa.edu/~ajreynol/ijcai16.pdf).
Andrew Reynolds, and Jasmin Christian Blanchette.
*IJCAI, 2016.*

**Main connection:** [theory_datatypes.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/datatypes/theory_datatypes.cpp).

Constructor clashes, injectivity, cycle checks and codatatype model construction implement the
corresponding parts of this calculus. Compare the tutorial’s impossible inductive cycle with a
permitted coinductive cycle. These conference, short and journal accounts concern the same line
of work.
Read with [Datatypes](theory-development/datatypes.md).

### DATATYPES-2007

[An Abstract Decision Procedure for a Theory of Inductive Data Types](https://theory.stanford.edu/~barrett/pubs/BST07-JSAT.pdf).
Clark Barrett, Igor Shikanian, and Cesare Tinelli.
*Journal on Satisfiability, Boolean Modeling and Computation, 2007.*

**Main connection:** [theory_datatypes.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/datatypes/theory_datatypes.cpp).

The retained inductive rules include constructor disjointness, injectivity and acyclicity. Use
the tutorial’s list cycle to read those rules; the later (co)datatype papers cover the
coinductive extension of the current solver.
Read with [Datatypes](theory-development/datatypes.md).

## Arithmetic

### SIMPLEX-SOI-2013

[Simplex with sum of infeasibilities for SMT](https://cvc4.github.io/publications/2013/KBD13.pdf).
Timothy King, Clark Barrett, Bruno Dutertre.
*FMCAD, 2013.*

**Main connection:** [soi_simplex.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arith/linear/soi_simplex.h).

SumOfInfeasibilitiesSPD implements the sum-of-infeasibilities simplex strategy. Connect
infeasible basic variables, the objective and pivot selection to the explained bound conflict
in the arithmetic tutorial.
Read with [Arithmetic](theory-development/arithmetic.md).

### ARITH-LP-MIP-2014

[Leveraging linear and mixed integer programming for SMT](https://cvc4.github.io/publications/2014/KBT14.pdf).
Tim King, Clark Barrett, Cesare Tinelli.
*FMCAD, 2014.*

**Main connection:** [approx_simplex.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arith/linear/approx_simplex.h).

ApproximateSimplex is the interface to approximate LP/MIP assistance. Read the paper with the
distinction between an approximate suggestion and an exact rational justification; the
tutorial’s rationally feasible but integer-infeasible variant exposes the integrality
obligation.
Read with [Arithmetic](theory-development/arithmetic.md).

### NRA-COOPERATION-2022

[Cooperating Techniques for Solving Nonlinear Real Arithmetic in the cvc5 SMT Solver](https://homepage.divms.uiowa.edu/~ajreynol/ijcar22b.pdf).
Gereon Kremer, Andrew Reynolds, Clark Barrett, Cesare Tinelli.
*IJCAR system description, 2022.*

**Main connection:** [nonlinear_extension.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arith/nl/nonlinear_extension.cpp).

NonlinearExtension coordinates nonlinear subsolvers and candidate-model refinement. Relate a
technique’s success, refinement lemma or incomplete result to the return path; the paper’s
experimental configuration does not set current defaults.
Read with [Arithmetic](theory-development/arithmetic.md).

### NRA-PROOFS-2026

[Formalization of a Proof Calculus for Incremental Linearization for Satisfiability Modulo Nonlinear Arithmetic and Transcendental Functions](https://hanielbarbosa.com/papers/2026cpp.pdf).
Tomaz Mascarenhas, Harun Khan, Abdalrhman Mohamed, Andrew Reynolds, Haniel Barbosa, Clark W.
Barrett, and Cesare Tinelli.
*CPP, 2026.*

**Main connection:** [proof_checker.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arith/nl/ext/proof_checker.cpp), [proof_checker.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arith/nl/transcendental/proof_checker.cpp).

The connection is the incremental-linearization and transcendental proof rules checked in these
files. Compare a generated bound lemma with its rule premises. The paper’s external
formalization is separate from these C++ rule checkers.
Read with [Arithmetic](theory-development/arithmetic.md).

### CAC-2021

[Deciding the Consistency of Non-Linear Real Arithmetic Constraints with a Conflict Driven Search Using Cylindrical Algebraic Coverings](https://arxiv.org/abs/2003.05633).
Erika Ábrahám, James H. Davenport, Matthew England, Gereon Kremer.
*Journal of Logical and Algebraic Methods in Programming 119; preprint 2020, 2021.*

**Main connection:** [cdcac.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arith/nl/coverings/cdcac.h).

CDCAC explicitly cites this work. Read its interval exclusions and coverings as a separate
nonlinear route from incremental linearization, then inspect how a conflict or candidate
assignment returns to NonlinearExtension.
Read with [Arithmetic](theory-development/arithmetic.md).

### TRANSCENDENTAL-2017

[Satisfiability Modulo Transcendental Functions via Incremental Linearization](https://arxiv.org/abs/1801.08723).
Alessandro Cimatti, Alberto Griggio, Ahmed Irfan, Marco Roveri, Roberto Sebastiani.
*CADE; author preprint posted 2018, 2017.*

**Main connection:** [taylor_generator.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arith/nl/transcendental/taylor_generator.h), [nonlinear_extension.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arith/nl/nonlinear_extension.h).

These headers cite the incremental-linearization approach. Taylor bounds and other valid
inequalities refine abstract transcendental values; a polynomial-only example does not exercise
these steps.
Read with [Arithmetic](theory-development/arithmetic.md).

### SIMPLEX-2006

[A Fast Linear-Arithmetic Solver for DPLL(T)](https://link.springer.com/chapter/10.1007/11817963_11).
Bruno Dutertre, Leonardo de Moura.
*CAV, 2006.*

**Main connection:** [linear_equality.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arith/linear/linear_equality.h).

LinearEquality explicitly cites the paper for tableau updates. Follow assignment changes, bound
violations and pivot repair; strict bounds additionally use the implementation’s infinitesimal
representation.
Read with [Arithmetic](theory-development/arithmetic.md).

## Bit-vectors

### BV-EAGER-LAZY-2014

[A tale of two solvers: Eager and lazy approaches to bit-vectors](https://cvc4.github.io/publications/2014/HBJ+14.pdf).
Liana Hadarean, Clark Barrett, Dejan Jovanović, Cesare Tinelli, Kshitij Bansal.
*CAV, 2014.*

**Main connection:** [theory_bv.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/bv/theory_bv.cpp), [bitblaster.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/bv/bitblast/bitblaster.h).

The paper explains eager versus lazy translation tradeoffs retained in the bit-vector solving
architecture. Follow the selected current backend before transferring a historical observation;
internal versus external SAT routing is a separate choice.
Read with [Bit-vectors](theory-development/bit-vectors.md).

### BV-INVERT-2018

[Solving quantified bit-vectors using invertibility conditions](https://cvc4.github.io/publications/2018/NPR+18.pdf).
Aina Niemetz, Mathias Preiner, Andrew Reynolds, Clark Barrett, Cesare Tinelli.
*CAV, 2018.*

**Main connection:** [ceg_bv_instantiator.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/cegqi/ceg_bv_instantiator.h), [bv_inverter.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/bv_inverter.h).

BvInstantiator explicitly links its construction to the invertibility-condition approach.
BvInverter constructs conditions and terms for solving a selected variable. This is quantified
reasoning; the ground overflow example alone does not exercise it.
Read with [Bit-vectors](theory-development/bit-vectors.md).

### BV-INVERT-2021

[On Solving Quantified Bit-Vector Constraints using Invertibility Conditions](https://cs.stanford.edu/~preiner/publications/2021/NiemetzPreinerReynoldsBarrettTinelli-FMSD21.pdf).
Aina Niemetz, Mathias Preiner, Andrew Reynolds, Clark Barrett, Cesare Tinelli.
*Formal Methods in System Design, 2021.*

**Main connection:** [ceg_bv_instantiator.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/cegqi/ceg_bv_instantiator.h), [bv_inverter.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/bv_inverter.h).

BvInstantiator explicitly links its construction to the invertibility-condition approach.
BvInverter constructs conditions and terms for solving a selected variable. This is quantified
reasoning; the ground overflow example alone does not exercise it.
Read with [Bit-vectors](theory-development/bit-vectors.md).

### INT-BLASTING-2022

[Bit-Precise Reasoning via Int-Blasting](https://cs.stanford.edu/~preiner/publications/2022/ZoharIMNNPRBT-VMCAI22.pdf).
Yoni Zohar, Ahmed Irfan, Makai Mann, Aina Niemetz, Andres Nötzli, Mathias Preiner, Andrew
Reynolds, Clark Barrett, Cesare Tinelli.
*VMCAI, 2022.*

**Main connection:** [int_blaster.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/bv/int_blaster.h).

IntBlaster translates fixed-width bit-vector operations into integer constraints. For the
tutorial’s four-bit increment, identify the range and modulo-16 constraints that preserve
overflow; ordinary unbounded addition is insufficient.
Read with [Bit-vectors](theory-development/bit-vectors.md).

### BV-PARAMETRIC-2025

[Bit-Precise Reasoning with Parametric Bit-Vectors](https://drops.dagstuhl.de/storage/00lipics/lipics-vol341-sat2025/LIPIcs.SAT.2025.4/LIPIcs.SAT.2025.4.pdf).
Zvika Berger, Yoni Zohar, Aina Niemetz, Mathias Preiner, Andrew Reynolds, Clark Barrett, Cesare
Tinelli.
*SAT, 2025.*

**Main connection:** [piand_solver.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arith/nl/piand_solver.h), [pow2_solver.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arith/nl/pow2_solver.h).

The retained connection is specifically the lazy integer backend for parametric integer AND
(PIAND) and powers of two. PIAndSolver refines candidate values using range and bitwise
constraints. The paper’s parametric-bit-vector front end is not established by these files;
ordinary SMT-LIB bit-vector sorts in the tutorial still have concrete widths.
Read with [Bit-vectors](theory-development/bit-vectors.md).

### BV-ABSTRACTION-2024

[Scalable Bit-Blasting with Abstractions](https://cs.stanford.edu/~preiner/publications/2024/NiemetzPZ-CAV24.pdf).
Aina Niemetz, Mathias Preiner, Yoni Zohar.
*CAV, 2024.*

**Main connection:** [abstraction_module.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/bv/abstract/abstraction_module.h).

AbstractionModule explicitly cites this algorithm, originally evaluated in Bitwuzla. Compare
its abstract multiplication/division operators, refinement lemmas and exact fallback. The
tutorial’s small increment is not a test of these expensive-operator abstractions.
Read with [Bit-vectors](theory-development/bit-vectors.md).

## Floating point

### FP-SEMANTICS-2015

[An Automatable Formal Semantics for IEEE-754 Floating-Point Arithmetic](https://homepage.cs.uiowa.edu/~tinelli/papers/BraEtAl-ARITH-15.pdf).
Martin Brain, Cesare Tinelli, Philipp Rümmer, Thomas Wahl.
*ARITH, 2015.*

**Main connection:** [theory_fp_rewriter.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/fp/theory_fp_rewriter.cpp).

The floating-point rewriter distinguishes IEEE fp.eq from logical equality, including NaNs and
signed zero. Derive both results in the tutorial from these semantics before investigating
symbolic encoding or constant evaluation.
Read with [Floating point](theory-development/floating-point.md).

### SYMFPU-2019

[Building Better Bit-Blasting for Floating-Point Problems](https://openaccess.city.ac.uk/21921/1/brain_schanda_tacas2019_extended.pdf).
Martin Brain, Florian Schanda, Youcheng Sun.
*TACAS, 2019.*

**Main connection:** [fp_word_blaster.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/fp/fp_word_blaster.h).

FpWordBlaster supplies cvc5 symbolic types to SymFPU’s encodings. Follow a symbolic floating-
point operator into bit-vector expressions; the separate MPFR constant-evaluation
implementation is not the subject of this paper.
Read with [Floating point](theory-development/floating-point.md).

## Finite fields

### FINITE-FIELDS-2023

[Satisfiability Modulo Finite Fields](https://link.springer.com/chapter/10.1007/978-3-031-37703-7_8).
Alex Ozdemir, Gereon Kremer, Cesare Tinelli, and Clark Barrett.
*CAV, 2023.*

**Main connection:** [cocoa_encoder.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/ff/cocoa_encoder.h), [sub_theory.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/ff/sub_theory.cpp).

CocoaEncoder builds polynomial constraints, including disequality encodings, and SubTheory
obtains base-field assignments. In the no-root example, identify where the field restriction
rules out an algebraic-closure solution.
Read with [Finite fields](theory-development/finite-fields.md).

### SPLIT-GB-2024

[Split Gröbner Bases for Satisfiability Modulo Finite Fields](https://theory.stanford.edu/~barrett/pubs/OPB+24.pdf).
Alex Ozdemir, Shankara Pailoor, Alp Bassa, Kostas Ferles, Clark Barrett, and Işil Dillig.
*CAV, 2024.*

**Main connection:** [split_gb.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/ff/split_gb.h).

The split_gb header explicitly names this algorithm. Read it with the selected split-basis
backend and compare the partitioned bases with the one-basis route; both must return values in
the declared finite field.
Read with [Finite fields](theory-development/finite-fields.md).

### FINITE-FIELD-PROOFS-2026

[Proof Production for Satisfiability Modulo Finite Fields with Proof Checking in Pacheck and Lean](https://repositum.tuwien.at/handle/20.500.12708/230471).
Pedro Saccomani, Abdalrhman Mohamed, Elizaveta Pertseva, Daniela Kaufmann,
Cesare Tinelli, Clark Barrett, Haniel Barbosa.
*FMCAD, 2026.*

**Main connection:** [cvc5_proof_rule.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/include/cvc5/cvc5_proof_rule.h), [theory_ff.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/ff/theory_ff.cpp).

The finite-field proof-rule declarations describe polynomial combinations,
root branching and contradiction rules corresponding to the calculus. This
is a partial connection: the field solver returns no theory proof checker
and emits subtheory conflicts without a proof generator. These declarations
do not establish the paper's end-to-end proof production or external checking
in this snapshot. See the [implementation-gap audit](unreferenced-papers.md#partial-case-finite-field-proof-production).
Read with [Finite fields](theory-development/finite-fields.md).

## Strings and sequences

### STRINGS-2014

[A DPLL(T) theory solver for a theory of strings and regular expressions](https://cvc4.github.io/publications/2014/LRT+14.pdf).
Tianyi Liang, Andrew Reynolds, Cesare Tinelli, Clark Barrett, Morgan Deters.
*CAV, 2014.*

**Main connection:** [core_solver.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/core_solver.h), [base_solver.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/base_solver.h).

The headers explicitly connect normal-form and cycle reasoning to the original string calculus.
Align the tutorial’s concatenation components using their known lengths, then remove a length
fact and identify the explanation or split needed to continue. The journal paper expands the
solver account.
Read with [Strings and sequences](theory-development/strings.md).

### STRINGS-2016

[An efficient SMT solver for string constraints](https://cvc4.github.io/publications/2016/LRT+16.pdf).
Tianyi Liang, Andrew Reynolds, Nestan Tsiskaridze, Cesare Tinelli, Clark Barrett, Morgan
Deters.
*Formal Methods in System Design, 2016.*

**Main connection:** [core_solver.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/core_solver.h), [base_solver.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/base_solver.h).

The headers explicitly connect normal-form and cycle reasoning to the original string calculus.
Align the tutorial’s concatenation components using their known lengths, then remove a length
fact and identify the explanation or split needed to continue. The journal paper expands the
solver account.
Read with [Strings and sequences](theory-development/strings.md).

### REGEXP-LENGTH-2015

[A decision procedure for regular membership and length constraints over unbounded strings](https://cvc4.github.io/publications/2015/LTR+15.pdf).
Tianyi Liang, Nestan Tsiskaridze, Andrew Reynolds, Cesare Tinelli, Clark Barrett.
*FroCoS, 2015.*

**Main connection:** [regexp_solver.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/regexp_solver.cpp).

RegExpSolver connects membership obligations to unfolding and length reasoning. Read this
alongside the word-equation example with an added regexp constraint; cancellation alone does
not settle language membership.
Read with [Strings and sequences](theory-development/strings.md).

### STRINGS-CDS-2017

[Scaling up DPLL(T) string solvers using context-dependent simplification](https://cvc4.github.io/publications/2017/RWB+17.pdf).
Andrew Reynolds, Maverick Woo, Clark Barrett, David Brumley, Tianyi Liang, Cesare Tinelli.
*CAV, 2017.*

**Main connection:** [extf_solver.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/extf_solver.h).

ExtfSolver cites these papers for context-dependent simplification and lazy reductions. Track
which equalities justify a simplification and why a conflict can avoid a reduction. Those
assumptions must survive in the explanation and respect backtracking.
Read with [Strings and sequences](theory-development/strings.md).

### STRINGS-ABSTRACTION-2019

[High-level abstractions for simplifying extended string constraints in SMT](https://cvc4.github.io/publications/2019/RNB+19.pdf).
Andrew Reynolds, Andres Nötzli, Clark Barrett, Cesare Tinelli.
*CAV, 2019.*

**Main connection:** [strings_entail.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/strings_entail.h), [arith_entail.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/arith_entail.h).

Both helpers cite the abstraction approach. They establish string and length facts used in
rewriting extended operations; separate these context-independent entailment checks from
search-state deductions in ExtfSolver.
Read with [Strings and sequences](theory-development/strings.md).

### CODE-POINTS-2020

[A Decision Procedure for String to Code Point Conversion](https://cvc4.github.io/publications/2020/RNB+20-IJCAR.pdf).
Andrew Reynolds, Andres Nötzli, Clark Barrett, Cesare Tinelli.
*IJCAR, 2020.*

**Main connection:** [code_point_solver.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/code_point_solver.h).

CodePointSolver explicitly cites the decision procedure. Follow conversion lemmas for single-
character strings and the exceptional cases for other lengths; replacing a string by an
unrestricted integer code loses these conditions.
Read with [Strings and sequences](theory-development/strings.md).

### REGEXP-REDUCTIONS-2020

[Reductions for Strings and Regular Expressions Revisited](https://cvc4.github.io/publications/2020/RNB+20-FMCAD.pdf).
Andrew Reynolds, Andres Nötzli, Clark Barrett, Cesare Tinelli.
*FMCAD, 2020.*

**Main connection:** [regexp_elim.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/regexp_elim.h).

RegExpElimination exposes the reductions discussed in this work. Compare a membership
expression with the generated constraints and auxiliary terms, including the conditions under
which elimination is applicable.
Read with [Strings and sequences](theory-development/strings.md).

### STRINGS-LAZY-2022

[Even Faster Conflicts and Lazier Reductions for String Solvers](https://homepage.divms.uiowa.edu/~ajreynol/cav22.pdf).
Andres Noetzli, Andrew Reynolds, Haniel Barbosa, Clark Barrett, Cesare Tinelli.
*CAV, 2022.*

**Main connection:** [extf_solver.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/extf_solver.h).

ExtfSolver cites these papers for context-dependent simplification and lazy reductions. Track
which equalities justify a simplification and why a conflict can avoid a reduction. Those
assumptions must survive in the explanation and respect backtracking.
Read with [Strings and sequences](theory-development/strings.md).

### SEQUENCES-2022

[Reasoning About Vectors using an SMT Theory of Sequences](https://homepage.divms.uiowa.edu/~ajreynol/ijcar22c.pdf).
Ying Sheng, Andres Noetzli, Andrew Reynolds, Yoni Zohar, David Dill, Wolfgang Grieskamp, Junkil
Park, Shaz Qadeer, Clark Barrett and Cesare Tinelli.
*IJCAR, 2022.*

**Main connection:** [array_solver.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/array_solver.h), [theory_strings.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/theory_strings.cpp).

Sequence element access and array-style reasoning extend the shared concatenation/length solver
to arbitrary element sorts. Follow element-equality obligations into the element theory;
String’s fixed character domain is not a model of every Seq(T).
Read with [Strings and sequences](theory-development/strings.md).

### SEQUENCES-2023

[Reasoning About Vectors: Satisfiability Modulo a Theory of Sequences](https://homepage.divms.uiowa.edu/~ajreynol/jar2023b.pdf).
Ying Sheng, Andres Noetzli, Andrew Reynolds, Yoni Zohar, David L. Dill, Wolfgang Grieskamp,
Junkil Park, Shaz Qadeer, Clark W. Barrett, Cesare Tinelli.
*Journal of Automated Reasoning, 2023.*

**Main connection:** [array_solver.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/array_solver.h), [theory_strings.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/theory_strings.cpp).

Sequence element access and array-style reasoning extend the shared concatenation/length solver
to arbitrary element sorts. Follow element-equality obligations into the element theory;
String’s fixed character domain is not a model of every Seq(T).
Read with [Strings and sequences](theory-development/strings.md).

## Sets relations bags and tables

### SETS-2016

[A new decision procedure for finite sets and cardinality constraints in SMT](https://cvc4.github.io/publications/2016/BRBT16.pdf).
Kshitij Bansal, Andrew Reynolds, Clark Barrett, Cesare Tinelli.
*IJCAR, 2016.*

**Main connection:** [cardinality_extension.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/sets/cardinality_extension.cpp).

The cardinality extension relates membership regions and their sizes to the model. The
tutorial’s two distinct members require at least two elements; without their disequality, two
syntactic terms may occupy one region element. The journal article extends the conference
account.
Read with [Sets and relations](theory-development/sets.md).

### SETS-2018

[Reasoning with finite sets and cardinality constraints in SMT](https://cvc4.github.io/publications/2018/KRB+18.pdf).
Kshitij Bansal, Clark Barrett, Andrew Reynolds, Cesare Tinelli.
*Logical Methods in Computer Science, 2018.*

**Main connection:** [cardinality_extension.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/sets/cardinality_extension.cpp).

The cardinality extension relates membership regions and their sizes to the model. The
tutorial’s two distinct members require at least two elements; without their disequality, two
syntactic terms may occupy one region element. The journal article extends the conference
account.
Read with [Sets and relations](theory-development/sets.md).

### RELATIONS-2017

[Relational constraint solving in SMT](https://cvc4.github.io/publications/2017/MRT+17.pdf).
Baoluo Meng, Andrew Reynolds, Cesare Tinelli, Clark Barrett.
*CADE, 2017.*

**Main connection:** [theory_sets_rels.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/sets/theory_sets_rels.cpp).

TheorySetsRels generates consequences for relations represented as sets of tuples. Express a
join or product as tuple-membership conditions, then find the corresponding inference;
duplicate tuple occurrences do not increase a set’s size.
Read with [Sets and relations](theory-development/sets.md).

### TABLES-2024

[Verifying SQL queries using theories of tables and relations](https://theory.stanford.edu/~barrett/pubs/MRT+24.pdf).
Mudathir Mahgoub Yahia Mohamed, Andrew Reynolds, Cesare Tinelli, and Clark Barrett.
*LPAR, 2024.*

**Main connection:** [inference_generator.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/bags/inference_generator.cpp), [theory_sets_rels.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/sets/theory_sets_rels.cpp).

The retained solver contribution is reasoning about tables with bag multiplicities and
relations with set membership. Follow count lemmas and tuple operations in these two
components. The paper’s SQL translation and verification application are outside this source
connection.
Read with [bags and tables](theory-development/bags.md) and [sets and relations](theory-development/sets.md).

### SET-COMPREHENSIONS-2025

[Solving Set Constraints with Comprehensions and Bounded Quantifiers](https://repositum.tuwien.at/handle/20.500.12708/219545).
Mudathir Mohamed, Nick Feng, Andrew Reynolds, Cesare Tinelli, Clark Barrett, and Marsha
Chechik.
*FMCAD, 2025.*

**Main connection:** [theory_sets_rewriter.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/sets/theory_sets_rewriter.cpp), [theory_sets_private.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/sets/theory_sets_private.cpp).

postRewriteAll and postRewriteSome encode set-bounded quantification using SET_FILTER;
checkFilterUp and checkFilterDown propagate filter membership. This is restricted comprehension
over a supplied set, distinct from the general SET_COMPREHENSION reduction to quantified
formulas.
Read with [Sets and relations](theory-development/sets.md).

## Separation logic

### SEP-2016

[A Decision Procedure for Separation Logic in SMT](https://cvc4.github.io/publications/2016/RIS+16.pdf).
Andrew Reynolds, Radu Iosif, Christina Serban, Tim King.
*ATVA, 2016.*

**Main connection:** [theory_sep.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/sep/theory_sep.cpp).

TheorySep labels spatial subformulas, reasons about heap domains and refines candidate heaps.
Derive the tutorial’s conflict from two singleton domains forced both to overlap and to be
disjoint, then locate the labels supporting the inference.
Read with [Separation logic](theory-development/separation-logic.md).

## Quantifiers and higher-order reasoning

### FMF-INSTANTIATION-2013

[Quantifier instantiation techniques for finite model finding in SMT](https://cvc4.github.io/publications/2013/RTG+13.pdf).
Andrew Reynolds, Cesare Tinelli, Amit Goel, Sava Krstic, Morgan Deters, Clark Barrett.
*CADE, 2013.*

**Main connection:** [full_model_check.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/fmf/full_model_check.h).

FullModelChecker checks quantified formulas against finite candidate models and generates
needed instances. Compare its domain coverage with merely assigning a truth value to a
quantified assertion in the ground model.
Read with [Quantifiers](theory-development/quantifiers.md).

### FMF-2013

[Finite Model Finding in SMT](https://cvc4.github.io/publications/2013/RTG+13-CAV.pdf).
Andrew Reynolds, Cesare Tinelli, Amit Goel, Sava Krstic.
*CAV, 2013.*

**Main connection:** [model_engine.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/fmf/model_engine.cpp), [cardinality_extension.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/uf/cardinality_extension.h).

ModelEngine and the UF cardinality extension connect finite-domain choices to quantified model
checking. Follow domain-size constraints, candidate construction and the owning module’s
completeness check; a ground model alone does not justify quantified satisfiability.
Read with [Quantifiers](theory-development/quantifiers.md).

### FMF-CONSTRAINTS-2017

[Constraint solving for finite model finding in SMT solvers](https://cvc4.github.io/publications/2017/RTB17.pdf).
Andrew Reynolds, Cesare Tinelli, Clark Barrett.
*Theory and Practice of Logic Programming, 2017.*

**Main connection:** [model_engine.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/fmf/model_engine.cpp), [cardinality_extension.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/uf/cardinality_extension.h).

ModelEngine and the UF cardinality extension connect finite-domain choices to quantified model
checking. Follow domain-size constraints, candidate construction and the owning module’s
completeness check; a ground model alone does not justify quantified satisfiability.
Read with [Quantifiers](theory-development/quantifiers.md).

### CONFLICT-INST-2014

[Finding conflicting instances of quantified formulas in SMT](https://cvc4.github.io/publications/2014/RTM14.pdf).
Andrew Reynolds, Cesare Tinelli, Leonardo Mendonca de Moura.
*FMCAD, 2014.*

**Main connection:** [quant_conflict_find.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/quant_conflict_find.cpp).

QuantConflictFind explicitly cites the conflict-based procedure. Follow the search for a
substitution whose instance conflicts with current ground facts; this uses more information
than matching a trigger’s shape. The workshop report is an earlier presentation.
Read with [Quantifiers](theory-development/quantifiers.md).

### LOCAL-EXTENSIONS-2015

[Deciding local theory extensions via E-matching](https://cvc4.github.io/publications/2015/BRK+15.pdf).
Kshitij Bansal, Andrew Reynolds, Tim King, Clark Barrett, Thomas Wies.
*CAV, 2015.*

**Main connection:** [inst_strategy_e_matching.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/ematching/inst_strategy_e_matching.h).

The connection is E-matching against ground terms modulo equality. The paper identifies local-
extension conditions under which this instantiation approach is complete; the general matching
module is not a detector or completeness guarantee for arbitrary local extensions.
Read with [Quantifiers](theory-development/quantifiers.md).

### ARITH-CEGQI-2017

[Solving quantified linear arithmetic by counterexample-guided instantiation](https://cvc4.github.io/publications/2017/RKK17.pdf).
Andrew Reynolds, Tim King, Viktor Kuncak.
*Formal Methods in System Design, 2017.*

**Main connection:** [ceg_instantiator.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/cegqi/ceg_instantiator.h), [ceg_arith_instantiator.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/cegqi/ceg_arith_instantiator.h).

The CEGQI framework cites this work and delegates arithmetic substitutions to
ArithInstantiator. Trace how a candidate counterexample yields a projected substitution;
repairing a ground simplex tableau is a different operation.
Read with [Quantifiers](theory-development/quantifiers.md).

### CCFV-2017

[Congruence Closure with Free Variables](https://cvc4.github.io/publications/2017/BFR17.pdf).
Haniel Barbosa, Pascal Fontaine, Andrew Reynolds.
*TACAS, 2017.*

**Main connection:** [trigger_term_info.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/ematching/trigger_term_info.h).

Trigger metadata explicitly cites congruence closure with free variables. Use the equality-
aware matching variation of the tutorial to see why matching needs both term structure and
equality representatives.
Read with [Quantifiers](theory-development/quantifiers.md).

### ENUM-INST-2018

[Revisiting Enumerative Instantiation](https://cvc4.github.io/publications/2018/RBF18.pdf).
Andrew Reynolds, Haniel Barbosa, Pascal Fontaine.
*TACAS, 2018.*

**Main connection:** [inst_strategy_enumerative.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/inst_strategy_enumerative.h).

InstStrategyEnum explicitly cites the paper’s completeness result and implements enumerative
instantiation. Separate tuple generation from entailment filtering when tracing the tutorial’s
f(a) instance.
Read with [Quantifiers](theory-development/quantifiers.md).

### SYQI-2021

[Syntax-Guided Quantifier Instantiation](https://cvc4.github.io/publications/2021/NPR+21-TACAS.pdf).
Aina Niemetz, Mathias Preiner, Andrew Reynolds, Clark Barrett, Cesare Tinelli.
*TACAS, 2021.*

**Main connection:** [sygus_inst.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/sygus_inst.h).

SygusInst uses syntax-guided term generation for quantifier instantiation. Identify the grammar
supplying a substitution term that ordinary matching against the current ground terms would
miss.
Read with [Quantifiers](theory-development/quantifiers.md).

### HIGHER-ORDER-2019

[Extending SMT solvers to higher-order logic](https://cvc4.github.io/publications/2019/BREO+19.pdf).
Haniel Barbosa, Andrew Reynolds, Daniel El Ouraoui, Cesare Tinelli, Clark Barrett.
*CADE, 2019.*

**Main connection:** [ho_term_database.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/ho_term_database.h), [ho_extension.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/uf/ho_extension.h).

HoTermDb cites the higher-order extension, while HoExtension handles application and
extensionality obligations. Compare a witness for f != g with the first-order congruence
example. The work-in-progress report precedes the fuller account.
Read with [Quantifiers](theory-development/quantifiers.md).

### HIGHER-ORDER-2018

[Higher-Order SMT Solving (Work in Progress)](https://homepage.divms.uiowa.edu/~ajreynol/smt18b.pdf).
Haniel Barbosa, Andrew Reynolds, Pascal Fontaine, Daniel El Ouraoui, and Cesare Tinelli.
*SMT workshop, work in progress, 2018.*

**Main connection:** [ho_term_database.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/ho_term_database.h), [ho_extension.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/uf/ho_extension.h).

HoTermDb cites the higher-order extension, while HoExtension handles application and
extensionality obligations. Compare a witness for f != g with the first-order congruence
example. The work-in-progress report precedes the fuller account.
Read with [Quantifiers](theory-development/quantifiers.md).

### RECURSIVE-FUNCTIONS-2016

[Model Finding for Recursive Functions in SMT](https://cvc4.github.io/publications/2016/RBC+16.pdf).
Andrew Reynolds, Jasmin Christian Blanchette, Simon Cruanes, Cesare Tinelli.
*IJCAR, 2016.*

**Main connection:** [fun_def_fmf.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/preprocessing/passes/fun_def_fmf.cpp).

FunDefFmf preprocesses recursive definitions for finite-model finding. Follow the transformed
quantified definition into model checking; an inductive datatype cycle test does not by itself
test reasoning about recursive functions.
Read with [Quantifiers](theory-development/quantifiers.md).

### INDUCTION-2015

[Induction for SMT solvers](https://cvc4.github.io/publications/2015/RK15.pdf).
Andrew Reynolds, Viktor Kuncak.
*VMCAI, 2015.*

**Main connection:** [skolemize.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/skolemize.h).

Skolemize explicitly cites the paper’s induction technique. Inspect the strengthening used when
skolemizing supported induction conjectures, rather than attributing induction to every
datatype or quantifier check.
Read with [Quantifiers](theory-development/quantifiers.md).

### QUANTIFIER-HEURISTICS-2016

[Conflicts, Models and Heuristics for Quantifier Instantiation in SMT](https://homepage.divms.uiowa.edu/~ajreynol/vampire16.pdf).
Andrew Reynolds.
*Vampire workshop, invited paper, 2016.*

**Main connection:** [quant_conflict_find.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/quant_conflict_find.cpp), [model_engine.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/fmf/model_engine.cpp).

The conflict and model approaches surveyed here remain separate modules with different checks
and scheduling. Use the quantifier chapter’s strategy table to follow one proposed substitution
all the way to Instantiate.
Read with [Quantifiers](theory-development/quantifiers.md).

### RECURSIVE-FUNCTIONS-2015

[Model Finding for Recursive Functions in SMT](https://homepage.divms.uiowa.edu/~ajreynol/smt15.pdf).
Andrew Reynolds, Jasmin Christian Blanchette, and Cesare Tinelli.
*SMT workshop, 2015.*

**Main connection:** [fun_def_fmf.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/preprocessing/passes/fun_def_fmf.cpp).

FunDefFmf preprocesses recursive definitions for finite-model finding. Follow the transformed
quantified definition into model checking; an inductive datatype cycle test does not by itself
test reasoning about recursive functions.
Read with [Quantifiers](theory-development/quantifiers.md).

### CONFLICT-INST-WORKSHOP-2014

[Finding Conflicting Instances of Quantified Formulas in SMT](https://homepage.divms.uiowa.edu/~ajreynol/quantify14.pdf).
Andrew Reynolds, Cesare Tinelli, and Leonardo de Moura.
*QUANTIFY workshop, 2014.*

**Main connection:** [quant_conflict_find.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/quant_conflict_find.cpp).

QuantConflictFind explicitly cites the conflict-based procedure. Follow the search for a
substitution whose instance conflicts with current ground facts; this uses more information
than matching a trigger’s shape. The workshop report is an earlier presentation.
Read with [Quantifiers](theory-development/quantifiers.md).

### MBQI-ENUM-2025

[Augmenting Model-Based Instantiation with Fast Enumeration](https://www.tcs.ifi.lmu.de/staff/jasmin-blanchette/enum.pdf).
Lydia Kondylidou, Andrew Reynolds, Jasmin Blanchette.
*TACAS, 2025.*

**Main connection:** [mbqi_enum.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/mbqi_enum.cpp).

MbqiEnum combines model-based instantiation with the SyGuS enumerator. Follow how a grammar-
generated term replaces a candidate model value and how the resulting instance is checked.
Read with [Quantifiers](theory-development/quantifiers.md).

### CHOICE-INST-2026

[Enumerating Choice Terms in Model-Based Quantifier Instantiation](https://link.springer.com/chapter/10.1007/978-3-032-22752-2_15).
Lydia Kondylidou, Andrew Reynolds, Jasmin Blanchette, Cesare Tinelli.
*TACAS, 2026.*

**Main connection:** [mbqi_enum.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/mbqi_enum.cpp).

The implementation contains choice grammars, witness elimination and auxiliary lemmas
constraining the introduced symbols. Follow these steps together: enumerating a choice term
without its semantic obligations would not justify the same instance.
Read with [Quantifiers](theory-development/quantifiers.md).

### MBQI-2009

[Complete Instantiation for Quantified Formulas in Satisfiabiliby Modulo Theories](https://leodemoura.github.io/files/citr09.pdf).
Yeting Ge, Leonardo de Moura.
*CAV; title follows the published spelling, 2009.*

**Main connection:** [inst_strategy_mbqi.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/inst_strategy_mbqi.h).

InstStrategyMbqi cites this foundation for model-based instantiation. The selected
counterexample must be turned into a usable ground instance; completeness depends on the
paper’s fragment assumptions.
Read with [Quantifiers](theory-development/quantifiers.md).

## Synthesis and abduction

### SYGUS-CEGQI-2015

[Counterexample guided quantifier instantiation for synthesis in SMT](https://cvc4.github.io/publications/2015/RDK+15.pdf).
Andrew Reynolds, Morgan Deters, Viktor Kuncak, Clark Barrett, Cesare Tinelli.
*CAV, 2015.*

**Main connection:** [synth_engine.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/sygus/synth_engine.h), [embedding_converter.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/sygus/embedding_converter.h).

SynthEngine and EmbeddingConverter explicitly relate the synthesis embedding and counterexample
loop to the conference paper. Identify the verification query that can reject a candidate
fitting every current example; the journal article develops the refutation-based account.
Read with [Synthesis](theory-development/quantifiers.md#synthesis).

### REFUTATION-SYNTHESIS-2019

[Refutation-based synthesis in SMT](https://cvc4.github.io/publications/2017/RKT+17.pdf).
Andrew Reynolds, Viktor Kuncak, Cesare Tinelli, Clark Barrett, Morgan Deters.
*Formal Methods in System Design, 2019.*

**Main connection:** [synth_engine.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/sygus/synth_engine.h), [embedding_converter.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/sygus/embedding_converter.h).

SynthEngine and EmbeddingConverter explicitly relate the synthesis embedding and counterexample
loop to the conference paper. Identify the verification query that can reject a candidate
fitting every current example; the journal article develops the refutation-based account.
Read with [Synthesis](theory-development/quantifiers.md#synthesis).

### CVC4SY-2019

[CVC4SY: Smart and fast term enumeration for syntax-guided synthesis](https://cvc4.github.io/publications/2019/RBN+19.pdf).
Andrew Reynolds, Haniel Barbosa, Andres Nötzli, Cesare Tinelli, Clark Barrett.
*CAV, 2019.*

**Main connection:** [sygus_enumerator.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/sygus/sygus_enumerator.h).

SygusEnumerator enumerates terms represented by grammar datatypes and filters redundant
candidates. Follow an enumerated grammar value into candidate evaluation before interpreting a
check-synth result.
Read with [Synthesis](theory-development/quantifiers.md#synthesis).

### SYGUS-CLASSIFICATION-2019

[Extending enumerative function synthesis via SMT-driven classification](https://cvc4.github.io/publications/2019/BRL+19.pdf).
Haniel Barbosa, Andrew Reynolds, Daniel Larraz, Cesare Tinelli.
*FMCAD, 2019.*

**Main connection:** [cegis_unif.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/sygus/cegis_unif.h).

CegisUnif explicitly cites SMT-driven classification. Trace how enumerated pieces are
classified by behavior and combined into a candidate solution; each piece’s local fit does not
settle the full specification.
Read with [Synthesis](theory-development/quantifiers.md#synthesis).

### SYGUS-CORE-2017

[SyGuS Techniques in the Core of an SMT solver](https://cvc4.github.io/publications/2017/RT17.pdf).
Andrew Reynolds, Cesare Tinelli.
*SYNT workshop, 2017.*

**Main connection:** [example_eval_cache.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/sygus/example_eval_cache.h), [sygus_qe_preproc.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/sygus/sygus_qe_preproc.h).

These helpers cite the reuse of synthesis inside the solver. Compare example-based redundancy
detection with the quantifier-elimination preprocessing route and identify the condition
justifying each discarded candidate.
Read with [Synthesis](theory-development/quantifiers.md#synthesis).

### ABDUCTION-2020

[Scalable Algorithms for Abduction via Enumerative Syntax-Guided Synthesis](https://cvc4.github.io/publications/2020/RBL+20.pdf).
Andrew Reynolds, Haniel Barbosa, Daniel Larraz, Cesare Tinelli.
*IJCAR, 2020.*

**Main connection:** [sygus_abduct.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/sygus/sygus_abduct.h), [abduction_solver.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/abduction_solver.cpp).

SygusAbduct constructs the synthesis problem used by AbductionSolver. An explanation must make
the desired conclusion follow while meeting the consistency obligation; generating a
grammatically valid formula is only the candidate step.
Read with [Synthesis](theory-development/quantifiers.md#synthesis).

### SOLUTION-FITTING-2023

[A Procedure for SyGuS Solution Fitting via Matching and Rewrite Rule Discovery](https://repositum.tuwien.at/handle/20.500.12708/188730).
Abdalrhman Mohamed, Andrew Reynolds, Clark W. Barrett, Cesare Tinelli.
*FMCAD, 2023.*

**Main connection:** [sygus_reconstruct.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/sygus/sygus_reconstruct.h).

SygusReconstruct fits a term to a target grammar using enumeration, matching and discovered
equalities. Read its algorithm and observation pools with the paper, then distinguish
reconstruction from the initial search for a satisfying function.
Read with [Synthesis](theory-development/quantifiers.md#synthesis).

### SYNTHESIS-CONSTANTS-2023

[Synthesising Programs with Non-trivial Constants](https://homepage.divms.uiowa.edu/~ajreynol/jar2023a.pdf).
Alessandro Abate, Haniel Barbosa, Clark Barrett, Cristina David, Pascal Kesseli, Daniel
Kroening, Elizabeth Polgreen, Andrew Reynolds, Cesare Tinelli.
*Journal of Automated Reasoning, 2023.*

**Main connection:** [sygus_repair_const.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/sygus/sygus_repair_const.h).

SygusRepairConst replaces repairable candidate subterms by symbolic constants and asks a
separate solver for values satisfying the specification. This corresponds to the CVC4 constant-
repair integration discussed in the paper; the separate fastsynth implementation is outside
this mapping.
Read with [Synthesis](theory-development/quantifiers.md#synthesis).

### ORACLES-2022

[Satisfiability and Synthesis Modulo Oracles](https://homepage.divms.uiowa.edu/~ajreynol/vmcai22a.pdf).
Elizabeth Polgreen, Andrew Reynolds and Sanjit Seshia.
*VMCAI, 2022.*

**Main connection:** [oracle_engine.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/oracle_engine.h), [oracle_checker.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/oracle_checker.h).

OracleEngine explicitly cites the paper. OracleChecker checks interpretations against external
oracle responses and generates the required consistency constraints. This is a specialized
quantified-oracle interface, distinct from an ordinary theory callback.
Read with [Synthesis](theory-development/quantifiers.md#synthesis).

## Rewriting and proof production

### REWRITE-ENUM-2019

[Syntax-guided rewrite rule enumeration for SMT solvers](https://cvc4.github.io/publications/2019/NRB+19.pdf).
Andres Nötzli, Andrew Reynolds, Haniel Barbosa, Aina Niemetz, Mathias Preiner, Clark Barrett,
Cesare Tinelli.
*SAT, 2019.*

**Main connection:** [candidate_rewrite_database.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/candidate_rewrite_database.h).

CandidateRewriteDatabase cites syntax-guided rewrite enumeration. Compare candidate equality
discovery with validation and registration in the rewrite database; a discovered pattern still
needs a valid equality. The workshop account precedes the conference paper.
Read with [Making and investigating a change](development.md).

### REWRITE-ENUM-2018

[Rewrites for SMT Solvers using Syntax-Guided Enumeration (Work in Progress)](https://homepage.divms.uiowa.edu/~ajreynol/smt18a.pdf).
Andrew Reynolds, Haniel Barbosa, Aina Niemetz, Andres Noetzli, Mathias Preiner, Clark Barrett,
and Cesare Tinelli.
*SMT workshop, work in progress, 2018.*

**Main connection:** [candidate_rewrite_database.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/candidate_rewrite_database.h).

CandidateRewriteDatabase cites syntax-guided rewrite enumeration. Compare candidate equality
discovery with validation and registration in the rewrite database; a discovered pattern still
needs a valid equality. The workshop account precedes the conference paper.
Read with [Making and investigating a change](development.md).

### REWRITE-DSL-2022

[Reconstructing Fine-Grained Proofs of Rewrites Using a Domain-Specific Language](https://cs.stanford.edu/~preiner/publications/2022/NoetzliBNPRBT-FMCAD22.pdf).
Andres Nötzli, Haniel Barbosa, Aina Niemetz, Mathias Preiner, Andrew Reynolds, Cesare Tinelli,
Clark Barrett.
*FMCAD, 2022.*

**Main connection:** [rewrite_db_proof_cons.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/rewriter/rewrite_db_proof_cons.h).

RewriteDbProofCons explicitly cites the reconstruction algorithm. In the singleton-set
exercise, follow the matched rewrite rule into a fine-grained equality proof and then into the
enclosing proof dependency.
Read with [Making and investigating a change](development.md).

### FLEXIBLE-PROOFS-2022

[Flexible Proof Production in an Industrial-Strength SMT Solver](https://cs.stanford.edu/~preiner/publications/2022/BarbosaRKLNNOPVVZTB-IJCAR22.pdf).
Haniel Barbosa, Andrew Reynolds, Gereon Kremer, Hanna Lachnitt, Aina Niemetz, Andres Nötzli,
Alex Ozdemir, Mathias Preiner, Arjun Viswanathan, Scott Viteri, Yoni Zohar, Cesare Tinelli,
Clark Barrett.
*IJCAR, 2022.*

**Main connection:** [proof_generator.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/proof/proof_generator.h), [trust_node.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/proof/trust_node.h), [proof_manager.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/proof_manager.cpp).

Proof generators, TrustNode and ProofManager implement the modular producer architecture.
Follow a preprocessing equality through its delayed justification and into the final
refutation; printing a proof and checking that proof are separate calls.
Read with [Making and investigating a change](development.md).

### CPC-2026

[The Cooperating Proof Calculus: Comprehensive Proofs for an SMT Solver](https://hanielbarbosa.com/papers/2026cav.pdf).
Andrew Reynolds, Hans-Jörg Schurr, Haniel Barbosa, Ofec Israel, Jibiana Zoe Jakpor, Hanna
Lachnitt, Abdalrhman Mohamed, Aina Niemetz, Mathias Preiner, Yoni Zohar, Robert Jones, Clark
Barrett, Cesare Tinelli.
*CAV, 2026.*

**Main connection:** [Cpc.eo](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/proofs/eo/cpc/Cpc.eo), [eo_printer.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/proof/eo/eo_printer.cpp).

The CPC rule definitions and Eunoia printer provide the direct calculus-to-code connection.
Compare a ProofRule’s premises and conclusion with its exported CPC step; the tutorial’s
singleton rewrite is a small route through this boundary.
Read with [Making and investigating a change](development.md).

### ETHOS-2026

[Ethos: A Fast Proof Checker for the Eunoia Logical Framework](https://hanielbarbosa.com/papers/2026ijcar-ethos.pdf).
Andrew Reynolds, Hans-Jörg Schurr, Mallku Soldevila, Haniel Barbosa, Cesare Tinelli, Clark
Barrett.
*IJCAR, 2026.*

**Main connection:** [eo_printer.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/proof/eo/eo_printer.cpp).

The connection is Eunoia output emitted by EoPrinter for the external Ethos checker. Read the
framework’s term and rule representation against that output; the checker is a separate
program, not an algorithm claimed to reside in this file.
Read with [Making and investigating a change](development.md).

### LFSC-2013

[SMT Proof Checking Using a Logical Framework](https://homepage.divms.uiowa.edu/~ajreynol/fmsd12.pdf).
Aaron Stump, Duckki Oe, Andrew Reynolds, Liana Hadarean, and Cesare Tinelli.
*Formal Methods in System Design, 2013.*

**Main connection:** [lfsc_printer.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/proof/lfsc/lfsc_printer.cpp).

LfscPrinter serializes proofs for the logical framework described in the paper. Distinguish a
rule’s premises from a computational side condition when following the exported proof; the
paper does not specify current rule coverage.
Read with [Making and investigating a change](development.md).

### ALETHE-2021

[Alethe: Towards a Generic SMT Proof Format](https://hanielbarbosa.com/papers/pxtp2021.pdf).
Hans-Jörg Schurr, Mathias Fleury, Haniel Barbosa, Pascal Fontaine.
*PxTP workshop, 2021.*

**Main connection:** [alethe_printer.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/proof/alethe/alethe_printer.cpp), [alethe_post_processor.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/proof/alethe/alethe_post_processor.cpp).

The postprocessor and printer translate internal proofs to Alethe steps. Compare internal rules
with the emitted format, including elaboration introduced during export. The living
specification evolves independently; these pinned files establish what this snapshot emits.
Read with [Making and investigating a change](development.md).

### ALETHE-SPEC-2025

[The Alethe Proof Format: An Evolving Specification and Reference](https://verit.gitlabpages.uliege.be/alethe/specification.pdf).
Haniel Barbosa, Mathias Fleury, Pascal Fontaine, Hans-Jörg Schurr.
*Living format specification; version listed by the authors in 2025, 2025.*

**Main connection:** [alethe_printer.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/proof/alethe/alethe_printer.cpp), [alethe_post_processor.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/proof/alethe/alethe_post_processor.cpp).

The postprocessor and printer translate internal proofs to Alethe steps. Compare internal rules
with the emitted format, including elaboration introduced during export. The living
specification evolves independently; these pinned files establish what this snapshot emits.
Read with [Making and investigating a change](development.md).

## Solver integration and configuration

### PARTITIONING-2023

[Partitioning Strategies for Distributed SMT Solving](https://repositum.tuwien.at/handle/20.500.12708/188827).
Amalee Wilson, Andres Noetzli, Andrew Reynolds, Byron Cook, Cesare Tinelli, Clark W. Barrett.
*FMCAD, 2023.*

**Main connection:** [partition_generator.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/partition_generator.h).

PartitionGenerator builds and emits cubes from selected literals and records blocking
constraints. The source connection covers subproblem generation; scheduling the resulting jobs
across machines belongs to an external executor.
Read with [Development workflow](development.md).

### INPUT-STABILITY-2025

[Towards SMT Solver Stability via Input Normalization](https://cs.stanford.edu/~preiner/publications/2025/AmrollahiPNRCTB-FMCAD25.pdf).
Daneshvar Amrollahi, Mathias Preiner, Aina Niemetz, Andrew Reynolds, Moses Charikar, Cesare
Tinelli, Clark Barrett.
*FMCAD, 2025.*

**Main connection:** [normalize.cpp](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/preprocessing/passes/normalize.cpp).

The Normalize implementation explicitly cites this paper. Follow canonical ordering and
renaming through the preprocessing pass, then compare equivalent presentations of a benchmark
when evaluating a performance change.
Read with [Development workflow](development.md).

### IPASIR-UP-2023

[IPASIR-UP: User Propagators for CDCL](https://cs.stanford.edu/~preiner/publications/2023/FazekasNPKSB-SAT23.pdf).
Katalin Fazekas, Aina Niemetz, Mathias Preiner, Markus Kirchweger, Stefan Szeider, Armin Biere.
*SAT, 2023.*

**Main connection:** [cdclt_propagator.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/prop/cadical/cdclt_propagator.h).

The CaDiCaL CDCL(T) propagator implements the external-propagator boundary discussed in these
papers. Follow assignment notifications, propagation explanations and backtracking into the
theory engine; these events are distinct from term preregistration.
Read with [Development workflow](development.md).

### USER-PROPAGATORS-2024

[Satisfiability Modulo User Propagators](https://jair.org/index.php/jair/article/view/16163/27111).
Katalin Fazekas, Aina Niemetz, Mathias Preiner, Markus Kirchweger, Stefan Szeider, Armin Biere.
*Journal of Artificial Intelligence Research, 2024.*

**Main connection:** [cdclt_propagator.h](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/prop/cadical/cdclt_propagator.h).

The CaDiCaL CDCL(T) propagator implements the external-propagator boundary discussed in these
papers. Follow assignment notifications, propagation explanations and backtracking into the
theory engine; these events are distinct from term preregistration.
Read with [Development workflow](development.md).

## Keeping the literature and tutorials in agreement

For each added paper, record its exact title, authors, year, publication status
and a primary link. Identify the relevant code at the recorded source pin and
explain the algorithm, rule or representation it shares with the paper. If
that connection cannot be established, leave the paper out. A generic link to
a theory directory is insufficient evidence for a particular research result.

Keep citation keys stable when correcting metadata. On a source update,
recheck the component and the scope of the connection; remove a citation if
the supporting code has disappeared and no concrete successor remains. Check
chapter citations along with the bibliography. See the
[maintenance procedure](source-baseline.md#a-maintenance-pass).
