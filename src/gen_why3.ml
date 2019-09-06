open Location

module M = Model
open Tools
open Mlwtree

(* Constants -------------------------------------------------------------------*)

let gArchetypeDir   = "archetype3"
let gArchetypeLib   = "Lib"
let gArchetypeColl  = "AssetCollection"
let gArchetypeSum   = "Sum"
let gArchetypeList  = "IntListUtils"
let gArchetypeTrace = "Trace"

let mk_id i          = "_"^i

let mk_ac_id a        = mk_id (a^"_assets")
let mk_ac_added_id a  = mk_id (a^"_assets_added")
let mk_ac_rmed_id a   = mk_id (a^"_assets_removed")

let gs                = "_s"

let mk_ac a           = Tdoti (gs, mk_ac_id a)
let mk_ac_old a       = Tdot (Told (Tvar gs), Tvar (mk_ac_id a))

let mk_ac_added a     = Tdoti (gs, mk_ac_added_id a)
let mk_ac_old_added a = Tdot (Told (Tvar gs), Tvar (mk_ac_added_id a))

let mk_ac_rmed a      = Tdoti (gs, mk_ac_rmed_id a)
let mk_ac_old_rmed a  = Tdot (Told (Tvar gs), Tvar (mk_ac_rmed_id a))

let mk_ac_sv s a      = Tdoti (s, mk_ac_id a)

(* Use ---------------------------------------------------------------------------*)

let mk_use = Duse [gArchetypeDir;gArchetypeLib] |> loc_decl |> deloc
let mk_use_list = Duse ["list";"List"] |> loc_decl |> deloc
let mk_use_module m = Duse [deloc m]  |> loc_decl |> deloc

(* Trace -------------------------------------------------------------------------*)

type change =
  | CAdd of ident
  | CRm of ident
  | CUpdate of ident
  | CTransfer of ident
  | CGet of ident
  | CIterate of ident
  | CCall of ident

let mk_change_term tr =
  match tr with
  | CAdd id -> Tapp (Tdoti("Tr",
                          "TrAdd_"),
                    [Tvar (String.capitalize_ascii id)])
  | CRm id -> Tapp (Tdoti("Tr",
                         "TrRm_"),
                   [Tvar (String.capitalize_ascii id)])
  | CUpdate id -> Tapp (Tdoti("Tr",
                             "TrUpdate_"),
                       [Tvar (String.capitalize_ascii id)])
  | CGet id -> Tapp (Tdoti("Tr",
                          "TrGet_"),
                    [Tvar (String.capitalize_ascii id)])
  | _ -> assert false

let mk_trace tr =
  let gstr = Tdoti(gs,
                   mk_id "tr") in
  Tassign (gstr,
           Tcons (mk_change_term tr,
                  gstr)
          ) |> loc_term

let mk_trace_asset m =
  Denum ("_asset",
         M.Utils.get_assets m
         |> List.map (fun (a : M.info_asset) -> String.capitalize_ascii a.name))
  |> loc_decl

let mk_trace_entry m =
  Denum ("_entry",
         M.Utils.get_entries m
         |> List.map (fun (_, (f : M.function_struct)) -> String.capitalize_ascii (unloc f.name)))
  |> loc_decl

let mk_trace_field m =
  Denum ("_field",
         (M.Utils.get_variables m
          |> List.map (fun (v : M.storage_item) -> String.capitalize_ascii (unloc v.name))) @
         (M.Utils.get_assets m
          |> List.map (fun (a : M.info_asset) ->
              List.map (fun (n,_,_) -> String.capitalize_ascii n) a.values
            )
          |> List.flatten))
  |> loc_decl

let mk_trace_clone () =
  Dclone ([gArchetypeDir;gArchetypeTrace], "Tr",
          [Ctype ("_asset","_asset");
           Ctype ("_entry","_entry");
           Ctype ("_field","_field")])
  |> loc_decl

let mk_trace_utils m =
  if M.Utils.with_trace m then [
    mk_trace_asset m;
    mk_trace_entry m;
    mk_trace_field m;
    mk_trace_clone ()
  ] else []

(* Storage -----------------------------------------------------------------------*)

let mk_default_init = function
  | Drecord (n,fs) ->
    Dfun {
      name     = "mk_default_"^n;
      logic    = NoMod;
      args     = [];
      returns  = Tyasset n;
      raises   = [];
      variants = [];
      requires = [];
      ensures  = [];
      body     = Trecord (None, List.map (fun (f:field) ->
          f.name, f.init
        ) fs);
    }
  | _ -> assert false


let mk_collection_field asset to_id = {
  name     = with_dummy_loc (to_id asset);
  typ      = loc_type (Tycoll asset);
  init     = loc_term (Temptycoll asset);
  mutable_ = true;
}

let mk_const_fields m = [
  { name = mk_id "ops"   ; typ = Tyrecord "transfers" ; init = Tvar "Nil"; mutable_ = true; };
  { name = mk_id "balance" ;     typ = Tytez; init = Tint Big_int.zero_big_int; mutable_ = false; };
  { name = mk_id "transferred" ; typ = Tytez; init = Tint Big_int.zero_big_int; mutable_ = false; };
  { name = mk_id "caller"    ; typ = Tyaddr;  init = Tint Big_int.zero_big_int; mutable_ = false; };
  { name = mk_id "now"       ; typ = Tydate;  init = Tint Big_int.zero_big_int; mutable_ = false; }
] @
  if M.Utils.with_trace m then
    [
      { name = mk_id "entry"     ; typ = Tyoption (Tyasset "_entry"); init = Tnone; mutable_ = false; };
      { name = mk_id "tr"        ; typ = Tyasset ("Tr._traces"); init = Tnil; mutable_ = true; }
    ]
  else []

let mk_sum_clone_id a f = (String.capitalize_ascii a) ^ (String.capitalize_ascii f)

let mk_sum_clone m asset key field =
  let cap_asset = String.capitalize_ascii asset in
  Dclone ([gArchetypeDir;gArchetypeSum],
          mk_sum_clone_id asset field,
          [Ctype ("container",
                  cap_asset^".collection");
           Ctype ("t",
                  asset);
           Cval ("f",
                 "get_"^field);
           Cval ("field",
                 field);
           Cval ("card",
                 cap_asset^".card");
           Cfun ("union",
                 cap_asset^".union");
           Cfun ("inter",
                 cap_asset^".inter");
           Cfun ("diff",
                 cap_asset^".diff");
           Cpred("is_empty",
                 cap_asset^".is_empty");
           Cpred("subset",
                 cap_asset^".subset");
           Cval ("singleton",
                 cap_asset^".singleton");
           Cval ("witness",
                 cap_asset^".witness");
           Cval ("keyf",
                 key);
          ])


(* n is the asset name
   f is the name of the key field
   ktyp is the key type
*)
let mk_keys_eq_axiom n f ktyp : decl =
  Dtheorem (Axiom,
            "eq_"^n^"_keys",
            Tforall ([["s"],Tystorage;["k"],ktyp],
                     Timpl (Tmem (n,
                                  Tvar "k",
                                  Tdoti ("s",n^"_keys")),
                            Teq (Tyint,
                                 Tapp (Tvar f,
                                       [Tget (n,
                                              Tdoti ("s",n^"_assets"),
                                              Tvar "k")]),
                                 Tvar "k"))))

(* asset is the asset name
   f is the partition field name
   kt is the key type
   pa is the partitionned asset name
   kpt is the partionned asset key type
*)
let mk_partition_axiom asset f kt pa kpt : decl =
  Dtheorem (Axiom,
            asset^"_"^f^"_is_partition",
            Tforall ([["s"],Tystorage;["a"],Tyasset asset;["k"],kpt],
                     Timpl (Tmem (asset,
                                  Tvar("a"),
                                  mk_ac_sv "s" asset),
                            Timpl (Tlmem (gArchetypeList,
                                          Tvar "k",
                                          Tapp (Tvar f,
                                                [Tvar "a"])),
                                   Tcontains (pa,
                                              Tvar "k",
                                              mk_ac_sv "s" pa)))))

