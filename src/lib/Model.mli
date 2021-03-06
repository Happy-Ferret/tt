open Signature

module type Model = sig
  module F : sig
    (* signature endofunctor *)
    type 'a t
  end

  module T : sig
    (* algebra for the signature endofunctor *)
    type t
    [@@deriving (compare, sexp, show)]
  end

  val into : T.t F.t -> T.t
  val var : int -> T.t
  val subst : (T.t, T.t) Subst.Tensor.t -> T.t
end

module type EffectfulTermModel = sig
  include Model

  module M : Monad.S

  val out : T.t -> [`F of T.t F.t | `V of int] M.t
  val pretty : Caml.Format.formatter -> T.t -> unit M.t
end

module type TermModel = sig
  include EffectfulTermModel
    with module M = Monad.Ident
end

module Pure (Sig : Signature) : sig
  include TermModel
    with module F = Sig
end

(* As example of the flexibility of this system *)
module ExplicitSubst (Sig : Signature) : sig
  include TermModel
    with module F = Sig
end
