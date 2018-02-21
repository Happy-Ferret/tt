open Sigs

module Types =
struct
  type hole = string

  (* Here is where things like hash keys and tags should be kept *)
  type term =
    | In of (int, term, subst) term_f
    | Ref of hole * subst
  and subst = InSb of (term, subst) subst_f
end

module Tm =
struct
  type hole = Types.hole
  type term = Types.term
  type subst = Types.subst

  open Types

  let meta alpha sb =
    Ref (alpha, sb)

  let into tf = In tf

  let intoS sbf = InSb sbf


  (* TODO: implement *)
  let subst ~sb ~tm : term =
    match tm with
    | In tmf ->
      begin
        match tmf with
        | Var _ -> failwith ""
        | Lam _ -> failwith ""
        | App (_, _) -> failwith ""
        | Ax -> tm
        | Pi (_, _) -> failwith ""
        | Unit -> tm
        | Univ -> tm
      end
    | Ref (key, sb') -> Ref (key, intoS @@ Cmp (sb, sb'))
end

module ElabCore : ElabCore =
struct
  module Tm = Tm

  type env = (string, Tm.term jdg) Hashtbl.t

  (* let mk_env: unit -> env = Hashtbl.create (module String) *)

  type 'a t = env -> 'a

  let bind m ~f rho = f (m rho) rho
  let return a _ = a
  let map = `Define_using_bind


  module Let_syntax =
  struct
    let bind = bind
  end

  let rec alt (ms : 'a t list) : 'a t =
    match ms with
    | [] -> failwith "No alternatives"
    | m::ms ->
      fun env ->
        let env' = Hashtbl.copy env in
        try m env with
        | _ -> alt ms env'

  let alloc jdg env =
    let key = "fresh" in (* TODO *)
    ignore @@ Hashtbl.add env ~key ~data:jdg;
    key

  let find key env =
    Hashtbl.find_exn env key (* FIXME: use optional version *)

  (* TODO:
     - [ ] possibly typecheck the term
     - [ ] allow things other than Ask via unification
  *)
  let fill key tm env =
    match Hashtbl.find_exn env key with
    | exception Not_found -> failwith "[fill]: key not found"
    | Chk (ctx, Ask, ty) -> Hashtbl.set env ~key ~data:(Chk (ctx, Ret tm, ty))
    | _ -> failwith "[fill]: expected hole"

  let rec out t =
    match t with
    | Types.In tf -> return tf
    | Types.Ref (key, sub) ->
      match%bind find key with
      | Chk (_, Ret t', _) -> out @@ Tm.subst ~sb:sub ~tm:t'
      | Chk (_, Ask, _) -> failwith "[out]: Term is a hole"

end

module Elab (E : ElabCore) =
struct
  include E

  module Let_syntax =
  struct
    let bind = bind
  end

  let ask ~ctx ~ty =
    let%bind key = alloc @@ Chk (ctx, Ask, ty) in
    return (key, Tm.meta key @@ Tm.intoS Id)

end
