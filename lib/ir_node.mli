(*
 * Copyright (c) 2013      Louis Gesbert     <louis.gesbert@ocamlpro.com>
 * Copyright (c) 2013-2014 Thomas Gazagnaire <thomas@gazagnaire.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

(** Nodes represent structured values serialized in the block
    store. *)

(** The blocks form a labeled directed acyclic graph (DAG). For
    instance, using the following API it is possible to go from one
    node to another following a path in the graph. Every node of the
    graph might carry some optional contents. *)

module type S = sig

  (** Node values. *)

  include Ir_contents.S

  type contents
  (** Type for contents. *)

  type node
  (** Type for nodes. *)

  type 'a step_map
  (** A map of steps. *)

  val contents: t -> contents option
  (** [contents t] is the (optional) key of the node contents. *)

  val contents_exn: t -> contents
  (** Same as [contents], but raise [Not_found] if it is [None]. *)

  val succ: t -> node step_map
  (** Extract the successors of a node. *)

  val edges: t -> [`Contents of contents | `Node of node] list
  (** Return the list of successor vertices. *)

  val empty: t
  (** The empty node. *)

  val leaf: contents -> t
  (** Create a leaf node, with some contents and no successors. *)

  val create: ?contents:contents -> node step_map -> t
  (** [create ~contents succ] is the node with contents [contents] and
      successors [succs]. *)

  val is_empty: t -> bool
  (** Is the node empty. *)

  val is_leaf: t -> bool
  (** Is it a leaf node (see [leaf]) ? *)

end

module type STORE = sig

  (** The node store encodes a labeled DAG where every node might hold
      some contents. *)

  include Ir_ao.STORE

  type contents
  (** Node contents. *)

  type step
  (** A step is used to pass from one node to an other. A list of
      steps forms a path. *)

  module Step: Tc.I0 with type t = step
  (** Base functions over steps. *)

  val empty: value
  (** The empty node. *)

  val node: t -> origin -> ?contents:contents -> ?succ:(step * value) list ->
    unit -> (key * value) Lwt.t
  (** Create a new node. *)

  val contents: t -> origin -> value -> contents Lwt.t option
  (** Return the node contents. *)

  val succ: t -> origin -> value -> value Lwt.t Map.Make(Step).t
  (** Return the node successors. *)

  val sub: t -> origin -> value -> step list -> value option Lwt.t
  (** Find a subvalue. *)

  val sub_exn: t -> origin -> value -> step list -> value Lwt.t
  (** Find a subvalue. Raise [Not_found] if it does not exist. *)

  val map: t -> origin -> value -> step list -> (value -> value) -> value Lwt.t
  (** Modify a subtree. *)

  val update: t -> origin -> value -> step list -> contents -> value Lwt.t
  (** Add a value by recusively saving subvalues into the
      corresponding stores. *)

  val find: t -> origin -> value -> step list -> contents option Lwt.t
  (** Find a value. *)

  val find_exn: t -> origin -> value -> step list -> contents Lwt.t
  (** Find a value. Raise [Not_found] is [path] is not defined. *)

  val remove: t -> origin -> value -> step list -> value Lwt.t
  (** Remove a value. *)

  val valid: t -> origin -> value -> step list -> bool Lwt.t
  (** Is a path valid. *)

  val merge: t -> (key, origin) Ir_merge.t
  (** Merge two nodes together. *)

  module Contents: Ir_contents.STORE
    with type value = contents
     and type origin = origin
  (** The contents store. *)

  module Key: Ir_uid.S with type t = key
  (** Base functions for keys. *)

  module Val: S
    with type t = value
     and type node = key
     and type contents = Contents.key
     and type 'a step_map = 'a Map.Make(Step).t
  (** Base functions for values. *)

end

module type MAKER =
  functor (K: Ir_uid.S) ->
  functor (S: Ir_step.S) ->
  functor (C: Ir_contents.STORE) ->
    STORE with type key = K.t
           and type step = S.t
           and type contents = C.value
           and type origin = C.origin
           and module Contents = C

module Make (Node: Ir_ao.MAKER): MAKER
(** Create a node store from an append-only database. *)

module Rec (S: STORE): Ir_contents.S with type t = S.key
(** Same as [Ir_contents.Rec] but for node stores. *)
