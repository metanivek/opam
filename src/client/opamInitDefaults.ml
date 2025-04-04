(**************************************************************************)
(*                                                                        *)
(*    Copyright 2016-2019 OCamlPro                                        *)
(*                                                                        *)
(*  All rights reserved. This file is distributed under the terms of the  *)
(*  GNU Lesser General Public License version 2.1, with the special       *)
(*  exception on linking described in the file LICENSE.                   *)
(*                                                                        *)
(**************************************************************************)

open OpamTypes

let repository_url = {
  OpamUrl.
  transport = "https";
  path = "opam.ocaml.org";
  hash = None;
  backend = `http;
}

let default_compiler =
  OpamFormula.Atom (OpamPackage.Name.of_string "ocaml-base-compiler",
                    OpamFormula.Empty)

let default_invariant =
  OpamFormula.Atom
    (OpamPackage.Name.of_string "ocaml",
     OpamFormula.Atom
       (`Geq, OpamPackage.Version.of_string "4.05.0"))

let sys_ocaml_version =
  OpamVariable.of_string "sys-ocaml-version", ["ocamlc"; "-vnum"],
  "OCaml version present on your system independently of opam, if any"

let eval_variables =
  sys_ocaml_version :: OpamEnv.sys_ocaml_eval_variables

let os_filter os =
  FOp (FIdent ([], OpamVariable.of_string "os", None), `Eq, FString os)

let linux_filter = os_filter "linux"
let macos_filter = os_filter "macos"
let openbsd_filter = os_filter "openbsd"
let freebsd_filter = os_filter "freebsd"
let netbsd_filter = os_filter "netbsd"
let dragonflybsd_filter = os_filter "dragonfly"
let not_bsd_filter =
  FNot (FOr (FOr (openbsd_filter, netbsd_filter),
             FOr (freebsd_filter, dragonflybsd_filter)))
let win32_filter = os_filter "win32"
let not_win32_filter =
  FOp (FIdent ([], OpamVariable.of_string "os", None), `Neq, FString "win32")
let sandbox_filter = FOr (linux_filter, macos_filter)

let gtar_filter = openbsd_filter
let tar_filter = FNot gtar_filter

let getconf_filter = FNot (FOr (win32_filter, freebsd_filter))

let sandbox_wrappers =
  let cmd t = [
    CString "%{hooks}%/sandbox.sh", None;
    CString t, None;
  ] in
  [ `build  [cmd "build", Some sandbox_filter];
    `install  [cmd "install", Some sandbox_filter];
    `remove  [cmd "remove", Some sandbox_filter];
  ]

let wrappers ~sandboxing () =
  let w = OpamFile.Wrappers.empty in
  if sandboxing then
    List.fold_left OpamFile.Wrappers.(fun w -> function
        | `build wrap_build -> { w with wrap_build }
        | `install wrap_install -> { w with wrap_install }
        | `remove wrap_remove -> { w with wrap_remove }
      ) OpamFile.Wrappers.empty sandbox_wrappers
  else w

let bwrap_cmd = "bwrap"
let bwrap_filter = linux_filter
let bwrap_string () = Printf.sprintf
    "Sandboxing tool %s was not found. You should install 'bubblewrap'. \
     See https://opam.ocaml.org/doc/FAQ.html#Why-does-opam-require-bwrap."
    bwrap_cmd

let req_dl_tools () =
  let msg =
    Some "A download tool is required, check env variables OPAMCURL or OPAMFETCH"
  in
  (* Keep synchronised with [OpamRepositoryConfig.default] *)
  let default =
    [
      (* BSDs have download tools (fetch or ftp) that are part of the
         base system so there is no need to check for those tools. *)
      ["curl"; "wget"], msg, Some not_bsd_filter;
    ]
  in
  let open OpamStd.Option.Op in
  let cmd =
    (OpamRepositoryConfig.E.fetch_t ()
     >>= fun s ->
     match OpamStd.String.split s ' ' with
     | c::_ -> Some c
     | _ -> None)
    >>+ fun () -> OpamRepositoryConfig.E.curl_t ()
  in
  match cmd with
  | Some cmd ->
    [[cmd], Some "Custom download tool, check OPAMCURL or OPAMFETCH", None]
  | None -> default

let dl_tool () =
  let open OpamStd.Option.Op in
  (OpamRepositoryConfig.E.fetch_t ()
   >>+ fun () -> OpamRepositoryConfig.E.curl_t ())
  >>| fun cmd -> [(CString cmd), None]

let recommended_tools () =
  let make = OpamStateConfig.(Lazy.force !r.makecmd) in
  [
    [make], None, None;
    ["cc"], None, Some not_win32_filter;
  ]

let required_tools ~sandboxing () =
  req_dl_tools () @
  [
    ["tar"], None, Some tar_filter;
    ["gtar"], None, Some gtar_filter;
    ["unzip"], None, None;
    ["getconf"], None, Some getconf_filter;
  ] @
  if sandboxing then [
    [bwrap_cmd], Some (bwrap_string()), Some bwrap_filter;
    ["sandbox-exec"], None, Some macos_filter;
  ] else []

let required_packages_for_cygwin =
  [
    "make";
    "tar";
    "unzip";
    "rsync";
  ] |> List.map OpamSysPkg.of_string

let init_scripts () = [
  ("sandbox.sh", OpamScript.bwrap), Some bwrap_filter;
  ("sandbox.sh", OpamScript.sandbox_exec), Some macos_filter;
]

module I = OpamFile.InitConfig

let (@|) g f = OpamStd.Op.(g @* f) ()

let init_config ?(sandboxing=true) () =
  I.empty |>
  I.with_repositories
    [OpamRepositoryName.of_string "default", (repository_url, None)] |>
  I.with_default_compiler default_compiler |>
  I.with_default_invariant default_invariant |>
  I.with_eval_variables eval_variables |>
  I.with_wrappers @| wrappers ~sandboxing |>
  I.with_recommended_tools @| recommended_tools |>
  I.with_required_tools @| required_tools ~sandboxing |>
  I.with_init_scripts @| init_scripts |>
  I.with_dl_tool @| dl_tool
