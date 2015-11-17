Require Import iris.cmra.
Local Hint Extern 1 (_ ≼ _) => etransitivity; [eassumption|].
Local Hint Extern 1 (_ ≼ _) => etransitivity; [|eassumption].
Local Hint Extern 10 (_ ≤ _) => omega.

Structure uPred (M : cmraT) : Type := IProp {
  uPred_holds :> nat → M → Prop;
  uPred_ne x1 x2 n : uPred_holds n x1 → x1 ={n}= x2 → uPred_holds n x2;
  uPred_weaken x1 x2 n1 n2 :
    x1 ≼ x2 → n2 ≤ n1 → validN n2 x2 → uPred_holds n1 x1 → uPred_holds n2 x2
}.
Add Printing Constructor uPred.
Instance: Params (@uPred_holds) 3.

Instance uPred_equiv (M : cmraT) : Equiv (uPred M) := λ P Q, ∀ x n,
  validN n x → P n x ↔ Q n x.
Instance uPred_dist (M : cmraT) : Dist (uPred M) := λ n P Q, ∀ x n',
  n' < n → validN n' x → P n' x ↔ Q n' x.
Program Instance uPred_compl (M : cmraT) : Compl (uPred M) := λ c,
  {| uPred_holds n x := c (S n) n x |}.
Next Obligation. by intros M c x y n ??; simpl in *; apply uPred_ne with x. Qed.
Next Obligation.
  intros M c x1 x2 n1 n2 ????; simpl in *.
  apply (chain_cauchy c (S n2) (S n1)); eauto using uPred_weaken, cmra_valid_le.
Qed.
Instance uPred_cofe (M : cmraT) : Cofe (uPred M).
Proof.
  split.
  * intros P Q; split; [by intros HPQ n x i ??; apply HPQ|].
    intros HPQ x n ?; apply HPQ with (S n); auto.
  * intros n; split.
    + by intros P x i.
    + by intros P Q HPQ x i ??; symmetry; apply HPQ.
    + by intros P Q Q' HP HQ x i ??; transitivity (Q i x); [apply HP|apply HQ].
  * intros n P Q HPQ x i ??; apply HPQ; auto.
  * intros P Q x i ??; lia.
  * intros c n x i ??; apply (chain_cauchy c (S i) n); auto.
Qed.
Instance uPred_holds_ne {M} (P : uPred M) n : Proper (dist n ==> iff) (P n).
Proof. intros x1 x2 Hx; split; eauto using uPred_ne. Qed.
Instance uPred_holds_proper {M} (P : uPred M) n : Proper ((≡) ==> iff) (P n).
Proof. by intros x1 x2 Hx; apply uPred_holds_ne, equiv_dist. Qed.
Definition uPredC (M : cmraT) : cofeT := CofeT (uPred M).

(** functor *)
Program Definition uPred_map {M1 M2 : cmraT} (f : M2 → M1)
  `{!∀ n, Proper (dist n ==> dist n) f, !CMRAPreserving f}
  (P : uPred M1) : uPred M2 := {| uPred_holds n x := P n (f x) |}.
Next Obligation. by intros M1 M2 f ?? P y1 y2 n ? Hy; simpl; rewrite <-Hy. Qed.
Next Obligation.
  by intros M1 M2 f ?? P y1 y2 n i ???; simpl; apply uPred_weaken; auto;
    apply validN_preserving || apply included_preserving.
Qed.
Instance uPred_map_ne {M1 M2 : cmraT} (f : M2 → M1)
  `{!∀ n, Proper (dist n ==> dist n) f, !CMRAPreserving f} :
  Proper (dist n ==> dist n) (uPred_map f).
Proof.
  by intros n x1 x2 Hx y n'; split; apply Hx; try apply validN_preserving.
Qed.
Definition uPredC_map {M1 M2 : cmraT} (f : M2 -n> M1) `{!CMRAPreserving f} :
  uPredC M1 -n> uPredC M2 := CofeMor (uPred_map f : uPredC M1 → uPredC M2).
Lemma upredC_map_ne {M1 M2 : cmraT} (f g : M2 -n> M1)
    `{!CMRAPreserving f, !CMRAPreserving g} n :
  f ={n}= g → uPredC_map f ={n}= uPredC_map g.