(* Select --------------------------------------------------------------------*)

(* TODO : complete mapping *)
let rec mk_select_test = function
  | Tdot (Tvar v,f) when compare v "the" = 0 -> Tdot (Tvar "a",f)
  | Tnow _ -> Tvar (mk_id "now")
  | _ as t -> map_abstract_term mk_select_test id id t

let mk_select_body asset mlw_test : term =
  let capa = String.capitalize_ascii asset in
  Tletfun (
    {
      name     = "internal_select";
      logic    = Rec;
      args     = ["l",Tylist (Tyasset asset)];
      returns  = Tylist (Tyasset asset);
      raises   = [];
      variants = [Tvar "l"];
      requires = [];
      ensures  = [];
      body     = Tmlist (Tnil,"l","a","tl",
                         Tif(mk_select_test mlw_test,
                             Tcons (Tvar "a",Tapp (Tvar ("internal_select"),[Tvar "tl"])),
                             Some (Tapp (Tvar ("internal_select"),[Tvar "tl"])))
                        );
    },
    Trecord (
      None,
      [capa^".content", Tapp (Tvar "internal_select",[Tdoti("c."^capa,"content")])]
    )
  )

(* argument extraction is done on model's term because it is typed *)
let extract_args test =
  let rec internal_extract_args acc (term : M.mterm) =
    match term.M.node with
    | M.Mnow -> acc @ [term,mk_id "now", Tydate]
    | _ -> M.fold_term internal_extract_args acc term in
  internal_extract_args [] test

let get_select_id (m : M.model) asset test =
  let rec internal_get_select_id acc = function
    | (sc : M.api_item) :: tl ->
      begin
        match sc.node_item with
        | M.APIFunction (Select (a,t)) ->
          if compare a asset = 0 then
            if M.cmp_mterm t test then
              acc + 1
            else
              internal_get_select_id (acc + 1) tl
          else
            internal_get_select_id acc tl
        | _ -> internal_get_select_id acc tl
      end
    | [] -> acc in
  internal_get_select_id 0 m.api_items

let mk_select_name m asset test = "select_"^asset^"_"^(string_of_int (get_select_id m asset test))

let mk_select m asset test mlw_test only_formula =
  let id =  mk_select_name m asset test in
  let decl = Dfun {
      name     = id;
      logic    = if only_formula then Logic else NoMod;
      args     = (extract_args test |> List.map (fun (_,a,b) -> a,b)) @ ["c",Tycoll asset];
      returns  = Tycoll asset;
      raises   = [];
      variants = [];
      requires = [];
      ensures  = [
        { id   = id^"_post_1";
          form = Tforall (
              [["a"],Tyasset asset],
              Timpl (Tmem (asset,Tvar "a",Tresult),
                     mk_select_test mlw_test
                    )
            );
        };
        { id   = id^"_post_2";
          form = Tsubset (asset,
                          Tresult,
                          Tvar "c");
        }
      ];
      body     = mk_select_body asset mlw_test;
    } in
  decl

(* Utils ----------------------------------------------------------------------*)

let wdl (l : 'a list)  = List.map with_dummy_loc l
let unloc_decl = List.map unloc_decl
let loc_decl   = List.map loc_decl
let loc_field  = List.map loc_field
let deloc (l : 'a list) = List.map deloc l

let rec zip l1 l2 l3 l4 =
  match l1,l2,l3,l4 with
  | e1::tl1,e2::tl2,e3::tl3,e4::tl4 -> e1::e2::e3::e4::(zip tl1 tl2 tl3 tl4)
  | _ -> []

let cap s = mk_loc s.loc (String.capitalize_ascii s.obj)

(* Map model term -------------------------------------------------------------*)

let map_lident (i : M.lident) : loc_ident = {
  obj = i.pldesc;
  loc = i.plloc;
}

let map_lidents = List.map map_lident

let type_to_init (typ : loc_typ) : loc_term =
  mk_loc typ.loc (match typ.obj with
      | Typartition i -> Temptycoll i
      | Tycoll i      -> Temptycoll i
      | Tylist _      -> Tnil
      | Tymap i       -> Tvar (mk_loc typ.loc ("const (mk_default_"^i.obj^" ())"))
      | _             -> Tint Big_int.zero_big_int)

let map_btype = function
  | M.Bbool          -> Tybool
  | M.Bint           -> Tyint
  | M.Brational      -> Tyrational
  | M.Bdate          -> Tydate
  | M.Bduration      -> Tyduration
  | M.Bstring        -> Tystring
  | M.Baddress       -> Tyaddr
  | M.Brole          -> Tyrole
  | M.Bcurrency _    -> Tytez
  | M.Bkey           -> Tykey

let rec map_mtype (t : M.type_) : loc_typ =
  with_dummy_loc (match t with
      | M.Tasset id                           -> Tyasset (map_lident id)
      | M.Tenum id                            -> Tyenum (map_lident id)
      | M.Tbuiltin v                          -> map_btype v
      | M.Tcontainer (Tasset id,M.Partition)  -> Typartition (map_lident id)
      | M.Tcontainer (Tasset id,M.Collection) -> Tycoll (map_lident id)
      | M.Tcontainer (t,M.Collection)         -> Tylist (map_mtype t).obj
      | M.Toption t                           -> Tyoption (map_mtype t).obj
      | M.Ttuple l                            -> Tytuple (l |> List.map map_mtype |> deloc)
      | M.Tunit                               -> Tyunit
      | _ -> assert false)

let rec map_term (t : M.mterm) : loc_term = mk_loc t.loc (
    match t.node with
    | M.Maddress v  -> Tint (sha v)
    | M.Mint i      -> Tint i
    | M.Mvarlocal i -> Tvar (map_lident i)
    | M.Mgt (t1,t2) -> Tgt (with_dummy_loc Tyint,map_term t1,map_term t2)
    | _ ->
      let str = Format.asprintf "Not translated : %a@." M.pp_mterm t in
      print_endline str;
      Tnottranslated
  )

let map_record_term _ = map_term

let map_record_values (values : M.record_item list) =
  List.map (fun (value : M.record_item) ->
      let typ_ = map_mtype value.type_ in
      let init_value = type_to_init typ_ in {
        name     = map_lident value.name;
        typ      = typ_;
        init     = Option.fold map_record_term init_value value.default;
        mutable_ = false;
      }
    ) values

let map_storage_items = List.fold_left (fun acc (item : M.storage_item) ->
    acc @
    match item.typ with
    | M.Tcontainer (Tasset id, Collection) ->
      let id = unloc id in [
        mk_collection_field id mk_ac_id;
        mk_collection_field id mk_ac_added_id;
        mk_collection_field id mk_ac_rmed_id
      ]
    | _ ->
      let typ_ = map_mtype item.typ in
      let init_value = type_to_init typ_ in
      [{
        name     = item.name |> unloc |> with_dummy_loc;
        typ      = typ_;
        init     = map_record_term init_value item.default;
        mutable_ = true;
      }]
  ) []

let is_local_invariant m an t =
  let rec internal_is_local acc (term : M.mterm) =
    match term.M.node with
    | M.Mforall (i,M.Tasset a,_,b) -> not (compare (a |> unloc) an = 0)
    | M.Msum (a,_,_) -> not (compare a an = 0)
    | M.Mmax (a,_,_) -> not (compare a an = 0)
    | M.Mmin (a,_,_) -> not (compare a an = 0)
    | M.Mselect (a,_,_) -> not (compare a an = 0)
    | _ -> M.fold_term internal_is_local acc term in
  internal_is_local true t

let adds_asset m an b =
  let rec internal_adds acc (term : M.mterm) =
    match term.M.node with
    | M.Maddasset (a,_) ->  compare a an = 0
    | M.Maddfield (a,f,_,_) ->
      let (pa,_,_) = M.Utils.get_partition_asset_key m (dumloc a) (dumloc f) in
      compare pa an = 0
    | _ -> M.fold_term internal_adds acc term in
  internal_adds false b

let is_security (t : M.mterm) =
  match t.M.node with
  | M.MOnlyByRole _ -> true
  | M.MOnlyInAction _ -> true
  | M.MOnlyByRoleInAction _ -> true
  | _ -> false

let map_action_to_change = function
  | M.ADadd i      -> CAdd i
  | M.ADremove i   -> CRm i
  | M.ADupdate i   -> CUpdate i
  | M.ADtransfer i -> CTransfer i
  | M.ADget i      -> CGet i
  | M.ADiterate i  -> CIterate i
  | M.ADcall i     -> CCall i
  | _ -> assert false

let map_security_pred loc (t : M.mterm) =
  let vars =
    ["tr";"caller";"entry"]
    |> List.map mk_id
    |> List.map (fun v ->
        match loc with
        | `Storage -> Tvar (v)
        | `Loop    -> Tdoti(gs,v)
      )
  in
  let tr = List.nth vars 0 in
  let caller = List.nth vars 1 in
  let entry = List.nth vars 2 in
  let mk_eq a b = Teq (Tyint,a,Tvar b) in
  let mk_performed_by t l =
    Tapp (Tvar "Tr.performed_by",
          [tr;
           List.fold_left (fun acc r ->
               Tor (acc,mk_eq t r)
             ) (mk_eq t (List.hd l)) (List.tl l) ])
  in
  let mk_changes_performed_by t a l =
    Tapp (Tvar "Tr.changes_performed_by",
          [tr;
           Tcons (map_action_to_change a |> mk_change_term,Tnil);
           List.fold_left (fun acc r ->
               Tor (acc,mk_eq t r)
             ) (mk_eq t (List.hd l)) (List.tl l) ])
  in
  let mk_performed_by_2 t1 t2 l1 l2 =
    Tapp (Tvar "Tr.performed_by",
          [tr;
           Tand (
             List.fold_left (fun acc r ->
                 Tor (acc,mk_eq t1 r)
               ) (mk_eq t1 (List.hd l1)) (List.tl l2),
             List.fold_left (fun acc r ->
                 Tor (acc,mk_eq t2 r)
               ) (mk_eq t2 (List.hd l1)) (List.tl l2))])
  in
  let mk_changes_performed_by_2 t1 t2 a l1 l2 =
    Tapp (Tvar "Tr.performed_by",
          [tr;
           Tcons (map_action_to_change a |> mk_change_term,Tnil);
           Tand (
             List.fold_left (fun acc r ->
                 Tor (acc,mk_eq t1 r)
               ) (mk_eq t1 (List.hd l1)) (List.tl l2),
             List.fold_left (fun acc r ->
                 Tor (acc,mk_eq t2 r)
               ) (mk_eq t2 (List.hd l1)) (List.tl l2))])
  in
  match t.M.node with
  | M.MOnlyByRole (ADany,roles)     -> mk_performed_by caller (roles |> List.map unloc)
  | M.MOnlyInAction (ADany,entries) -> mk_performed_by entry (entries |> List.map unloc)
  | M.MOnlyByRole (a,roles)         -> mk_changes_performed_by caller a (roles |> List.map unloc)
  | M.MOnlyInAction (a,entries)     -> mk_changes_performed_by entry a (entries |> List.map unloc)
  | M.MOnlyByRoleInAction (ADany,roles,entries) ->
    mk_performed_by_2 caller entry (roles |> List.map unloc) (entries |> List.map unloc)
  | M.MOnlyByRoleInAction (a,roles,entries) ->
    mk_changes_performed_by_2 caller entry a (roles |> List.map unloc) (entries |> List.map unloc)
  | _ -> Tnottranslated

let mk_spec_invariant loc (spec : M.specification) =
  if is_security spec.formula then
    [
      {
        id = map_lident spec.name;
        form = with_dummy_loc Tnone;
      }
    ]
  else []

(* prefixes with 'forall k_:key, mem k_ "asset"_keys ->  ...'
   replaces asset field "field" by '"field " (get "asset"_assets k_)'
   TODO : make sure there is no collision between "k_" and invariant vars

   m is the Model
   n is the asset name
   inv is the invariant to extend
*)

(* f --> f a *)
let mk_app_field (a : ident) (f : loc_ident) : loc_term * loc_term  =
  let arg   : term     = Tvar a in
  let loc_f : loc_term = mk_loc f.loc (Tvar f) in
  (loc_f,with_dummy_loc (Tapp (loc_f,[loc_term arg])))

let mk_invariant m n src inv : loc_term =
  let r        = M.Utils.get_info_asset m n in
  let fields   = r.values |> List.map (fun (i,_,_) -> i) |> wdl in
  let asset    = map_lident n in
  let variable =
    match src with
    | `Preasset arg -> arg
    | _ -> "a" in
  let replacements = List.map (fun f -> mk_app_field variable f) fields in
  let replacing = List.fold_left (fun acc (t1,t2) -> loc_replace t1 t2 acc) inv replacements in
  match src with
  | `Preasset _ -> replacing
  | _ ->
    let mem_pred =
      match src with
      | `Storage -> Tmem ((unloc_ident asset),
                          Tvar variable,
                          Tvar (mk_ac_id asset.obj))
      | `Loop    -> Tmem ((unloc_ident asset),
                          Tvar variable,
                          mk_ac (unloc n))
      | `Prelist arg ->
        Tapp (Tvar ((String.capitalize_ascii (unloc n))^".internal_mem"),
              [Tvar variable; Tvar arg])
      | `Precoll arg -> Tmem ((unloc_ident asset),
                              Tvar variable,
                              Tvar arg)
      | _ -> Tnone
    in
    let prefix   = Tforall ([[variable],Tyasset (unloc_ident asset)],
                            Timpl (mem_pred,
                                   Ttobereplaced)) in
    loc_replace (with_dummy_loc Ttobereplaced) replacing (loc_term prefix)

let mk_storage_invariant m n (lt : M.label_term) = {
  id = Option.fold (fun _ x -> map_lident x)  (with_dummy_loc "") lt.label;
  form = mk_invariant m n `Storage (map_term lt.term);
}

let mk_pre_list m n arg inv : loc_term = mk_invariant m (dumloc n) (`Prelist arg) inv

let mk_pre_coll m n arg inv : loc_term = mk_invariant m (dumloc n) (`Precoll arg) inv

let mk_pre_asset m n arg inv : loc_term = mk_invariant m (dumloc n) (`Preasset arg) inv

let mk_loop_invariant m n inv : loc_term = mk_invariant m (dumloc n) `Loop inv

let mk_eq_asset m (r : M.record) =
  let cmps = List.map (fun (item : M.record_item) ->
      let f1 = Tdoti("a1",unloc item.name) in
      let f2 = Tdoti("a2",unloc item.name) in
      match item.type_ with
      | Tcontainer _ -> Tapp (Tvar "eql",[f1;f2])
      | _ ->            Teq (Tyint,f1,f2)
    ) r.values in
  Dfun  {
    name = "eq_"^(unloc r.name) |> with_dummy_loc;
    logic = Logic;
    args = ["a1" |> with_dummy_loc, Tyasset (map_lident r.name) |> with_dummy_loc;
            "a2" |> with_dummy_loc, Tyasset (map_lident r.name) |> with_dummy_loc];
    returns = Tybool |> with_dummy_loc;
    raises = [];
    variants = [];
    requires = [];
    ensures = [];
    body = List.fold_left (fun acc cmp ->
        Tpand (acc,cmp)
      ) (List.hd cmps) (List.tl cmps) |> loc_term;
  }

let mk_eq_extensionality m (r : M.record) : loc_decl =
  let asset = unloc r.name in
  Dtheorem (Lemma,
            asset^"_extensionality",
            Tforall ([["a1";"a2"],Tyasset asset],
                     Timpl (Tapp (Tvar ("eq_"^asset),
                                  [Tvar "a1";Tvar "a2"]),
                            Teq (Tyasset asset,Tvar "a1",Tvar "a2")
                           ))) |> Mlwtree.loc_decl

let map_record m (r : M.record) =
  Drecord (map_lident r.name, map_record_values r.values)

let record_to_clone m (r : M.info_asset) =
  let (key,_) = M.Utils.get_asset_key m (dumloc r.name) in
  let sort =
    if List.length r.sort > 0 then
      List.hd r.sort
    else key in (* asset are sorted on key be default *)
  Dclone ([gArchetypeDir;gArchetypeColl] |> wdl,
          String.capitalize_ascii r.name |> with_dummy_loc,
          [Ctype ("t" |> with_dummy_loc, r.name |> with_dummy_loc);
           Cval  ("keyf" |> with_dummy_loc, key |> with_dummy_loc);
           Cval  ("sortf" |> with_dummy_loc, sort |> with_dummy_loc);
           Cval  ("eqf" |> with_dummy_loc, "eq_"^r.name |> with_dummy_loc)])

let map_storage m (l : M.storage) =
  Dstorage {
    fields     = (map_storage_items l)@ (mk_const_fields m |> loc_field |> deloc);
    invariants = List.concat (List.map (fun (item : M.storage_item) ->
        List.map (mk_storage_invariant m item.name) item.invariants) l) @
                 (List.fold_left (fun acc spec ->
                      acc @ (mk_spec_invariant `Storage spec)) [] m.verification.specs)
  }

