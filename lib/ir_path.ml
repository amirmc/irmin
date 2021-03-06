(*
 * Copyright (c) 2013-2015 Thomas Gazagnaire <thomas@gazagnaire.org>
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

exception Invalid of string

module String_list = struct

  type step = string

  module Step = struct
    include Tc.String
    let to_hum s = s
    let of_hum = function
      | "" -> raise (Invalid "Empty step!")
      | s  -> s
  end

  include Tc.List(Step)

  let empty = []
  let is_empty l = (l = [])
  let cons s t = s :: t
  let rcons t s = t @ [s]

  let decons = function
    | []   -> None
    | h::t -> Some (h, t)

  let rdecons l =
    match List.rev l with
    | []   -> None
    | h::t -> Some (List.rev t, h)

  let map l f = List.map f l
  let create x = x

  let to_hum t =
    let len = List.fold_left (fun acc s -> 1 + acc + Step.size_of s) 1 t in
    let buf = Buffer.create len in
    List.iter (fun s ->
        Buffer.add_char buf '/';
        Buffer.add_string buf (Step.to_hum s)
      ) t;
    Buffer.contents buf

  (* XXX: slow *)
  let of_hum s =
    List.filter ((<>)"") (Stringext.split s ~on:'/')
    |> List.map Step.of_hum

end
