open Prelude

let basename = "compile_commands.json"

type command_object = {
  directory: string;
  file: string;
  command: string option [@default None];
  arguments: string list option [@default None];
  output: string option [@default None];
} [@@deriving yojson]

type t = command_object list [@@deriving yojson]

let parse_file filename =
  Result.get_ok (of_yojson (Yojson.Safe.from_file filename))

let command_o_regexp = Str.regexp "-o +[^ ]+"

let load_and_preprocess ~include_args filename =
  let database_dir = Filename.dirname (GobFilename.absolute filename) in (* absolute before dirname to avoid . *)
  (* TODO: generalize .goblint for everything *)
  ignore (Goblintutil.create_dir ".goblint");
  let preprocessed_dir = Goblintutil.create_dir (Filename.concat ".goblint" "preprocessed") in
  let preprocess obj =
    let file = obj.file in
    let preprocessed_file = Filename.concat preprocessed_dir (Filename.chop_extension (GobFilename.chop_common_prefix database_dir file) ^ ".i") in
    GobSys.mkdir_parents preprocessed_file;
    let preprocess_command = match obj.command, obj.arguments with
      | Some command, None ->
        (* TODO: extract o_file *)
        let preprocess_command = Str.replace_first command_o_regexp (String.join " " include_args ^ " -E -o " ^ preprocessed_file) command (* TODO: cppflags *) in
        if preprocess_command = command then (* easier way to check if match was found (and replaced) *)
          failwith "CompilationDatabase.preprocess: no -o argument found for " ^ file
        else
          preprocess_command
      | None, Some arguments ->
        begin match List.findi (fun i e -> e = "-o") arguments with
          | (o_i, _) ->
            begin match List.split_at o_i arguments with
              | (arguments_init, _ :: o_file :: arguments_tl) ->
                let preprocess_arguments = arguments_init @ include_args @ "-E" :: "-o" :: preprocessed_file :: arguments_tl in (* TODO: cppflags *)
                Filename.quote_command (List.hd preprocess_arguments) (List.tl preprocess_arguments)
              | _ ->
                failwith "CompilationDatabase.preprocess: no -o argument value found for " ^ file
            end
          | exception Not_found ->
            failwith "CompilationDatabase.preprocess: no -o argument found for " ^ file
        end
      | Some _, Some _ ->
        failwith "CompilationDatabase.preprocess: both command and arguments specified for " ^ file
      | None, None ->
        failwith "CompilationDatabase.preprocess: neither command nor arguments specified for " ^ file
    in
    if GobConfig.get_bool "dbg.verbose" then
      Printf.printf "Preprocessing %s\n  to %s\n  using %s\n  in %s\n" file preprocessed_file preprocess_command obj.directory;
    let old_cwd = Sys.getcwd () in
    Fun.protect ~finally:(fun () ->
        Sys.chdir old_cwd
      ) (fun () ->
        Sys.chdir obj.directory; (* command/arguments might have paths relative to directory *)
        match Unix.system preprocess_command with
        | WEXITED 0 -> preprocessed_file
        | process_status -> failwith (MakefileUtil.string_of_process_status process_status)
      )
  in
  parse_file filename
  |> List.map preprocess