let mk_axioms (m : M.model) =
  let records = M.Utils.get_assets m |> List.map (fun (r : M.info_asset) -> dumloc (r.name)) in
  let keys    = records |> List.map (M.Utils.get_asset_key m) in
  List.map2 (fun r (k,kt) ->
      mk_keys_eq_axiom r.pldesc k (map_btype kt)
    ) records keys |> loc_decl |> deloc

let mk_partition_axioms (m : M.model) =
  M.Utils.get_partitions m |> List.map (fun (n,i,_) ->
      let kt     = M.Utils.get_asset_key m (dumloc n) |> snd |> map_btype in
      let pa,_,pkt  = M.Utils.get_partition_asset_key m (dumloc n) (dumloc i) in
      mk_partition_axiom n i kt pa (pkt |> map_btype)
    ) |> loc_decl |> deloc

let rec get_record id = function
  | Drecord (n,_) as r :: tl when compare id n = 0 -> r
  | _ :: tl -> get_record id tl
  | [] -> assert false

let get_record_name = function
  | Drecord (n,_) -> n
  | _ -> assert false

let mk_var (i : ident) = Tvar i

let get_for_fun = function
  | M.Tcontainer (Tasset a,_) -> (fun (t1,t2) -> loc_term (Tnth  (unloc a,t1,t2))),
                                 (fun t ->       loc_term (Tcard (unloc a,t)))
  | _ -> assert false


