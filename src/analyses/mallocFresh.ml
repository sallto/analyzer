(** Analysis of unescaped (i.e. thread-local) heap locations ([mallocFresh]). *)

open GoblintCil
open Analyses


module Spec =
struct
  include Analyses.IdentitySpec

  (* must fresh variables *)
  module D = SetDomain.Reverse (SetDomain.ToppedSet (CilType.Varinfo) (struct let topname = "All variables" end)) (* need bot (top) for hoare widen *)
  module C = D

  let name () = "mallocFresh"

  let startstate _ = D.empty ()
  let exitstate _ = D.empty ()

  let assign_lval (ask: Queries.ask) lval local =
    match ask.f (MayPointTo (AddrOf lval)) with
    | ad when Queries.AD.is_top ad -> D.empty ()
    | ad when Queries.AD.exists (function
        | Queries.AD.Addr.Addr (v,_) -> not (D.mem v local) && (v.vglob || ThreadEscape.has_escaped ask v)
        | _ -> false
      ) ad -> D.empty ()
    | _ -> local

  let assign ctx lval rval =
    assign_lval (Analyses.ask_of_ctx ctx) lval ctx.local

  let combine_env ctx lval fexp f args fc au f_ask =
    ctx.local (* keep local as opposed to IdentitySpec *)

  let combine_assign ctx lval f fd args context f_local (f_ask: Queries.ask) =
    match lval with
    | None -> f_local
    | Some lval -> assign_lval (Analyses.ask_of_ctx ctx) lval f_local

  let special ctx lval f args =
    let desc = LibraryFunctions.find f in
    match desc.special args with
    | Malloc _
    | Calloc _
    | Realloc _ ->
      begin match ctx.ask HeapVar with
        | `Lifted var -> D.add var ctx.local
        | _ -> ctx.local
      end
    | _ ->
      match lval with
      | None -> ctx.local
      | Some lval -> assign_lval (Analyses.ask_of_ctx ctx) lval ctx.local

  let threadenter ctx lval f args =
    [D.empty ()]

  let threadspawn ctx lval f args fctx =
    D.empty ()

  module A =
  struct
    include BoolDomain.Bool
    let name () = "fresh"
    let may_race f1 f2 = not (f1 || f2)
    let should_print f = f
  end
  let access ctx (a: Queries.access) =
    match a with
    | Memory {var_opt = Some v; _} ->
      D.mem v ctx.local
    | _ ->
      false
end

let _ =
  MCP.register_analysis ~dep:["mallocWrapper"] (module Spec : MCPSpec)
