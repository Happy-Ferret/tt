(* We treat the semantic domain as a partial applicative structure, interpreting binding forms directly as closures.
   The meaning of variables is "atoms" or indeterminate constants, which are structured a De Bruijn Levels (not indices).
 *)

type d =
  | Clo of Tm.chk Tm.Bind.t * env
  | Up of d * dne
  | Unit
  | Bool
  | Pi of d * d
  | Sg of d * d
  | Eq of d * d * d
  | EDim
  | U
  | Pair of d * d
  | Ax
  | Tt
  | Ff
  | Dim0
  | Dim1

and dne =
  | Atom of int
  | App of dne * dnf
  | Proj1 of dne
  | Proj2 of dne
  | If of d * dne * dnf * dnf

and dnf =
  | Down of d * d

and env = d list