type logical_mod = Nomod | Added | Removed

type logical_context = {
  old  : bool;
  lmod : logical_mod;
}

let init_ctx = {
  old = false;
  lmod = Nomod;
}

let mk_trace_seq m t chs =
  if M.Utils.with_trace m then
    Tseq ([with_dummy_loc t] @ (List.map mk_trace chs))
  else t

let rec map_mterm m ctx (mt : M.mterm) : loc_term =
  let t =
    match mt.node with
    | M.Mif (c,t,Some { node=M.Mseq []; type_=_})  ->
      Tif (map_mterm m ctx c, map_mterm m ctx t, None)
    | M.Mif (c,t,e)  -> Tif (map_mterm m ctx c, map_mterm m ctx t, Option.map (map_mterm m ctx) e)
    | M.Mnot c       -> Tnot (map_mterm m ctx c)
    | M.Mfail InvalidCaller -> Traise Einvalidcaller
    | M.Mfail NoTransfer -> Traise Enotransfer
    | M.Mfail (InvalidCondition _) -> Traise Einvalidcondition
    | M.Mfail _      -> Traise Enotfound
    | M.Mequal (l,r) -> Teq (with_dummy_loc Tyint,map_mterm m ctx l,map_mterm m ctx r)
    | M.Mcaller      -> Tcaller (with_dummy_loc gs)
    | M.Mtransferred -> Ttransferred (with_dummy_loc gs)
    | M.Mvarstorevar v  -> Tdoti (with_dummy_loc gs, map_lident v)
    | M.Mcurrency (v,_) -> Tint v
    | M.Mgt (l, r)      -> Tgt (with_dummy_loc Tyint, map_mterm m ctx l, map_mterm m ctx r)
    | M.Mge (l, r)      -> Tge (with_dummy_loc Tyint, map_mterm m ctx l, map_mterm m ctx r)
    | M.Mlt (l, r)      -> Tlt (with_dummy_loc Tyint, map_mterm m ctx l, map_mterm m ctx r)
    | M.Mle (l, r)      -> Tle (with_dummy_loc Tyint, map_mterm m ctx l, map_mterm m ctx r)
    | M.Mvarlocal v     -> Tvar (map_lident v)
    | M.Mvarparam v     -> Tvar (map_lident v)
    | M.Mint v          -> Tint v
    | M.Mdotasset (e,i) -> Tdot (map_mterm m ctx e, mk_loc (loc i) (Tvar (map_lident i)))
    | M.Munshallow (a,e) ->
      Tapp (loc_term (Tvar ("unshallow_"^a)),
            [map_mterm m ctx (M.mk_mterm (M.Mvarstorecol (dumloc a))
                                (M.Tcontainer (Tasset (dumloc a),Collection)));
             map_mterm m ctx e])
    | M.Mshallow (a,e) -> Tapp (loc_term (Tvar ("shallow_"^a)),[map_mterm m ctx e])
    | M.Mcontains (a,_,r) -> Tapp (loc_term (Tvar ("contains_"^a)),[map_mterm m ctx r])
    | M.Maddfield (a,f,c,i) ->
      let t,_,_ = M.Utils.get_partition_asset_key m (dumloc a) (dumloc f) in
      mk_trace_seq m
        (Tapp (loc_term (Tvar ("add_"^a^"_"^f)),
               [map_mterm m ctx c; map_mterm m ctx i]))
        [CUpdate f; CAdd t]
    | M.Mget (n,k) -> Tapp (loc_term (Tvar ("get_"^n)),[map_mterm m ctx k])
    | M.Maddshallow (n,l) ->
      let pa = M.Utils.get_partition_assets m n |> List.map (fun a ->
          CAdd (String.capitalize_ascii a)) in
      mk_trace_seq m
        (Tapp (loc_term (Tvar ("add_shallow_"^n)),List.map (map_mterm m ctx) l))
        ([CAdd n] @ pa)
    | M.Maddasset (n,i) ->
      mk_trace_seq m
        (Tapp (loc_term (Tvar ("add_"^n)),[map_mterm m ctx i ]))
        [CAdd n]
    | M.Mrecord l ->
      let asset = M.Utils.get_asset_type mt in
      let fns = M.Utils.get_field_list m asset |> wdl in
      Trecord (None,(List.combine fns (List.map (map_mterm m ctx) l)))
    | M.Mlisttocoll (n,l) -> Tapp (loc_term (Tvar ("listtocoll_"^n)),[map_mterm m ctx l])
    | M.Marray l ->
      begin
        match mt.type_ with
        | Tcontainer (_,_) -> Tlist (l |> List.map (map_mterm m ctx))
        | _ -> assert false
      end
    | M.Mletin ([id],v,_,b) ->
      Tletin (M.Utils.is_local_assigned id b,map_lident id,None,map_mterm m ctx v,map_mterm m ctx b)
    | M.Mselect (a,l,r) ->
      let args = extract_args r in
      let id = mk_select_name m a r in
      let argids = args |> List.map (fun (e,_,_) -> e) |> List.map (map_mterm m ctx) in
      Tapp (loc_term (Tvar id),argids @ [map_mterm m ctx l])
    | M.Mnow -> Tnow (with_dummy_loc gs)
    | M.Mseq l -> Tseq (List.map (map_mterm m ctx) l)
    | M.Mfor (id,c,b,lbl) ->
      let (nth,card) = get_for_fun c.type_ in
      Tfor (with_dummy_loc "i",
            with_dummy_loc (
              Tminus (with_dummy_loc Tyunit,card (map_mterm m ctx c |> unloc_term),
                      (loc_term (Tint Big_int.unit_big_int)))
            ),
            mk_invariants m ctx lbl b,
            with_dummy_loc (
              Tletin (false,
                      map_lident id,
                      None,
                      nth (Tvar "i",map_mterm m ctx c |> unloc_term),
                      map_mterm m ctx b)))
    | M.Massign (ValueAssign,id,v) -> Tassign (with_dummy_loc (Tvar (map_lident id)),map_mterm m ctx v)
    | M.Massign (MinusAssign,id,v) -> Tassign (with_dummy_loc (Tvar (map_lident id)),
                                               with_dummy_loc (
                                                 Tminus (with_dummy_loc Tyint,
                                                         with_dummy_loc (Tvar (map_lident id)),
                                                         map_mterm m ctx v)))
    | M.Massignfield (ValueAssign,id1,id2,v) ->
      let id = with_dummy_loc (Tdoti (map_lident id1,map_lident id2)) in
      Tassign (id,map_mterm m ctx v)
    | M.Massignfield (MinusAssign,id1,id2,v) ->
      let id = with_dummy_loc (Tdoti (map_lident id1,map_lident id2)) in
      Tassign (id,
               with_dummy_loc (
                 Tminus (with_dummy_loc Tyint,
                         id,
                         map_mterm m ctx v)))
    | M.Mset (a,l,k,v) ->
      mk_trace_seq m
        (Tletin (false,
                 with_dummy_loc ("_old"^a),
                 None,
                 with_dummy_loc (Tapp (loc_term (Tvar ("get_"^a)),
                                       [map_mterm m ctx k])),
                 with_dummy_loc (Tapp (loc_term (Tvar ("set_"^a)),
                                       [
                                         loc_term (Tvar ("_old"^a));
                                         map_mterm m ctx v
                                       ]))))
        (List.map (fun f -> CUpdate f) l)
    | M.Mremovefield (a,f,k,v) ->
      let t,_,_ = M.Utils.get_partition_asset_key m (dumloc a) (dumloc f) in
      mk_trace_seq m
        (Tletin (false,
                 with_dummy_loc ("_rm"^t),
                 None,
                 with_dummy_loc (Tapp (loc_term (Tvar ("get_"^t)),
                                       [map_mterm m ctx v])),
                 with_dummy_loc (Tapp (loc_term (Tvar ("remove_"^a^"_"^f)),
                                       [
                                         map_mterm m ctx k;
                                         loc_term (Tvar ("_rm"^t))
                                       ]
                                      ))))
        [CUpdate f; CRm t]
    | M.Mremoveasset (n,a) ->
      mk_trace_seq m
        (Tletin (false,
                 with_dummy_loc ("_rm"^n),
                 None,
                 with_dummy_loc (Tapp (loc_term (Tvar ("get_"^n)),
                                       [map_mterm m ctx a])),
                 with_dummy_loc (Tapp (loc_term (Tvar ("remove_"^n)),
                                       [loc_term (Tvar ("_rm"^n))]))))
        [CRm n]
    | M.Msum (a,f,l) ->
      Tapp (loc_term (Tvar ((mk_sum_clone_id a (f |> unloc))^".sum")),[map_mterm m ctx l])
    | M.Mapp (f,args) ->
      Tapp (mk_loc (map_lident f).loc (Tvar (map_lident f)),List.map (map_mterm m ctx) args)
    | M.Mminus (l,r) -> Tminus (with_dummy_loc Tyint, map_mterm m ctx l, map_mterm m ctx r)
    | M.Mplus (l,r)  -> Tplus  (with_dummy_loc Tyint, map_mterm m ctx l, map_mterm m ctx r)
    | M.Mvarstorecol n ->
      let coll =
        match ctx.old, ctx.lmod with
        | false, Nomod   -> mk_ac (n |> unloc)
        | false, Added   -> mk_ac_added (n |> unloc)
        | false, Removed -> mk_ac_rmed (n |> unloc)
        | true, Nomod    -> mk_ac_old (n |> unloc)
        | true, Added    -> mk_ac_old_added (n |> unloc)
        | true, Removed  -> mk_ac_old_rmed (n |> unloc)
      in
      loc_term coll |> Mlwtree.deloc
    | M.Msetbefore c -> map_mterm m { ctx with old = true } c |> Mlwtree.deloc
    | M.Msetadded c ->  map_mterm m { ctx with lmod = Added } c |> Mlwtree.deloc
    | M.Msetremoved c -> map_mterm m { ctx with lmod = Removed } c |> Mlwtree.deloc
    | M.Mforall (i,t,None,b) ->
      let asset = M.Utils.get_asset_type (M.mk_mterm (M.Mbool false) t) |> unloc in
      Tforall (
        [[i |> map_lident],loc_type (Tyasset asset)],
        map_mterm m ctx b)
    | M.Mforall (i,t,Some coll,b) ->
      let asset = M.Utils.get_asset_type (M.mk_mterm (M.Mbool false) t) |> unloc in
      Tforall (
        [[i |> map_lident],loc_type (Tyasset asset)],
        with_dummy_loc (Timpl (with_dummy_loc (Tmem (with_dummy_loc asset,
                                                     loc_term (Tvar (unloc i)),
                                                     map_mterm m ctx coll)),
                               map_mterm m ctx b)))
    | M.Mmem (a,e,c) -> Tmem (with_dummy_loc a, map_mterm m ctx e, map_mterm m ctx c)
    | M.Mimply (a,b) -> Timpl (map_mterm m ctx a, map_mterm m ctx b)
    | M.Mlabel lbl ->
      begin
        match M.Utils.get_formula m None (unloc lbl) with
        | Some formula -> Tassert (map_mterm m ctx formula)
        | _ -> assert false
      end
    | M.Mand (l,r)-> Tand (map_mterm m ctx l,map_mterm m ctx r)
    | M.Misempty (l,r) -> Tempty (with_dummy_loc l,map_mterm m ctx r)
    | M.Msubset (n,l,r) -> Tsubset (with_dummy_loc n,map_mterm m ctx l,map_mterm m ctx r)
    | M.Msettoiterate c ->
      let n = M.Utils.get_asset_type mt |> map_lident in
      Ttoiter (n,with_dummy_loc "i",map_mterm m ctx c) (* TODO : should retrieve actual idx value *)
    | _ -> Tnone in
  mk_loc mt.loc t
