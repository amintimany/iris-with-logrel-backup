Require Import RecDom.PCM.

Module Type CORE_LANG (Res : PCM_T).
  Import Res.

  Delimit Scope lang_scope with lang.
  Local Open Scope lang_scope.

  (******************************************************************)
  (** ** Syntax, machine state, and atomic reductions **)
  (******************************************************************)

  (** Expressions and values **)
  Parameter expr : Type.

  Parameter is_value : expr -> Prop.
  Definition value : Type := {e: expr | is_value e}.
  Parameter is_value_dec : forall e, is_value e + ~is_value e.

  (* fork and fRet *)
  Parameter fork : expr -> expr.
  Parameter fork_ret : expr.
  Axiom fork_ret_is_value : is_value fork_ret.
  Definition fork_ret_val : value := exist _ fork_ret fork_ret_is_value.
  Axiom fork_not_value : forall e,
                           ~is_value (fork e).
  Axiom fork_inj : forall e1 e2,
                     fork e1 = fork e2 -> e1 = e2.

  (** Evaluation contexts **)
  Parameter ectx : Type.
  Parameter empty_ctx : ectx.
  Parameter comp_ctx : ectx -> ectx -> ectx.
  Parameter fill : ectx -> expr -> expr.

  Notation "'ε'"    := empty_ctx : lang_scope.
  Notation "K1 ∘ K2"  := (comp_ctx K1 K2) (at level 40, left associativity) : lang_scope.
  Notation "K '[[' e ']]' " := (fill K e) (at level 40, left associativity) : lang_scope.
  Axiom fill_empty : forall e, ε [[ e ]] = e.
  Axiom fill_comp  : forall K1 K2 e, K1 [[ K2 [[ e ]] ]] = K1 ∘ K2 [[ e ]].
  Axiom fill_inj1  : forall K1 K2 e,
                       K1 [[ e ]] = K2 [[ e ]] -> K1 = K2.
  Axiom fill_inj2  : forall K e1 e2,
                       K [[ e1 ]] = K [[ e2 ]] -> e1 = e2.
  Axiom fill_value : forall K e,
                       is_value (K [[ e ]]) ->
                       K = ε.
  Axiom fill_fork  : forall K e e',
                       fork e' = K [[ e ]] ->
                       K = ε.

  (** Shared machine state (e.g., the heap) **)
  Parameter state : Type.

  (** Primitive (single thread) machine configurations **)
  Definition prim_cfg : Type := (expr * state)%type.

  (** The primitive atomic stepping relation **)
  Parameter prim_step : prim_cfg -> prim_cfg -> Prop.

  Definition stuck (e : expr) : Prop :=
    forall σ c K e',
      e = K [[ e' ]] ->
      ~prim_step (e', σ) c.

  Axiom fork_stuck :
    forall K e, stuck (K [[ fork e ]]).
  Axiom values_stuck :
    forall e, is_value e -> stuck e.

  (* When something does a step, and another decomposition of the same
     expression has a non-value e in the hole, then K is a left
     sub-context of K' - in other words, e also contains the reducible
     expression *)
  Axiom step_by_value :
    forall K K' e e' sigma cfg,
      K [[ e ]] = K' [[ e' ]] ->
      prim_step (e', sigma) cfg ->
      ~ is_value e ->
      exists K'', K' = K ∘ K''.
  (* Similar to above, buth with a fork instead of a reducible
     expression *)
  Axiom fork_by_value :
    forall K K' e e',
      K [[ e ]] = K' [[ fork e' ]] ->
      ~ is_value e ->
      exists K'', K' = K ∘ K''.

  (** Atomic expressions **)
  Parameter atomic : expr -> Prop.

  Axiom atomic_not_stuck :
    forall e, atomic e -> ~stuck e.

  Axiom atomic_step : forall eR K e e' σ σ',
                        atomic eR ->
                        eR = K [[ e ]] ->
                        prim_step (e, σ) (e', σ') ->
                        K = ε /\ is_value e'.


  (******************************************************************)
  (** ** Erasures **)
  (******************************************************************)

  (** Erasure of a resource to the set of states it describes **)
  Parameter erase_state : option res -> state -> Prop.

  Axiom erase_state_nonzero :
    forall σ, ~ erase_state 0%pcm σ.

  Axiom erase_state_emp :
    forall σ, erase_state 1%pcm σ.

  (** Erasure of a resource to the set of expressions it describes **)
  (* Not needed for now *)
  Parameter erase_exp : option res -> expr -> Prop.

  Axiom erase_exp_mono :
    forall r r' e,
      erase_exp r e ->
      erase_exp (r · r')%pcm e.

  Axiom erase_fork_ret :
    forall r, erase_exp r fork_ret.

  Axiom erase_fork :
    forall r e,
      erase_exp r (fork e) ->
      erase_exp r e.

  Axiom erase_exp_idemp :
    forall r e, erase_exp r e ->
      exists r', r = (r · r')%pcm /\ r' = (r' · r')%pcm /\ erase_exp r' e.

  Axiom erase_exp_split :
    forall r K e,
      erase_exp r (fill K e) ->
      exists r_K r_e,
        r = (r_K · r_e)%pcm /\
        erase_exp r_K (fill K fork_ret) /\
        erase_exp r_e e.

  Axiom erase_exp_combine :
    forall r_K r_e e K,
      erase_exp r_K (fill K fork_ret) ->
      erase_exp r_e e ->
      erase_exp (r_K · r_e)%pcm (fill K e).

End CORE_LANG.