Proof.
  by intros Hfg P y n' ??; simpl; rewrite (dist_le _ _ _ _(Hfg y)) by lia.
Qed.

(** logical entailement *)
Instance uPred_entails {M} : SubsetEq (uPred M) := λ P Q, ∀ x n,
  validN n x → P n x → Q n x.

(** logical connectives *)
Program Definition uPred_const {M} (P : Prop) : uPred M :=
  {| uPred_holds n x := P |}.
Solve Obligations with done.
Instance uPred_inhabited M : Inhabited (uPred M) := populate (uPred_const True).

Program Definition uPred_and {M} (P Q : uPred M) : uPred M :=
  {| uPred_holds n x := P n x ∧ Q n x |}.
Solve Obligations with naive_solver eauto 2 using uPred_ne, uPred_weaken.
Program Definition uPred_or {M} (P Q : uPred M) : uPred M :=
  {| uPred_holds n x := P n x ∨ Q n x |}.
Solve Obligations with naive_solver eauto 2 using uPred_ne, uPred_weaken.
Program Definition uPred_impl {M} (P Q : uPred M) : uPred M :=
  {| uPred_holds n x := ∀ x' n',
       x ≼ x' → n' ≤ n → validN n' x' → P n' x' → Q n' x' |}.
Next Obligation.
  intros M P Q x1' x1 n1 HPQ Hx1 x2 n2 ????.
  destruct (cmra_included_dist_l x1 x2 x1' n1) as (x2'&?&Hx2); auto.
  assert (x2' ={n2}= x2) as Hx2' by (by apply dist_le with n1).
  assert (validN n2 x2') by (by rewrite Hx2'); rewrite <-Hx2'.
  by apply HPQ, uPred_weaken with x2' n2, uPred_ne with x2.
Qed.
Next Obligation. naive_solver eauto 2 with lia. Qed.

Program Definition uPred_forall {M A} (P : A → uPred M) : uPred M :=
  {| uPred_holds n x := ∀ a, P a n x |}.
Solve Obligations with naive_solver eauto 2 using uPred_ne, uPred_weaken.
Program Definition uPred_exist {M A} (P : A → uPred M) : uPred M :=
  {| uPred_holds n x := ∃ a, P a n x |}.
Solve Obligations with naive_solver eauto 2 using uPred_ne, uPred_weaken.

Program Definition uPred_eq {M} {A : cofeT} (a1 a2 : A) : uPred M :=
  {| uPred_holds n x := a1 ={n}= a2 |}.
Solve Obligations with naive_solver eauto 2 using (dist_le (A:=A)).

Program Definition uPred_sep {M} (P Q : uPred M) : uPred M :=
  {| uPred_holds n x := ∃ x1 x2, x ={n}= x1 ⋅ x2 ∧ P n x1 ∧ Q n x2 |}.
Next Obligation.
  by intros M P Q x y n (x1&x2&?&?&?) Hxy; exists x1, x2; rewrite <-Hxy.
Qed.
Next Obligation.
  intros M P Q x y n1 n2 Hxy ?? (x1&x2&Hx&?&?).
  assert (∃ x2', y ={n2}= x1 ⋅ x2' ∧ x2 ≼ x2') as (x2'&Hy&?).
  { rewrite ra_included_spec in Hxy; destruct Hxy as [z Hy].
    exists (x2 ⋅ z); split; eauto using ra_included_l.
    apply dist_le with n1; auto. by rewrite (associative op), <-Hx, Hy. }
  exists x1, x2'; split_ands; auto.
  * apply uPred_weaken with x1 n1; auto.
    by apply cmra_valid_op_l with x2'; rewrite <-Hy.
  * apply uPred_weaken with x2 n1; auto.
    by apply cmra_valid_op_r with x1; rewrite <-Hy.
Qed.

Program Definition uPred_wand {M} (P Q : uPred M) : uPred M :=
  {| uPred_holds n x := ∀ x' n',
       n' ≤ n → validN n' (x ⋅ x') → P n' x' → Q n' (x ⋅ x') |}.
Next Obligation.
  intros M P Q x1 x2 n1 HPQ Hx x3 n2 ???; simpl in *.
  rewrite <-(dist_le _ _ _ _ Hx) by done; apply HPQ; auto.
  by rewrite (dist_le _ _ _ n2 Hx).
Qed.
Next Obligation.
  intros M P Q x1 x2 n1 n2 ??? HPQ x3 n3 ???; simpl in *.
  apply uPred_weaken with (x1 ⋅ x3) n3; auto using ra_preserving_r.
  apply HPQ; auto.
  apply cmra_valid_included with (x2 ⋅ x3); auto using ra_preserving_r.
Qed.

Program Definition uPred_later {M} (P : uPred M) : uPred M :=
  {| uPred_holds n x := match n return _ with 0 => True | S n' => P n' x end |}.
Next Obligation. intros M P ?? [|n]; eauto using uPred_ne,(dist_le (A:=M)). Qed.
Next Obligation.
  intros M P x1 x2 [|n1] [|n2] ????; auto with lia.
  apply uPred_weaken with x1 n1; eauto using cmra_valid_S.
Qed.
Program Definition uPred_always {M} (P : uPred M) : uPred M :=
  {| uPred_holds n x := P n (unit x) |}.
Next Obligation. by intros M P x1 x2 n ? Hx; simpl in *; rewrite <-Hx. Qed.
Next Obligation.
  intros M P x1 x2 n1 n2 ????; eapply uPred_weaken with (unit x1) n1;
    auto using ra_unit_preserving, cmra_unit_valid.
Qed.

Program Definition uPred_own {M : cmraT} (a : M) : uPred M :=
  {| uPred_holds n x := ∃ a', x ={n}= a ⋅ a' |}.
Next Obligation. by intros M a x1 x2 n [a' Hx] ?; exists a'; rewrite <-Hx. Qed.
Next Obligation.
  intros M a x1 x n1 n2; rewrite ra_included_spec; intros [x2 Hx] ?? [a' Hx1].
  exists (a' ⋅ x2). by rewrite (associative op), <-(dist_le _ _ _ _ Hx1), Hx.
Qed.
Program Definition uPred_valid {M : cmraT} (a : M) : uPred M :=
  {| uPred_holds n x := validN n a |}.
Solve Obligations with naive_solver eauto 2 using cmra_valid_le.

Delimit Scope uPred_scope with I.
Bind Scope uPred_scope with uPred.
Arguments uPred_holds {_} _%I _ _.

Notation "'False'" := (uPred_const False) : uPred_scope.
Notation "'True'" := (uPred_const True) : uPred_scope.
Infix "∧" := uPred_and : uPred_scope.
Infix "∨" := uPred_or : uPred_scope.
Infix "→" := uPred_impl : uPred_scope.
Infix "★" := uPred_sep (at level 80, right associativity) : uPred_scope.
Infix "-★" := uPred_wand (at level 90) : uPred_scope.
Notation "∀ x .. y , P" :=
  (uPred_forall (λ x, .. (uPred_forall (λ y, P)) ..)) : uPred_scope.
Notation "∃ x .. y , P" :=
  (uPred_exist (λ x, .. (uPred_exist (λ y, P)) ..)) : uPred_scope.
Notation "▷ P" := (uPred_later P) (at level 20) : uPred_scope.
Notation "□ P" := (uPred_always P) (at level 20) : uPred_scope.
Infix "≡" := uPred_eq : uPred_scope.

Section logic.
Context {M : cmraT}.
Implicit Types P Q : uPred M.

Global Instance uPred_preorder : PreOrder ((⊆) : relation (uPred M)).
Proof. split. by intros P x i. by intros P Q Q' HP HQ x i ??; apply HQ, HP. Qed.
Lemma uPred_equiv_spec P Q : P ≡ Q ↔ P ⊆ Q ∧ Q ⊆ P.
Proof.
  split.
  * intros HPQ; split; intros x i; apply HPQ.
  * by intros [HPQ HQP]; intros x i ?; split; [apply HPQ|apply HQP].
Qed.
Global Instance uPred_entails_proper :
  Proper ((≡) ==> (≡) ==> iff) ((⊆) : relation (uPred M)).
Proof.
  intros P1 P2 HP Q1 Q2 HQ; rewrite uPred_equiv_spec in HP, HQ; split; intros.
  * by rewrite (proj2 HP), <-(proj1 HQ).
  * by rewrite (proj1 HP), <-(proj2 HQ).
Qed.

(** Non-expansiveness *)
Global Instance uPred_const_proper : Proper (iff ==> (≡)) (@uPred_const M).
Proof. intros P Q HPQ ???; apply HPQ. Qed.
Global Instance uPred_and_ne n :
  Proper (dist n ==> dist n ==> dist n) (@uPred_and M).
Proof.
  intros P P' HP Q Q' HQ; split; intros [??]; split; by apply HP || by apply HQ.
Qed.
Global Instance uPred_and_proper :
  Proper ((≡) ==> (≡) ==> (≡)) (@uPred_and M) := ne_proper_2 _.
Global Instance uPred_or_ne n :
  Proper (dist n ==> dist n ==> dist n) (@uPred_or M).
Proof.
  intros P P' HP Q Q' HQ; split; intros [?|?];
    first [by left; apply HP | by right; apply HQ].
Qed.
Global Instance uPred_or_proper :
  Proper ((≡) ==> (≡) ==> (≡)) (@uPred_or M) := ne_proper_2 _.
Global Instance uPred_impl_ne n :
  Proper (dist n ==> dist n ==> dist n) (@uPred_impl M).
Proof.
  intros P P' HP Q Q' HQ; split; intros HPQ x' n'' ????; apply HQ,HPQ,HP; auto.
Qed.
Global Instance uPred_impl_proper :
  Proper ((≡) ==> (≡) ==> (≡)) (@uPred_impl M) := ne_proper_2 _.
Global Instance uPred_sep_ne n :
  Proper (dist n ==> dist n ==> dist n) (@uPred_sep M).
Proof.
  intros P P' HP Q Q' HQ x n' ? Hx'; split; intros (x1&x2&Hx&?&?);
    exists x1, x2; rewrite  Hx in Hx'; split_ands; try apply HP; try apply HQ;
    eauto using cmra_valid_op_l, cmra_valid_op_r.
Qed.
Global Instance uPred_sep_proper :
  Proper ((≡) ==> (≡) ==> (≡)) (@uPred_sep M) := ne_proper_2 _.
Global Instance uPred_wand_ne n :
  Proper (dist n ==> dist n ==> dist n) (@uPred_wand M).
Proof.
  intros P P' HP Q Q' HQ x n' ??; split; intros HPQ x' n'' ???;
    apply HQ, HPQ, HP; eauto using cmra_valid_op_r.
Qed.
Global Instance uPred_wand_proper :
  Proper ((≡) ==> (≡) ==> (≡)) (@uPred_wand M) := ne_proper_2 _.
Global Instance uPred_eq_ne {A : cofeT} n :
  Proper (dist n ==> dist n ==> dist n) (@uPred_eq M A).
Proof.
  intros x x' Hx y y' Hy z n'; split; intros; simpl in *.
  * by rewrite <-(dist_le _ _ _ _ Hx), <-(dist_le _ _ _ _ Hy) by auto.
  * by rewrite (dist_le _ _ _ _ Hx), (dist_le _ _ _ _ Hy) by auto.
Qed.
Global Instance uPred_eq_proper {A : cofeT} :
  Proper ((≡) ==> (≡) ==> (≡)) (@uPred_eq M A) := ne_proper_2 _.
Global Instance uPred_forall_ne {A : cofeT} :
  Proper (pointwise_relation _ (dist n) ==> dist n) (@uPred_forall M A).
Proof. by intros n P1 P2 HP12 x n'; split; intros HP a; apply HP12. Qed.
Global Instance uPred_forall_proper {A : cofeT} :
  Proper (pointwise_relation _ (≡) ==> (≡)) (@uPred_forall M A).
Proof. by intros P1 P2 HP12 x n'; split; intros HP a; apply HP12. Qed.
Global Instance uPred_exists_ne {A : cofeT} :
  Proper (pointwise_relation _ (dist n) ==> dist n) (@uPred_exist M A).
Proof.
  by intros n P1 P2 HP12 x n'; split; intros [a HP]; exists a; apply HP12.
Qed.
Global Instance uPred_exist_proper {A : cofeT} :
  Proper (pointwise_relation _ (≡) ==> (≡)) (@uPred_exist M A).
Proof.
  by intros P1 P2 HP12 x n'; split; intros [a HP]; exists a; apply HP12.
Qed.
Global Instance uPred_later_contractive : Contractive (@uPred_later M).
Proof.
  intros n P Q HPQ x [|n'] ??; simpl; [done|].
  apply HPQ; eauto using cmra_valid_S.
Qed.
Global Instance uPred_later_proper :
  Proper ((≡) ==> (≡)) (@uPred_later M) := ne_proper _.
Global Instance uPred_always_ne n: Proper (dist n ==> dist n) (@uPred_always M).
Proof. intros P1 P2 HP x n'; split; apply HP; eauto using cmra_unit_valid. Qed.
Global Instance uPred_always_proper :
  Proper ((≡) ==> (≡)) (@uPred_always M) := ne_proper _.
Global Instance uPred_own_ne n : Proper (dist n ==> dist n) (@uPred_own M).
Proof.
  by intros a1 a2 Ha x n'; split; intros [a' ?]; exists a'; simpl; first
    [rewrite <-(dist_le _ _ _ _ Ha) by lia|rewrite (dist_le _ _ _ _ Ha) by lia].
Qed.
Global Instance uPred_own_proper :
  Proper ((≡) ==> (≡)) (@uPred_own M) := ne_proper _.

(** Introduction and elimination rules *)
Lemma uPred_const_intro P (Q : Prop) : Q → P ⊆ uPred_const Q.
Proof. by intros ???. Qed.
Lemma uPred_True_intro P : P ⊆ True%I.
Proof. done. Qed.
Lemma uPred_False_elim P : False%I ⊆ P.
Proof. by intros x n ?. Qed.
Lemma uPred_and_elim_l P Q : (P ∧ Q)%I ⊆ P.
Proof. by intros x n ? [??]. Qed.
Lemma uPred_and_elim_r P Q : (P ∧ Q)%I ⊆ Q.
Proof. by intros x n ? [??]. Qed.
Lemma uPred_and_intro R P Q : R ⊆ P → R ⊆ Q → R ⊆ (P ∧ Q)%I.
Proof. intros HP HQ x n ??; split. by apply HP. by apply HQ. Qed.
Lemma uPred_or_intro_l P Q : P ⊆ (P ∨ Q)%I.
Proof. by left. Qed.
Lemma uPred_or_intro_r P Q : Q ⊆ (P ∨ Q)%I.
Proof. by right. Qed.
Lemma uPred_or_elim R P Q : P ⊆ R → Q ⊆ R → (P ∨ Q)%I ⊆ R.
Proof. intros HP HQ x n ? [?|?]. by apply HP. by apply HQ. Qed.
Lemma uPred_impl_intro P Q R : (R ∧ P)%I ⊆ Q → R ⊆ (P → Q)%I.
Proof.
  intros HQ x n ?? x' n' ????; apply HQ; naive_solver eauto using uPred_weaken.
Qed.
Lemma uPred_impl_elim P Q : ((P → Q) ∧ P)%I ⊆ Q.
Proof. by intros x n ? [HQ HP]; apply HQ. Qed.
Lemma uPred_forall_intro P `(Q: A → uPred M): (∀ a, P ⊆ Q a) → P ⊆ (∀ a, Q a)%I.
Proof. by intros HPQ x n ?? a; apply HPQ. Qed.
Lemma uPred_forall_elim `(P : A → uPred M) a : (∀ a, P a)%I ⊆ P a.
Proof. intros x n ? HP; apply HP. Qed.
Lemma uPred_exist_intro `(P : A → uPred M) a : P a ⊆ (∃ a, P a)%I.
Proof. by intros x n ??; exists a. Qed.
Lemma uPred_exist_elim `(P : A → uPred M) Q : (∀ a, P a ⊆ Q) → (∃ a, P a)%I ⊆ Q.
Proof. by intros HPQ x n ? [a ?]; apply HPQ with a. Qed.

(* BI connectives *)
Lemma uPred_sep_elim_l P Q : (P ★ Q)%I ⊆ P.
Proof.
  intros x n Hvalid (x1&x2&Hx&?&?); rewrite Hx in Hvalid |- *.
  by apply uPred_weaken with x1 n; auto using ra_included_l.
Qed.
Global Instance uPred_sep_left_id : LeftId (≡) True%I (@uPred_sep M).
Proof.
  intros P x n Hvalid; split.
  * intros (x1&x2&Hx&_&?); rewrite Hx in Hvalid |- *.
    apply uPred_weaken with x2 n; auto using ra_included_r.
  * by intros ?; exists (unit x), x; rewrite ra_unit_l.
Qed. 
Global Instance uPred_sep_commutative : Commutative (≡) (@uPred_sep M).
Proof.
  by intros P Q x n ?; split;
    intros (x1&x2&?&?&?); exists x2, x1; rewrite (commutative op).
Qed.
Global Instance uPred_sep_associative : Associative (≡) (@uPred_sep M).
Proof.
  intros P Q R x n ?; split.
  * intros (x1&x2&Hx&?&y1&y2&Hy&?&?); exists (x1 ⋅ y1), y2; split_ands; auto.
    + by rewrite <-(associative op), <-Hy, <-Hx.
    + by exists x1, y1.
  * intros (x1&x2&Hx&(y1&y2&Hy&?&?)&?); exists y1, (y2 ⋅ x2); split_ands; auto.
    + by rewrite (associative op), <-Hy, <-Hx.
    + by exists y2, x2.
Qed.
Lemma uPred_wand_intro P Q R : (R ★ P)%I ⊆ Q → R ⊆ (P -★ Q)%I.
Proof.
  intros HPQ x n ?? x' n' ???; apply HPQ; auto.
  exists x, x'; split_ands; auto.
  eapply uPred_weaken with x n; eauto using cmra_valid_op_l.
Qed.
Lemma uPred_wand_elim P Q : ((P -★ Q) ★ P)%I ⊆ Q.
Proof.
  by intros x n Hvalid (x1&x2&Hx&HPQ&?); rewrite Hx in Hvalid |- *; apply HPQ.
Qed.
Lemma uPred_sep_or P Q R : ((P ∨ Q) ★ R)%I ≡ ((P ★ R) ∨ (Q ★ R))%I.
Proof.
  split; [by intros (x1&x2&Hx&[?|?]&?); [left|right]; exists x1, x2|].
  intros [(x1&x2&Hx&?&?)|(x1&x2&Hx&?&?)]; exists x1, x2; split_ands;
    first [by left | by right | done].
Qed.
Lemma uPred_sep_and P Q R : ((P ∧ Q) ★ R)%I ⊆ ((P ★ R) ∧ (Q ★ R))%I.
Proof. by intros x n ? (x1&x2&Hx&[??]&?); split; exists x1, x2. Qed.
Lemma uPred_sep_exist `(P : A → uPred M) Q :
  ((∃ b, P b) ★ Q)%I ≡ (∃ b, P b ★ Q)%I.
Proof.
  split; [by intros (x1&x2&Hx&[a ?]&?); exists a, x1, x2|].
  intros [a (x1&x2&Hx&?&?)]; exists x1, x2; split_ands; by try exists a.
Qed.
Lemma uPred_sep_forall `(P : A → uPred M) Q :
  ((∀ a, P a) ★ Q)%I ⊆ (∀ a, P a ★ Q)%I.
Proof. by intros x n ? (x1&x2&Hx&?&?); intros a; exists x1, x2. Qed.

(* Later *)
Lemma uPred_later_weaken P : P ⊆ (▷ P)%I.
Proof.
  intros x [|n] ??; simpl in *; [done|].
  apply uPred_weaken with x (S n); auto using cmra_valid_S.
Qed.
Lemma uPred_lub P : (▷ P → P)%I ⊆ P.
Proof.
  intros x n ? HP; induction n as [|n IH]; [by apply HP|].
  apply HP, IH, uPred_weaken with x (S n); eauto using cmra_valid_S.
Qed.
Lemma uPred_later_impl P Q : (▷ (P → Q))%I ⊆ (▷ P → ▷ Q)%I.
Proof.
  intros x [|n] ? HPQ x' [|n'] ???; auto with lia.
  apply HPQ; auto using cmra_valid_S.
Qed.
Lemma uPred_later_and P Q : (▷ (P ∧ Q))%I ≡ (▷ P ∧ ▷ Q)%I.
Proof. by intros x [|n]; split. Qed.
Lemma uPred_later_or P Q : (▷ (P ∨ Q))%I ≡ (▷ P ∨ ▷ Q)%I.
Proof. intros x [|n]; simpl; tauto. Qed.
Lemma uPred_later_forall `(P : A → uPred M) : (▷ ∀ a, P a)%I ≡ (∀ a, ▷ P a)%I.
Proof. by intros x [|n]. Qed.
Lemma uPred_later_exist `(P : A → uPred M) : (∃ a, ▷ P a)%I ⊆ (▷ ∃ a, P a)%I.
Proof. by intros x [|n]. Qed.
Lemma uPred_later_exist' `{Inhabited A} (P : A → uPred M) :
  (▷ ∃ a, P a)%I ≡ (∃ a, ▷ P a)%I.
Proof.
  intros x [|n]; split; try done.
  by destruct (_ : Inhabited A) as [a]; exists a.
Qed.
Lemma uPred_later_sep P Q : (▷ (P ★ Q))%I ≡ (▷ P ★ ▷ Q)%I.
Proof.
  intros x n ?; split.
  * destruct n as [|n]; simpl; [by exists x, x|intros (x1&x2&Hx&?&?)].
    destruct (cmra_extend_op x x1 x2 n)
      as ([y1 y2]&Hx'&Hy1&Hy2); auto using cmra_valid_S; simpl in *.
    exists y1, y2; split; [by rewrite Hx'|by rewrite Hy1, Hy2].
  * destruct n as [|n]; simpl; [done|intros (x1&x2&Hx&?&?)].
    exists x1, x2; eauto using (dist_S (A:=M)).
Qed.

(* Always *)
Lemma uPred_always_necessity P : (□ P)%I ⊆ P.
Proof.
  intros x n ??; apply uPred_weaken with (unit x) n;auto using ra_included_unit.
Qed.
Lemma uPred_always_intro P Q : (□ P)%I ⊆ Q → (□ P)%I ⊆ (□ Q)%I.
Proof.
  intros HPQ x n ??; apply HPQ; simpl in *; auto using cmra_unit_valid.
  by rewrite ra_unit_idempotent.
Qed.
Lemma uPred_always_impl P Q : (□ (P → Q))%I ⊆ (□P → □Q)%I.
Proof.
  intros x n ? HPQ x' n' ???.
  apply HPQ; auto using ra_unit_preserving, cmra_unit_valid.
Qed.
Lemma uPred_always_and P Q : (□ (P ∧ Q))%I ≡ (□ P ∧ □ Q)%I.
Proof. done. Qed.
Lemma uPred_always_or P Q : (□ (P ∨ Q))%I ≡ (□ P ∨ □ Q)%I.
Proof. done. Qed.
Lemma uPred_always_forall `(P : A → uPred M) : (□ ∀ a, P a)%I ≡ (∀ a, □ P a)%I.
Proof. done. Qed.
Lemma uPred_always_exist `(P : A → uPred M) : (□ ∃ a, P a)%I ≡ (∃ a, □ P a)%I.
Proof. done. Qed.
Lemma uPred_always_and_always_box P Q : (□ P ∧ Q)%I ⊆ (□ P ★ Q)%I.
Proof.
  intros x n ? [??]; exists (unit x), x; simpl in *.
  by rewrite ra_unit_l, ra_unit_idempotent.
Qed.

(* Own *)
Lemma uPred_own_op (a1 a2 : M) :
  uPred_own (a1 ⋅ a2) ≡ (uPred_own a1 ★ uPred_own a2)%I.
Proof.
  intros x n ?; split.
  * intros [z ?]; exists a1, (a2 ⋅ z); split; [by rewrite (associative op)|].
    split. by exists (unit a1); rewrite ra_unit_r. by exists z.
  * intros (y1&y2&Hx&[z1 Hy1]&[z2 Hy2]); exists (z1 ⋅ z2).
    rewrite (associative op), <-(commutative op z1), <-!(associative op), <-Hy2.
    by rewrite (associative op), (commutative op z1), <-Hy1.
Qed.
Lemma uPred_own_valid (a : M) : uPred_own a ⊆ uPred_valid a.
Proof.
  intros x n Hv [a' Hx]; simpl; rewrite Hx in Hv; eauto using cmra_valid_op_l.
Qed.
End logic.