and mk_invariants (m : M.model) ctx (lbl : ident option) lbody =
  let loop_invariants =
    Option.fold (M.Utils.get_loop_invariants m) [] lbl |>
    List.map (fun ((ilbl : M.lident),(i : M.mterm)) ->
        let iid =
          match lbl,ilbl with
          | Some a, b -> (unloc b) ^ "_" ^ a
          | None, b -> (unloc b) in
        { id =  with_dummy_loc iid; form = map_mterm m ctx i }
      ) in
  let storage_loop_invariants =
    M.Utils.get_storage_invariants m None |>
    List.fold_left (fun acc (an,inn,t) ->
        if is_local_invariant m an t && not (adds_asset m an lbody)
        then
          let iid =
            match lbl with
            | Some a -> inn^"_"^a
            | _ -> inn in
          acc @ [{ id = with_dummy_loc iid;
                   form = mk_loop_invariant m an (map_mterm m ctx t) }]
        else acc
      ) ([] : (loc_term, loc_ident) abstract_formula list) in
  loop_invariants @ storage_loop_invariants

(* API storage templates -----------------------------------------------------*)

let mk_get_field_from_pos asset field = Dfun {
    name = "get_"^field;
    logic = Logic;
    args = ["c",Tycoll asset; "i",Tyint];
    returns = Tyint;
    raises = [];
    variants = [];
    requires = [];
    ensures = [];
    body = Tapp (Tvar field,
                 [
                   Tnth (asset,
                         Tvar "i",
                         Tvar "c")
                 ])
  }

