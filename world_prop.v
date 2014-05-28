(** In this file, we show how we can use the solution of the recursive
    domain equations to build a higher-order separation logic *)
Require Import RecDom.PreoMet RecDom.MetricRec RecDom.CBUltInst.
Require Import RecDom.Finmap RecDom.Constr.
Require Import RecDom.PCM RecDom.UPred RecDom.BI.

Module WorldProp (Res : PCM_T).

  (** The construction is parametric in the monoid we choose *)
  Import Res.

  (** We need to build a functor that would describe the following
      recursive domain equation:
        Prop ≃ (Loc -f> Prop) -m> UPred (Res)
      As usual, we split the negative and (not actually occurring)
      positive occurrences of Prop. *)

  Section Definitions.
    (** We'll be working with complete metric spaces, so whenever
        something needs an additional preorder, we'll just take a
        discrete one. *)
    Local Instance pt_disc P `{cmetric P} : preoType P | 2000 := disc_preo P.
    Local Instance pcm_disc P `{cmetric P} : pcmType P | 2000 := disc_pcm P.

    Definition FProp P `{cmP : cmetric P} :=
      (nat -f> P) -m> UPred res.

    Context {U V} `{cmU : cmetric U} `{cmV : cmetric V}.

    Definition PropMorph (m : V -n> U) : FProp U -n> FProp V :=
      fdMap (disc_m m) ▹.

  End Definitions.

  Module F <: SimplInput (CBUlt).
    Import CBUlt.
    Open Scope cat_scope.

    Definition F (T1 T2 : cmtyp) := cmfromType (FProp T1).
    Program Instance FArr : BiFMap F :=
      fun P1 P2 P3 P4 => n[(PropMorph)] <M< Mfst.
    Next Obligation.
      intros m1 m2 Eqm; unfold PropMorph, equiv in *.
      rewrite Eqm; reflexivity.
    Qed.
    Next Obligation.
      intros m1 m2 Eqm; unfold PropMorph.
      rewrite Eqm; reflexivity.
    Qed.

    Instance FFun : BiFunctor F.
    Proof.
      split; intros; unfold fmorph; simpl morph; unfold PropMorph.
      - rewrite disc_m_comp, <- fdMap_comp, <- ucomp_precomp.
        intros x; simpl morph; reflexivity.
      - rewrite disc_m_id, fdMap_id, pid_precomp.
        intros x; simpl morph; reflexivity.
    Qed.

    Definition F_ne : 1 -t> F 1 1 :=
      umconst (pcmconst (up_cr (const True))).
  End F.

  Module F_In := InputHalve(F).
  Module Import Fix := Solution(CBUlt)(F_In).

  (** Now we can name the two isomorphic spaces of propositions, and
      the space of worlds. We'll store the actual solutions in the
      worlds, and use the action of the FPropO on them as the space we
      normally work with. *)
  Definition PreProp := DInfO.
  Definition Props   := FProp PreProp.
  Definition Wld     := (nat -f> PreProp).

  Definition ı  : PreProp -t> halve (cmfromType Props) := Unfold.
  Definition ı' : halve (cmfromType Props) -t> PreProp := Fold.

  Lemma iso P : ı' (ı P) == P.
  Proof. apply (FU_id P). Qed.
  Lemma isoR T : ı (ı' T) == T.
  Proof. apply (UF_id T). Qed.

  Instance PProp_preo : preoType PreProp   := disc_preo PreProp.
  Instance PProp_pcm  : pcmType PreProp    := disc_pcm PreProp.
  Instance PProp_ext  : extensible PreProp := disc_ext PreProp.

End WorldProp.