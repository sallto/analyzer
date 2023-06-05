(** Work in progress *)

open Analyses
open GoblintCil
open TerminationPreprocessing
include Printf

exception PreProcessing of string

let loopCounters : varinfo list ref = ref []
let upjumpingGotos : location list ref = ref [] (*contains the locations of the upjumping gotos*)

let loopExit : varinfo ref = ref (makeVarinfo false "-error" Cil.intType)

let is_loop_counter_var (x : varinfo) =
  List.mem x !loopCounters

let is_loop_exit_indicator (x : varinfo) =
  x = !loopExit

(* checks if at the current location (=loc) of the analysis an upjumping goto was already reached
   true: no upjumping goto was reached till now*)
let currrently_no_upjumping_gotos (loc : location) = 
  List.for_all (function (l) -> (l >= loc)) upjumpingGotos.contents

let no_upjumping_gotos () = 
  (List.length upjumpingGotos.contents) <= 0

(** Checks whether a variable can be bounded *)
let check_bounded ctx varinfo =
  let exp = Lval (Var varinfo, NoOffset) in
  match ctx.ask (EvalInt exp) with
    `Top -> false
  | `Bot -> raise (PreProcessing "Loop variable is Bot")
  |    _ -> true (* TODO: Is this sound? *)

module Spec : Analyses.MCPSpec =
struct

  let name () = "termination"

  module D = MapDomain.MapBot (Basetype.Variables) (BoolDomain.MustBool)
  module C = D

  let startstate _ = D.bot ()
  let exitstate = startstate (* TODO *)

  (** Provides some default implementations *)
  include Analyses.IdentitySpec

  let assign ctx (lval : lval) (rval : exp) =
    (* Detect loop counter variable assignment to 0 *)
    match lval, rval with
    (* Assume that the following loop does not terminate *)
      (Var x, NoOffset), _ when is_loop_counter_var x ->
      if not (no_upjumping_gotos ()) then printf "\n4 problem\n";
      D.add x false ctx.local
    (* Loop exit: Check whether loop counter variable is bounded *)
    | (Var y, NoOffset), Lval (Var x, NoOffset) when is_loop_exit_indicator y ->
      let is_bounded = check_bounded ctx x in
      if not (no_upjumping_gotos ()) then printf "\n5 problem\n";
      D.add x is_bounded ctx.local
    | _ -> ctx.local

  let branch ctx (exp : exp) (tv : bool) =
    ctx.local (* TODO: Do we actually need a branch transfer function? *)


  (* provides information to Goblint*)
  let query ctx (type a) (q: a Queries.t): a Queries.result =
    let open Queries in
    match q with
    | Queries.MustTermLoop v when check_bounded ctx v ->
      true (* TODO should we use the checl_bound function?*)
    | Queries.MustTermProg ->
      true (*TODO check if all values in the domain are true -> true*)
    | _ -> Result.top q

end

let () =
  (** Register the preprocessing *)
<<<<<<< HEAD
  Cilfacade.register_preprocess_cil (Spec.name ()) (new loopCounterVisitor loopCounters upjumpingGotos loopExit);
=======
  Cilfacade.register_preprocess_cil (Spec.name ()) (new loopCounterVisitor loopCounters);
>>>>>>> dfa9d6ef8 (changed loop exit indicator form global variable to a special function)
  (** Register this analysis within the master control program *)
  MCP.register_analysis (module Spec : MCPSpec)