let mk_get_asset asset key ktyp = Dfun {
    name = "get_"^asset;
    logic = NoMod;
    args = ["k",ktyp];
    returns = Tyasset asset;
    raises = [ Enotfound ];
    variants = [];
    requires = [];
    ensures = [
      { id   = "get_"^asset^"_post_1";
        form = Tmem (asset,
                     Tresult,
                     mk_ac asset);
      };
      { id   = "get_"^asset^"_post_2";
        form = Tforall ([["a"],Tyasset asset],
                        Timpl (Teq (Tyint,
                                    Tvar "k",
                                    Tdoti ("a",key)),
                               Teq (Tyasset asset,
                                    Tresult,
                                    Tvar "a")))
      }
    ];
    body = Tif (Tnot (Tcontains (asset,
                                 Tvar "k",
                                 mk_ac asset)),
                Traise Enotfound,
                Some (Tget (asset,
                            mk_ac asset,
                            Tvar "k")))
  }

let mk_set_sum_ensures m a =
  List.fold_left (fun acc f ->
      acc @ [{
          id = "set_"^a^"_sum_post";
          form = Teq (Tyint,
                      Tapp (Tvar ((mk_sum_clone_id a f)^".sum"),
                            [mk_ac_old a]),
                      Tplus (Tyint,
                             Tminus (Tyint,
                                     Tapp (Tvar ((mk_sum_clone_id a f)^".sum"),
                                           [mk_ac a]),
                                     Tdoti("new_asset",f)),
                             Tdot(
                               Tvar "old_asset",
                               Tvar f)))
        }]) [] (M.Utils.get_sum_fields m a)

let mk_set_ensures m n key fields =
  snd (List.fold_left (fun (i,acc) (f:field) ->
      if compare f.name key = 0 then
        (i,acc)
      else
        (succ i,acc@[{
             id   = "set_"^n^"_post"^(string_of_int i);
             form = Teq (Tyint,
                         Tapp (Tvar f.name,
                               [Tget (n,
                                      mk_ac n,
                                      Tdoti ("old_asset",
                                             key))]),
                         Tapp (Tvar f.name,
                               [Tvar ("new_asset")]))
           }])
    ) (1,[]) fields) @ (mk_set_sum_ensures m n)

let mk_set_asset m key = function
  | Drecord (asset, fields) ->  Dfun {
      name = "set_"^asset;
      logic = NoMod;
      args = ["old_asset", Tyasset asset; "new_asset", Tyasset asset];
      returns = Tyunit;
      raises = [ Enotfound ];
      variants = [];
      requires = [];
      ensures = mk_set_ensures m asset key fields;
      body = Tif (Tnot (Tmem (asset,
                              Tvar "old_asset",
                              mk_ac asset)),
                  Traise Enotfound,
                  Some (
                    Tassign (mk_ac asset,
                             Tset (asset,
                                   mk_ac asset,
                                   Tdoti ("old_asset",key),
                                   Tvar ("new_asset")))
                  ))
    }
  | _ -> assert false

let mk_contains asset keyt = Dfun {
    name     = "contains_"^asset;
    logic    = NoMod;
    args     = ["k",keyt];
    returns  = Tybool;
    raises   = [];
    variants = [];
    requires = [];
    ensures  = [
      { id   = asset^"_contains_1";
        form = Teq(Tyint, Tvar "result", Tcontains (asset,
                                                    Tvar "k",
                                                    mk_ac asset))
      }];
    body     = Tcontains (asset,
                          Tvar "k",
                          mk_ac asset)
  }

let mk_unshallow asset keyt = Dfun {
    name     = "unshallow_"^asset;
    logic    = Logic;
    args     = ["c",Tycoll asset;"l",Tylist keyt];
    returns  = Tycoll asset;
    raises   = [];
    variants = [];
    requires = [];
    ensures  = [
      { id   = asset^"_unshallow_post_1";
        form = Tsubset (asset,
                        Tresult,
                        Tvar "c")
      }];
    body     = Tunshallow (asset,
                           Tvar "c",
                           Tvar "l")
  }

let mk_api_precond m a src =
  M.Utils.get_storage_invariants m (Some a)
  |> List.fold_left (fun acc (_,lbl,t) ->
      if is_local_invariant m a t then
        acc @ [{
            id = lbl;
            form = unloc_term (mk_invariant m (dumloc a) src (map_mterm m init_ctx t))
          }]
      else acc
    ) []

let mk_add_asset_precond m a id = mk_api_precond m a (`Preasset id)

let mk_listtocoll_precond m a id = mk_api_precond m a (`Prelist id)

let mk_listtocoll m asset = Dfun {
    name     = "listtocoll_"^asset;
    logic    = Logic;
    args     = ["l",Tylist (Tyasset asset)];
    returns  = Tycoll asset;
    raises   = [];
    variants = [];
    requires = mk_listtocoll_precond m asset "l";
    ensures  = [
      (*      { id   = asset^"_unshallow_post_1";
              form = Tsubset (asset,
                              Tresult,
                              Tvar "c")
              }*)];
    body     = Tcoll (asset,
                      Tvar "l")
  }

(* basic getters *)

let gen_field_getter n field = Dfun {
    name     = n;
    logic    = Logic;
    args     = [];
    returns  = Tyunit;
    raises   = [];
    variants = [];
    requires = [];
    ensures  = [];
    body     = Tnone;
  }

let gen_field_getters = function
  | Drecord (n,fs) ->
    List.map (gen_field_getter n) fs
  | _ -> assert false

let mk_add_sum_ensures m a e =
  List.fold_left (fun acc f ->
      acc @ [{
          id = "add_"^a^"_sum_post";
          form = Teq (Tyint,
                      Tapp (Tvar ((mk_sum_clone_id a f)^".sum"),
                            [mk_ac a]),
                      Tplus (Tyint,
                             Tapp (Tvar ((mk_sum_clone_id a f)^".sum"),
                                   [mk_ac_old a]),
                             Tdoti(e,
                                   f)))
        }]) [] (M.Utils.get_sum_fields m a)

let mk_add_ensures m p a e =
  [
    { id   = p^"_post_1";
      form = Tmem (a,
                   Tvar e,
                   mk_ac a)
    };
    { id   = p^"_post_2";
      form = Teq (Tycoll a,
                  mk_ac a,
                  Tunion (a,
                          mk_ac_old a,
                          Tsingl (a,
                                  Tvar e)));
    };
    { id   = p^"_post_3";
      form = Teq (Tycoll a,
                  mk_ac_added a,
                  Tunion (a,
                          mk_ac_old_added a,
                          Tsingl (a,
                                  Tvar e)));
    };
    { id   = p^"_post_4";
      form = Tempty (a,
                     Tinter (a,
                             mk_ac_old_added a,
                             Tsingl (a,
                                     Tvar e)
                            ));
    };
  ] @ (mk_add_sum_ensures m a e)

let mk_add_asset m asset key : decl = Dfun {
    name     = "add_"^asset;
    logic    = NoMod;
    args     = ["new_asset",Tyasset asset];
    returns  = Tyunit;
    raises   = [Ekeyexist];
    variants = [];
    requires = mk_add_asset_precond m asset "new_asset";
    ensures  = mk_add_ensures m ("add_"^asset) asset "new_asset";
    body     = Tseq [
        Tif (Tmem (asset,
                   Tvar ("new_asset"),
                   mk_ac asset),
             Traise Ekeyexist, (* then *)
             Some (Tseq [      (* else *)
                 Tassign (mk_ac asset,
                          Tadd (asset,
                                mk_ac asset,
                                Tvar "new_asset"));
                 Tassign (mk_ac_added asset,
                          Tadd (asset,
                                mk_ac_added asset,
                                Tvar "new_asset"))
               ]
               ))
      ];
  }

