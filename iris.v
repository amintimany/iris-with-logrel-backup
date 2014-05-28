Require Import world_prop core_lang lang masks.
Require Import RecDom.PCM RecDom.UPred RecDom.BI RecDom.PreoMet RecDom.Finmap.

Module Iris (RP RL : PCM_T) (C : CORE_LANG RP).

  Module Import L  := Lang RP RL C.
  Module R <: PCM_T.
    Definition res := (RP.res * RL.res)%type.
    Instance res_op   : PCM_op res := _.
    Instance res_unit : PCM_unit res := _.
    Instance res_pcm  : PCM res := _.
  End R.
  Module Import WP := WorldProp R.

  Delimit Scope iris_scope with iris.
  Local Open Scope iris_scope.

  (** The final thing we'd like to check is that the space of
      propositions does indeed form a complete BI algebra.

      The following instance declaration checks that an instance of
      the complete BI class can be found for Props (and binds it with
      a low priority to potentially speed up the proof search).
   *)

  Instance Props_BI : ComplBI Props | 0 := _.
  Instance Props_Later : Later Props | 0 := _.

  (** And now we're ready to build the IRIS-specific connectives! *)

  Section Necessitation.
    (** Note: this could be moved to BI, since it's possible to define
        for any UPred over a monoid. **)

    Local Obligation Tactic := intros; resp_set || eauto with typeclass_instances.

    Program Definition box : Props -n> Props :=
      n[(fun p => m[(fun w => mkUPred (fun n r => p w n (pcm_unit _)) _)])].
    Next Obligation.
      intros n m r s HLe _ Hp; rewrite HLe; assumption.
    Qed.
    Next Obligation.
      intros w1 w2 EQw m r HLt; simpl.
      eapply (met_morph_nonexp _ _ p); eassumption.
    Qed.
    Next Obligation.
      intros w1 w2 Subw n r; simpl.
      apply p; assumption.
    Qed.
    Next Obligation.
      intros p1 p2 EQp w m r HLt; simpl.
      apply EQp; assumption.
    Qed.

  End Necessitation.

  (** "Internal" equality **)
  Section IntEq.
    Context {T} `{mT : metric T}.

    Program Definition intEqP (t1 t2 : T) : UPred R.res :=
      mkUPred (fun n r => t1 = S n = t2) _.
    Next Obligation.
      intros n1 n2 _ _ HLe _; apply mono_dist; now auto with arith.
    Qed.

    Program Definition intEq (t1 t2 : T) : Props := pcmconst (intEqP t1 t2).

    Instance intEq_equiv : Proper (equiv ==> equiv ==> equiv) intEqP.
    Proof.
      intros l1 l2 EQl r1 r2 EQr n r.
      split; intros HEq; do 2 red.
      - rewrite <- EQl, <- EQr; assumption.
      - rewrite EQl, EQr; assumption.
    Qed.

    Instance intEq_dist n : Proper (dist n ==> dist n ==> dist n) intEqP.
    Proof.
      intros l1 l2 EQl r1 r2 EQr m r HLt.
      split; intros HEq; do 2 red.
      - etransitivity; [| etransitivity; [apply HEq |] ];
        apply mono_dist with n; eassumption || now auto with arith.
      - etransitivity; [| etransitivity; [apply HEq |] ];
        apply mono_dist with n; eassumption || now auto with arith.
    Qed.

  End IntEq.

  Notation "t1 '===' t2" := (intEq t1 t2) (at level 70) : iris_scope.

  (** Invariants **)
  Definition invP (i : nat) (p : Props) (w : Wld) : UPred R.res :=
    intEqP (w i) (Some (ı' p)).
  Program Definition inv i : Props -n> Props :=
    n[(fun p => m[(invP i p)])].
  Next Obligation.
    intros w1 w2 EQw; unfold equiv, invP in *.
    apply intEq_equiv; [apply EQw | reflexivity].
  Qed.
  Next Obligation.
    intros w1 w2 EQw; unfold invP; simpl morph.
    destruct n; [apply dist_bound |].
    apply intEq_dist; [apply EQw | reflexivity].
  Qed.
  Next Obligation.
    intros w1 w2 Sw; unfold invP; simpl morph.
    intros n r HP; do 2 red; specialize (Sw i); do 2 red in HP.
    destruct (w1 i) as [μ1 |]; [| contradiction].
    destruct (w2 i) as [μ2 |]; [| contradiction]; simpl in Sw.
    rewrite <- Sw; assumption.
  Qed.
  Next Obligation.
    intros p1 p2 EQp w; unfold equiv, invP in *; simpl morph.
    apply intEq_equiv; [reflexivity |].
    rewrite EQp; reflexivity.
  Qed.
  Next Obligation.
    intros p1 p2 EQp w; unfold invP; simpl morph.
    apply intEq_dist; [reflexivity |].
    apply dist_mono, (met_morph_nonexp _ _ ı'), EQp.
  Qed.

  (** Ownership **)
  Definition own (r : R.res) : Props :=
    pcmconst (up_cr (pord r)).

  (** Physical part **)
  Definition ownP (r : RP.res) : Props :=
    own (r, pcm_unit _).

  (** Logical part **)
  Definition ownL (r : RL.res) : Props :=
    own (pcm_unit _, r).

  Notation "□ p" := (box p) (at level 30, right associativity) : iris_scope.
  Notation "⊤" := (top : Props) : iris_scope.
  Notation "⊥" := (bot : Props) : iris_scope.
  Notation "p ∧ q" := (and p q : Props) (at level 40, left associativity) : iris_scope.
  Notation "p ∨ q" := (or p q : Props) (at level 50, left associativity) : iris_scope.
  Notation "p * q" := (sc p q : Props) (at level 40, left associativity) : iris_scope.
  Notation "p → q" := (BI.impl p q : Props) (at level 55, right associativity) : iris_scope.
  Notation "p '-*' q" := (si p q : Props) (at level 55, right associativity) : iris_scope.
  Notation "∀ x , p" := (all n[(fun x => p)] : Props) (at level 60, x ident, no associativity) : iris_scope.
  Notation "∃ x , p" := (all n[(fun x => p)] : Props) (at level 60, x ident, no associativity) : iris_scope.
  Notation "∀ x : T , p" := (all n[(fun x : T => p)] : Props) (at level 60, x ident, no associativity) : iris_scope.
  Notation "∃ x : T , p" := (all n[(fun x : T => p)] : Props) (at level 60, x ident, no associativity) : iris_scope.

  Section Erasure.
    Global Instance preo_unit : preoType () := disc_preo ().
    Local Open Scope bi_scope.
    Local Open Scope pcm_scope.

    (* XXX: logical state omitted, since it looks weird. Also, later over the whole deal. *)
    Program Definition erasure (σ : state) (m : mask) (r s : R.res) (w : Wld) : UPred () :=
      ▹ (mkUPred (fun n _ =>
                    erase_state (option_map fst (Some r · Some s)) σ
                    /\ forall i π, m i -> w i == Some π -> (ı π) w n s) _).
    Next Obligation.
      intros n1 n2 _ _ HLe _ [HES HRS]; split; [assumption | clear HES; intros].
      rewrite HLe; eauto.
    Qed.

    Global Instance erasure_equiv σ m r s : Proper (equiv ==> equiv) (erasure σ m r s).
    Proof.
      intros w1 w2 EQw [| n] []; [reflexivity |].
      split; intros [HES HRS]; (split; [tauto | clear HES; intros ? ? HM HLu]).
      - rewrite <- EQw; eapply HRS; [eassumption |].
        change (w1 i == Some π); rewrite EQw; assumption.
      - rewrite EQw; eapply HRS; [eassumption |].
        change (w2 i == Some π); rewrite <- EQw; assumption.
    Qed.

    Global Instance erasure_dist n σ m r s : Proper (dist n ==> dist n) (erasure σ m r s).
    Proof.
      intros w1 w2 EQw [| n'] [] HLt; [reflexivity |]; destruct n as [| n]; [now inversion HLt |].
      split; intros [HES HRS]; (split; [tauto | clear HES; intros ? ? HM HLu]).
      - assert (EQπ := EQw i); specialize (HRS i); rewrite HLu in EQπ; clear HLu.
        destruct (w1 i) as [π' |]; [| contradiction]; do 3 red in EQπ.
        apply ı in EQπ; apply EQπ; [now auto with arith |].
        apply (met_morph_nonexp _ _ (ı π')) in EQw; apply EQw; [now auto with arith |].
        apply HRS; [assumption | reflexivity].
      - assert (EQπ := EQw i); specialize (HRS i); rewrite HLu in EQπ; clear HLu.
        destruct (w2 i) as [π' |]; [| contradiction]; do 3 red in EQπ.
        apply ı in EQπ; apply EQπ; [now auto with arith |].
        apply (met_morph_nonexp _ _ (ı π')) in EQw; apply EQw; [now auto with arith |].
        apply HRS; [assumption | reflexivity].
    Qed.

  End Erasure.

  Notation " p @ k " := ((p : UPred ()) k tt) (at level 60, no associativity).

  Section ViewShifts.
    Local Open Scope mask_scope.
    Local Open Scope pcm_scope.
    Local Obligation Tactic := intros.

    Program Definition preVS (m1 m2 : mask) (p : Props) (w : Wld) : UPred R.res :=
      mkUPred (fun n r => forall w1 s rf rc mf σ k (HSub : w ⊑ w1) (HLe : k <= n)
                                 (HGt : k > 0) (HR : Some rc = Some r · Some rf)
                                 (HE : erasure σ (m1 ∪ mf) rc s w1 @ k) (HD : mf # m1 ∪ m2),
                            exists w2 rc' r' s', w1 ⊑ w2 /\ p w2 k r' /\
                                                 Some rc' = Some r' · Some rf /\
                                                 erasure σ (m2 ∪ mf) rc' s' w2 @ k) _.
    Next Obligation.
      intros n1 n2 r1 r2 HLe HSub HP; intros.
      destruct HSub as [ [rd |] HSub]; [| erewrite pcm_op_zero in HSub by eauto with typeclass_instances; discriminate].
      rewrite (comm (Commutative := pcm_op_comm _)) in HSub; rewrite <- HSub in HR.
      rewrite <- (assoc (Associative := pcm_op_assoc _)) in HR.
      destruct (Some rd · Some rf) as [rf' |] eqn: HR';
        [| erewrite (comm (Commutative := pcm_op_comm _)), pcm_op_zero in HR by apply _; discriminate].
      edestruct (HP w1 s rf' rc mf σ k) as [w2 [rc' [r1' [s' HH] ] ] ];
        try eassumption; [etransitivity; eassumption |]; clear - HR' HH.
      destruct HH as [HW [HP [HR HE] ] ]; rewrite <- HR' in HR.
      rewrite (assoc (Associative := pcm_op_assoc _)) in HR.
      destruct (Some r1' · Some rd) as [r2' |] eqn: HR'';
        [| erewrite pcm_op_zero in HR by apply _; discriminate].
      exists w2 rc' r2' s'; intuition; [].
      eapply uni_pred, HP; [reflexivity |].
      exists (Some rd); rewrite (comm (Commutative := pcm_op_comm _)); assumption.
    Qed.

    Program Definition pvs (m1 m2 : mask) : Props -n> Props :=
      n[(fun p => m[(preVS m1 m2 p)])].
    Next Obligation.
      intros w1 w2 EQw n r; split; intros HP w2'; intros.
      - eapply HP; try eassumption; [].
        rewrite EQw; assumption.
      - eapply HP; try eassumption; [].
        rewrite <- EQw; assumption.
    Qed.
    Next Obligation.
      intros w1 w2 EQw n' r HLt; destruct n as [| n]; [now inversion HLt |]; split; intros HP w2'; intros.
      - symmetry in EQw; assert (HDE := extend_dist _ _ _ _ EQw HSub).
        assert (HSE := extend_sub _ _ _ _ EQw HSub); specialize (HP (extend w2' w1)).
        edestruct HP as [w1'' [rc' [r' [s' [HW HH] ] ] ] ]; try eassumption; clear HP; [ | ].
        + eapply erasure_dist, HE; [symmetry; eassumption | now eauto with arith].
        + symmetry in HDE; assert (HDE' := extend_dist _ _ _ _ HDE HW).
          assert (HSE' := extend_sub _ _ _ _ HDE HW); destruct HH as [HP [HR' HE'] ];
          exists (extend w1'' w2') rc' r' s'; repeat split; [assumption | | assumption |].
          * eapply (met_morph_nonexp _ _ p), HP ; [symmetry; eassumption | now eauto with arith].
          * eapply erasure_dist, HE'; [symmetry; eassumption | now eauto with arith].
      - assert (HDE := extend_dist _ _ _ _ EQw HSub); assert (HSE := extend_sub _ _ _ _ EQw HSub); specialize (HP (extend w2' w2)).
        edestruct HP as [w1'' [rc' [r' [s' [HW HH] ] ] ] ]; try eassumption; clear HP; [ | ].
        + eapply erasure_dist, HE; [symmetry; eassumption | now eauto with arith].
        + symmetry in HDE; assert (HDE' := extend_dist _ _ _ _ HDE HW).
          assert (HSE' := extend_sub _ _ _ _ HDE HW); destruct HH as [HP [HR' HE'] ];
          exists (extend w1'' w2') rc' r' s'; repeat split; [assumption | | assumption |].
          * eapply (met_morph_nonexp _ _ p), HP ; [symmetry; eassumption | now eauto with arith].
          * eapply erasure_dist, HE'; [symmetry; eassumption | now eauto with arith].
    Qed.
    Next Obligation.
      intros w1 w2 EQw n r HP w2'; intros; eapply HP; try eassumption; [].
      etransitivity; eassumption.
    Qed.
    Next Obligation.
      intros p1 p2 EQp w n r; split; intros HP w1; intros.
      - setoid_rewrite <- EQp; eapply HP; eassumption.
      - setoid_rewrite EQp; eapply HP; eassumption.
    Qed.
    Next Obligation.
      intros p1 p2 EQp w n' r HLt; split; intros HP w1; intros.
      - edestruct HP as [w2 [rc' [r' [s' [HW [HP' [HR' HE'] ] ] ] ] ] ]; try eassumption; [].
        clear HP; repeat eexists; try eassumption; [].
        apply EQp; [now eauto with arith | assumption].
      - edestruct HP as [w2 [rc' [r' [s' [HW [HP' [HR' HE'] ] ] ] ] ] ]; try eassumption; [].
        clear HP; repeat eexists; try eassumption; [].
        apply EQp; [now eauto with arith | assumption].
    Qed.

    Definition vs (m1 m2 : mask) (p q : Props) : Props :=
      □ (p → pvs m1 m2 q).

  End ViewShifts.

End Iris.