let mk_rm_sum_ensures m a e =
  List.fold_left (fun acc f ->
      acc @ [{
          id = "remove_"^a^"_sum_post";
          form = Teq (Tyint,
                      Tapp (Tvar ((mk_sum_clone_id a f)^".sum"),
                            [mk_ac a]),
                      Tminus (Tyint,
                              Tapp (Tvar ((mk_sum_clone_id a f)^".sum"),
                                    [mk_ac_old a]),
                              Tdoti(e,
                                    f)))
        }]) [] (M.Utils.get_sum_fields m a)

let mk_rm_ensures m p a e =
  [
    { id   = p^"_post1";
      form = Tnot (Tmem (a,
                         Tvar (e),
                         mk_ac a))
    };
    { id   = p^"_post2";
      form = Teq (Tycoll a,
                  mk_ac a,
                  Tdiff (a,
                         mk_ac_old a,
                         Tsingl (a,
                                 Tvar e)))
    };
    { id   = p^"_post3";
      form = Teq (Tycoll a,
                  mk_ac_rmed a,
                  Tunion (a,
                          mk_ac_old_rmed a,
                          Tsingl (a,
                                  Tvar e)))
    }
  ] @ (mk_rm_sum_ensures m a e)

let mk_rm_asset m asset key : decl = Dfun {
    name     = "remove_"^asset;
    logic    = NoMod;
    args     = ["a", Tyasset asset];
    returns  = Tyunit;
    raises   = [Enotfound];
    variants = [];
    requires = [];
    ensures  = mk_rm_ensures m ("remove_"^asset) asset "a";
    body = Tif (Tnot (Tmem (asset,
                            Tvar "a",
                            mk_ac asset)),
                Traise Enotfound,
                Some (
                  Tseq [
                    Tassign (mk_ac_rmed asset,
                             Tadd (asset,
                                   mk_ac_rmed asset,
                                   Tget(asset,
                                        mk_ac asset,
                                        Tdoti ("a",
                                               key))));
                    Tassign (mk_ac asset,
                             Tremove (asset,
                                      mk_ac asset,
                                      Tdoti ("a",
                                             key)))

                  ]));
  }

(* a      : asset name
   ak     : asset key field name
   pf      : partition field name
   adda    : added asset name
   addktyp : removed asset key type
*)
let mk_add_partition_field m a ak pf adda addak : decl =
  let akey  = Tapp (Tvar ak,[Tvar "asset"]) in
  let addak = Tapp (Tvar addak,[Tvar "new_asset"]) in
  Dfun {
    name     = "add_"^a^"_"^pf;
    logic    = NoMod;
    args     = ["asset",Tyasset a; "new_asset",Tyasset adda];
    returns  = Tyunit;
    raises   = [Enotfound;Ekeyexist];
    variants = [];
    requires = mk_add_asset_precond m adda "new_asset";
    ensures  = mk_add_ensures m ("add_"^a^"_"^pf) adda "new_asset";
    body     =
      Tif (Tnot (Tmem (a,
                       Tvar "asset",
                       mk_ac a)),
           Traise Enotfound,
           Some (Tseq [
               Tapp (Tvar ("add_"^adda),
                     [Tvar "new_asset"]);
               Tletin (false, a^"_"^pf,None,
                       Tapp (Tvar pf,[Tvar "asset"]),
                       Tletin (false,"new_"^a^"_"^pf,None,
                               Tcons (addak,Tvar (a^"_"^pf)),
                               Tletin (false,"new_asset",None,
                                       Trecord (Some (Tvar "asset"),
                                                [pf,Tvar ("new_"^a^"_"^pf)]),
                                       Tassign (mk_ac a,
                                                Tset (a,
                                                      mk_ac a,
                                                      akey,
                                                      Tvar ("new_asset")))
                                      )))]));
  }

(* n      : asset name
   ktyp   : asset key type
   f      : partition field name
   rmn    : removed asset name
   rmktyp : removed asset key type
*)
let mk_rm_partition_field m asset keyf f rmed_asset rmkey : decl = Dfun {
    name     = "remove_"^asset^"_"^f;
    logic    = NoMod;
    args     = ["asset",Tyasset asset; "rm_asset",Tyasset rmed_asset];
    returns  = Tyunit;
    raises   = [Enotfound];
    variants = [];
    requires = [];
    ensures  = mk_rm_ensures m ("remove_"^asset^"_"^f) rmed_asset "rm_asset";
    body     =
      Tif (Tnot (Tmem (asset,
                       Tvar "asset",
                       mk_ac asset)),
           Traise Enotfound,
           Some (
             Tletin (false,
                     asset^"_"^f,
                     None,
                     Tapp (Tvar f,
                           [Tvar ("asset")]),
                     Tletin (false,
                             "new_"^asset^"_"^f,
                             None,
                             Tlistremove (gArchetypeList,
                                          Tvar (asset^"_"^f),
                                          Tdoti ("rm_asset",
                                                 rmkey)),
                             Tletin (false,
                                     "new_"^asset^"_asset",
                                     None,
                                     Trecord (Some (Tvar ("asset")),
                                              [f,Tvar ("new_"^asset^"_"^f)]),
                                     Tseq [
                                       Tassign (mk_ac asset,
                                                Tset (asset,
                                                      mk_ac asset,
                                                      Tdoti ("asset",
                                                             keyf),
                                                      Tvar ("new_"^asset^"_asset")));
                                       Tapp (Tvar ("remove_"^rmed_asset),
                                             [Tvar ("rm_asset")])
                                     ]
                                    )))));
  }

let mk_storage_api (m : M.model) records =
  m.api_items |> List.fold_left (fun acc (sc : M.api_item) ->
      match sc.node_item with
      | M.APIStorage (Get n) ->
        let k,kt = M.Utils.get_asset_key m (dumloc n) in
        acc @ [mk_get_asset n k (kt |> map_btype)]
      | M.APIStorage (Add n) ->
        let k = M.Utils.get_asset_key m (dumloc n) |> fst in
        acc @ [mk_add_asset m n k]
      | M.APIStorage (Remove n) ->
        let kt = M.Utils.get_asset_key m (dumloc n) |> fst in
        acc @ [mk_rm_asset m n kt]
      | M.APIStorage (Set n) ->
        let record = get_record n (records |> unloc_decl) in
        let k      = M.Utils.get_asset_key m (get_record_name record |> dumloc) |> fst in
        acc @ [mk_set_asset m k record]
      | M.APIStorage (UpdateAdd (a,pf)) ->
        let k            = M.Utils.get_asset_key m (dumloc a) |> fst in
        let (pa,addak,_) = M.Utils.get_partition_asset_key m (dumloc a) (dumloc pf) in
        acc @ [
          (*mk_add_asset           pa.pldesc addak.pldesc;*)
          mk_add_partition_field m a k pf pa addak
        ]
      | M.APIStorage (UpdateRemove (n,f)) ->
        let t         = M.Utils.get_asset_key m (dumloc n) |> fst in
        let (pa,pk,_) = M.Utils.get_partition_asset_key m (dumloc n) (dumloc f) in
        acc @ [
          (*mk_rm_asset           pa.pldesc (pt |> map_btype);*)
          mk_rm_partition_field m n t f pa pk
        ]
      | M.APIFunction (Contains n) ->
        let t         =  M.Utils.get_asset_key m (dumloc n) |> snd |> map_btype in
        acc @ [ mk_contains n t ]
      | M.APIFunction (Select (asset,test)) ->
        let mlw_test = map_mterm m init_ctx test in
        acc @ [ mk_select m asset test (mlw_test |> unloc_term) sc.only_formula ]
      | M.APIFunction (Sum (asset,field)) when compare asset "todo" <> 0 ->
        let key      = M.Utils.get_asset_key m (dumloc asset) |> fst in
        acc @ [ mk_get_field_from_pos asset field;
                mk_sum_clone m asset key field ]
      | M.APIFunction (Unshallow n) ->
        let t         =  M.Utils.get_asset_key m (dumloc n) |> snd |> map_btype in
        acc @ [ mk_unshallow n t ]
      | M.APIFunction (Listtocoll n) ->
        acc @ [ mk_listtocoll m n ]
      | _ -> acc
    ) [] |> loc_decl |> deloc

(* Entries --------------------------------------------------------------------*)

let fold_exns body : exn list =
  let rec internal_fold_exn acc (term : M.mterm) =
    match term.M.node with
    | M.Mget _ -> acc @ [Enotfound]
    | M.Maddasset _ -> acc @ [Ekeyexist]
    | M.Maddfield _ -> acc @ [Enotfound;Ekeyexist]
    | M.Mfail InvalidCaller -> acc @ [Einvalidcaller]
    | M.Mfail NoTransfer -> acc @ [Enotransfer]
    | M.Mfail (InvalidCondition _) -> acc @ [Einvalidcondition]
    | M.Mremoveasset _ -> acc @ [Enotfound]
    | _ -> M.fold_term internal_fold_exn acc term in
  Tools.List.dedup (internal_fold_exn [] body)

let is_fail (t : M.mterm) =
  match t.node with
  | M.Mfail _ -> true
  | _ -> false

let flatten_if_fail m (t : M.mterm) : loc_term =
  let rec rec_flat acc (t : M.mterm) : loc_term list =
    match t.node with
    | M.Mif (c,th, Some e) when is_fail th ->
      rec_flat (acc@[mk_loc t.loc (Tif (map_mterm m init_ctx c, map_mterm m init_ctx th,None))]) e
    | _ -> acc @ [map_mterm m init_ctx t] in
  mk_loc t.loc (Tseq (rec_flat [] t))

let mk_ensures m acc (v : M.verification) =
  acc @ (List.map (fun (spec : M.specification) -> {
        id = spec.name |> map_lident;
        form = map_mterm m init_ctx spec.formula
      }) (v.specs |> List.filter M.Utils.is_post))

let mk_require n i t = {
  id = with_dummy_loc (n^"_require_"^(string_of_int i));
  form = t
}

(* TODO : should plunge in called functions body *)
let mk_requires m n v =
  M.Utils.get_added_removed_sets m v
  |> List.map (fun t ->
      match t with
      | M.Msetadded e ->
        let a = M.Utils.get_asset_type e |> unloc in
        loc_term (Tempty (a,mk_ac_added a))
      | M.Msetremoved e ->
        let a = M.Utils.get_asset_type e |> unloc in
        loc_term (Tempty (a,mk_ac_rmed a))
      | _ -> assert false
    )
  |> Tools.List.dedup
  |> List.mapi (fun i t  -> mk_require n i t)

(* for each arg, retrieve corresponding type invariants, and convert it to precondition *)
let mk_preconds m args body : ((loc_term,loc_ident) abstract_formula) list =
  List.fold_left (fun acc (id,t,_) ->
      match t with
      | M.Tasset n ->
        let n = unloc n in
        M.Utils.get_storage_invariants m (Some n)
        |> List.fold_left (fun acc  (_,lbl,t) ->
            if is_local_invariant m n t && adds_asset m n body then
              (* TODO : should be more specific : the real question is
                 'is the element id added?' *)
              acc @ [{
                  id = with_dummy_loc lbl;
                  form = mk_pre_asset m n (unloc id) (map_mterm m init_ctx t)
                }]
            else
              acc
          ) []
      | M.Tcontainer (Tasset n, Collection)
      | M.Tcontainer (Tasset n, Partition) ->
        let n = unloc n in
        M.Utils.get_storage_invariants m (Some n)
        |> List.fold_left (fun acc  (_,lbl,t) ->
            if is_local_invariant m n t && adds_asset m n body then
              (* TODO similar to above : should be more specific : the real question is
                 'is the element of id added?' *)
              acc @ [{
                  id = with_dummy_loc lbl;
                  form = mk_pre_coll m n (unloc id) (map_mterm m init_ctx t)
                }]
            else
              acc
          ) []
      | _ -> acc
    ) [] args

let is_src src (_,f,_) = f.M.src = src

let mk_entry_require m idents =
  if M.Utils.with_trace m && List.length idents > 0 then
    let mk_entry_eq id = Teq (Tyint,
                              Tdoti (gs,mk_id "entry"),
                              Tsome (Tvar (String.capitalize_ascii id))) in
    [
      {
        id = with_dummy_loc "entry_require";
        form =
          List.fold_left (fun acc id ->
              Tor (acc,mk_entry_eq id)
            ) (mk_entry_eq (List.hd idents)) (List.tl idents)
          |> loc_term
      };
      {
        id = with_dummy_loc "empty_trace";
        form = Teq (Tyint,
                    Tdoti (gs,mk_id "tr"),
                    Tnil)
               |> loc_term
      }
    ]
  else []

let mk_functions src m =
  M.Utils.get_functions m |> List.filter (is_src src) |> List.map (
    fun ((v : M.verification option),
         (s : M.function_struct),
         (t : M.type_)) ->
      Dfun {
        name     = map_lident s.name;
        logic    = NoMod;
        args     = (List.map (fun (i,t,_) ->
            (map_lident i, map_mtype t)
          ) s.args);
        returns  = map_mtype t;
        raises   = fold_exns s.body;
        variants = [];
        requires =
          (mk_entry_require m (M.Utils.get_callers m (unloc s.name))) @
          (mk_requires m (s.name |> unloc) v) @
          (mk_preconds m s.args s.body);
        ensures  = Option.fold (mk_ensures m) [] v;
        body     = flatten_if_fail m s.body;
      }
  )

let mk_endo_functions = mk_functions M.Endo
let mk_exo_functions = mk_functions M.Exo

let mk_entries m =
  M.Utils.get_entries m |> List.map (
    fun ((v : M.verification option),
         (s : M.function_struct)) ->
      Dfun {
        name     = map_lident s.name;
        logic    = NoMod;
        args     = (List.map (fun (i,t,_) ->
            (map_lident i, map_mtype t)
          ) s.args);
        returns  = with_dummy_loc Tyunit;
        raises   = fold_exns s.body;
        variants = [];
        requires = (mk_entry_require m [unloc s.name]) @
                   (mk_requires m (unloc s.name) v);
        ensures  = Option.fold (mk_ensures m) [] v;
        body     = flatten_if_fail m s.body;
      }
  )

(* ----------------------------------------------------------------------------*)

let to_whyml (m : M.model) : mlw_tree  =
  let storage_module   = with_dummy_loc (String.capitalize_ascii (m.name.pldesc^"_storage")) in
  let uselib           = mk_use in
  let uselist          = mk_use_list in
  let traceutils       = mk_trace_utils m |> deloc in
  let records          = M.Utils.get_records m |> List.map (map_record m) |> wdl in
  let eq_assets        = M.Utils.get_records m |> List.map (mk_eq_asset m) |> wdl in
  let eq_exten         = M.Utils.get_records m |> List.map (mk_eq_extensionality m) |> deloc in
  let clones           = M.Utils.get_assets m  |> List.map (record_to_clone m) |> wdl in
  let init_records     = records |> unloc_decl |> List.map mk_default_init |> loc_decl in
  let records          = zip records eq_assets init_records clones |> deloc in
  let storage          = M.Utils.get_storage m |> map_storage m in
  let storageval       = Dval (with_dummy_loc gs, with_dummy_loc Tystorage) in
  (*let axioms           = mk_axioms m in*)
  let partition_axioms = mk_partition_axioms m in
  let storage_api      = mk_storage_api m (records |> wdl) in
  let endo             = mk_endo_functions m in
  let functions        = mk_exo_functions m in
  let entries          = mk_entries m in
  let usestorage       = mk_use_module storage_module in
  let loct : loc_mlw_tree = [{
      name  = storage_module;
      decls = [uselib]               @
              traceutils             @
              records                @
              eq_exten               @
              [storage;storageval]   @
              (*axioms                 @*)
              partition_axioms       @
              storage_api            @
              endo;
    };{
       name = cap (map_lident m.name);
       decls = [uselib;uselist;usestorage] @
               functions @
               entries;
     }] in unloc_tree loct
