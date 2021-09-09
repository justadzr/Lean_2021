import analysis.calculus.conformal
import analysis.normed_space.banach
import analysis.normed_space.dual
import similarity
import bilin_form_lemmas
import analysis.calculus.times_cont_diff
import analysis.calculus.fderiv_symmetric

noncomputable theory

open conformal_at set
open_locale classical real_inner_product_space filter topological_space

section quick

lemma quick1 {F : Type*} [add_comm_group F] {a b c d e e' f : F} 
  (h : a + b + (c + d) + (e + f) = d + b + (c + a) + (e' + f)) : e = e' :=
begin
  simp_rw [← add_assoc] at h,
  rw [add_right_cancel_iff] at h,
  nth_rewrite 1 add_comm at h,
  simp_rw [← add_assoc] at h,
  nth_rewrite 2 add_comm at h,
  simp_rw [← add_assoc] at h,
  nth_rewrite 3 add_comm at h,
  nth_rewrite 4 add_assoc at h,
  nth_rewrite 7 add_comm at h,
  simpa [← add_assoc, add_left_cancel_iff] using h
end

end quick

section linear_conformal_prep
open submodule

variables {E F : Type*} [inner_product_space ℝ E] [inner_product_space ℝ F] {x : E}

lemma eventually_is_conformal_map_of_eventually_conformal {f : E → F} 
  (hf : ∀ᶠ x' in 𝓝 x, conformal_at f x') : ∀ᶠ x' in 𝓝 x, is_conformal_map (fderiv ℝ f x') :=
hf.mono (λ y hy, conformal_at_iff_is_conformal_map_fderiv.mp hy)

lemma A {f' : E →L[ℝ] F} (h : is_conformal_map f') {u v : E} :
  ⟪u, v⟫ = 0 ↔ ⟪f' u, f' v⟫ = 0 :=
begin
  rcases (is_conformal_map_iff _).mp h with ⟨c, p, q⟩,
  split,
  { intros huv,
    convert q u v,
    rw [huv, mul_zero] },
  { intros huv,
    rw q u v at huv,
    exact eq_zero_of_ne_zero_of_mul_left_eq_zero (ne_of_gt p) huv } 
end

lemma A' {f' : E → (E →L[ℝ] F)} {u v : E} (huv : ⟪u, v⟫ = 0) 
  (h : ∀ᶠ x' in 𝓝 x, is_conformal_map $ f' x') :
  (λ x, ⟪f' x u, f' x v⟫) =ᶠ[𝓝 x] λ x, (0 : ℝ) :=
begin
  apply (filter.eventually_of_forall $ λ x, huv).mp,
  simp only [congr_arg],
  rcases filter.eventually_iff_exists_mem.mp h with ⟨s, hs, hys⟩,
  exact filter.eventually_iff_exists_mem.mpr ⟨s, hs, λ y hy p, (A $ hys y hy).mp p⟩
end

lemma B {f' : E →L[ℝ] F} {K : submodule ℝ E} 
  (hf : function.surjective f') (h : is_conformal_map f') :
  (Kᗮ).map (f' : E →ₗ[ℝ] F) = (K.map f')ᗮ :=
begin
  ext1 y'',
  simp only [mem_map, mem_orthogonal],
  split,
  { rintros ⟨u, hu, huy⟩,
    intros v hv,
    rcases hv with ⟨z, hz, hzv⟩,
    rw [← huy, ← hzv, continuous_linear_map.coe_coe, ← A h],
    exact hu z hz },
  { intros H,
    rcases hf y'' with ⟨y', hy'⟩,
    refine ⟨y', λ u hu, _, hy'⟩,
    rw [A h, hy'],
    exact H (f' u) ⟨u, hu, rfl⟩ }
end

lemma C {f' : E →L[ℝ] F} (hf : function.surjective f') (h : is_conformal_map f') {u v : E} {w : F}
  (H : ∀ (t : E), t ∈ (span ℝ ({u} ∪ {v} : set E))ᗮ → ⟪w, f' t⟫ = 0) :
  w ∈ (span ℝ ({f' u} ∪ {f' v} : set F)) :=
begin
  have triv₁ : {f' u} ∪ {f' v} = f' '' ({u} ∪ {v}) :=
    by simp only [image_union, image_singleton],
  rw [triv₁, ← continuous_linear_map.coe_coe, ← map_span],
  have triv₂ : is_complete (span ℝ ({u} ∪ {v} : set E) : set E),
  { haveI : finite_dimensional ℝ (span ℝ ({u} ∪ {v} : set E)) :=
      finite_dimensional.span_of_finite ℝ ((finite_singleton _).union $ finite_singleton _),
    exact complete_of_finite_dimensional _ },
  haveI : complete_space (span ℝ ({u} ∪ {v} : set E)) := triv₂.complete_space_coe,
  rw [← orthogonal_orthogonal (span ℝ ({u} ∪ {v} : set E)), B hf h, mem_orthogonal],
  intros y hy,
  rw [mem_map] at hy,
  rcases hy with ⟨y', hy', Hy'⟩,
  rw [real_inner_comm, ← Hy'],
  exact H y' hy'
end

end linear_conformal_prep

open continuous_linear_map
open_locale topological_space filter

section diff_elementary

lemma DD1 {E F : Type*} [normed_group E] [normed_space ℝ E] [normed_group F] [normed_space ℝ F] 
  {f : E → F} {f' : E → (E →L[ℝ] F)} {y u : E} (hf : ∀ᶠ (x : E) in 𝓝 y, has_fderiv_at f (f' x) x)
  (hf' : differentiable_at ℝ f' y) : fderiv ℝ (λ x, f' x u) y = fderiv ℝ f' y u :=
begin
  have : (λ x, f' x u) = λ x, ((apply ℝ _ _) ∘ f') x :=
    by simp only [function.comp_app, apply_apply],
  simp only [this, congr_arg],
  rw fderiv.comp _ (apply ℝ F u).differentiable_at hf',
  ext1 v,
  simp only [(apply ℝ F u).fderiv, coe_comp', function.comp_app, apply_apply],
  exact second_derivative_symmetric_of_eventually hf hf'.has_fderiv_at _ _
end

lemma DD1' {E F : Type*} [normed_group E] [normed_space ℝ E] [normed_group F] [normed_space ℝ F]  
  {f' : E → E →L[ℝ] F} {f'' : E → (E →L[ℝ] E →L[ℝ] F)} {y u v w : E} 
  (hf : ∀ᶠ (x : E) in 𝓝 y, has_fderiv_at f' (f'' x) x) (hf' : differentiable_at ℝ f'' y) :
  fderiv ℝ (λ x, f'' x u v) y w = fderiv ℝ f'' y w u v :=
begin
  have triv : (λ x, f'' x u v) = λ x, ((apply ℝ _ _) ∘ 
    (λ x', f'' x' u)) x :=
    by simp only [function.comp_app, apply_apply],
  simp only [triv],
  rw [fderiv.comp _ (apply ℝ F v).differentiable_at, DD1 hf hf'],
  rw second_derivative_symmetric_of_eventually hf hf'.has_fderiv_at _ _,
  simp only [congr_arg, coe_comp', (apply ℝ F v).fderiv, apply_apply, function.comp_app],
  exact (apply ℝ (E →L[ℝ] F) u).differentiable_at.comp _ hf'
end

lemma is_open.is_const_of_fderiv_eq_zero {E F 𝕜 : Type*} [normed_group E] [normed_space ℝ E] 
  [is_R_or_C 𝕜] [normed_space 𝕜 E] [is_scalar_tower ℝ 𝕜 E] [normed_group F] [normed_space 𝕜 F] 
  {f : E → F} {s : set E} (hs : is_open s) (hs' : is_connected s) (hf : differentiable_on 𝕜 f s) 
  (h : ∀ x ∈ s, fderiv 𝕜 f x = 0) {x y : E} (hx : x ∈ s) (hy : y ∈ s) :
  f x = f y :=
begin
  rw is_connected_iff_connected_space at hs'; resetI,
  let S : set s := {a : s | f a = f x},
  have triv₁ : S.nonempty := ⟨⟨x, hx⟩, rfl⟩,
  have triv₂ := continuous_on_iff_continuous_restrict.mp hf.continuous_on,
  have minor₁ : is_closed S := is_closed_eq triv₂ continuous_const,
  have minor₂ : is_open S :=
  is_open_iff_forall_mem_open.mpr begin
    intros t ht,
    rcases metric.is_open_iff.mp hs t.1 t.2 with ⟨ε, hε, hball⟩,
    have subminor₁ : ∀ (x' : E), x' ∈ metric.ball t.1 ε → 
      fderiv_within 𝕜 f (metric.ball t.1 ε) x' = 0 := 
    λ x' hx', begin
      convert h x' (hball hx'),
      exact fderiv_within_of_open metric.is_open_ball hx'
    end,
    have subminor₂ : coe⁻¹' (metric.ball t.1 ε) ⊆ S :=
    λ a ha, begin
      have := (convex_ball t.1 ε).is_const_of_fderiv_within_eq_zero (hf.mono hball) 
        subminor₁ ha (metric.mem_ball_self hε),
      simp only [set.mem_set_of_eq] at ht,
      rw [subtype.val_eq_coe, ht] at this,
      exact this
    end,
    refine ⟨coe⁻¹' (metric.ball t.1 ε), subminor₂, 
      metric.is_open_ball.preimage continuous_subtype_coe, _⟩,
    simp only [subtype.val_eq_coe],
    exact metric.mem_ball_self hε
  end,
  have key : f y = f x := begin
    suffices new : (⟨y, hy⟩ : s) ∈ S,
    { exact new },
    { rw eq_univ_of_nonempty_clopen triv₁ ⟨minor₂, minor₁⟩,
      exact mem_univ _ }
  end,
  exact key.symm
end

lemma is_open.eq_sub_add_of_fderiv_eq_fderiv {E F 𝕜 : Type*} [normed_group E] [normed_space ℝ E] 
  [is_R_or_C 𝕜] [normed_space 𝕜 E] [is_scalar_tower ℝ 𝕜 E] [normed_group F] [normed_space 𝕜 F] 
  {f g : E → F} {s : set E} (hs : is_open s) (hs' : is_connected s) 
  (hf : differentiable_on 𝕜 f s) (hg : differentiable_on 𝕜 g s) 
  (h : ∀ x ∈ s, fderiv 𝕜 f x = fderiv 𝕜 g x) {x₀ : E} (hx₀ : x₀ ∈ s) :
  ∀ x ∈ s, f x = g x - g x₀ + f x₀ :=
begin
  refine λ x hx, sub_eq_zero.mp _,
  rw [sub_add_eq_add_sub, ← add_sub],
  have triv₁ : f x₀ - (g x₀ + (f x₀ - g x₀)) = 0 := by simp,
  rw ← triv₁,
  have triv₂ : differentiable_on 𝕜 (λ y, f y - (g y + (f x₀ - g x₀))) s := hf.sub (hg.add_const _),
  refine hs.is_const_of_fderiv_eq_zero hs' triv₂ (λ y hy, _) hx hx₀,
  rw [fderiv_sub ((hf y hy).differentiable_at $ hs.mem_nhds hy) 
      (((hg y hy).differentiable_at $ hs.mem_nhds hy).add_const _), 
      fderiv_add_const, h y hy, sub_self]
end

/-- Strangely the last statement cannot be simped... even if it's extremely simple -/
lemma is_open.exists_of_fderiv_eq_fderiv {E F 𝕜 : Type*} [normed_group E] [normed_space ℝ E] 
  [is_R_or_C 𝕜] [normed_space 𝕜 E] [is_scalar_tower ℝ 𝕜 E] [normed_group F] [normed_space 𝕜 F] 
  {f g : E → F} {s : set E} (hs : is_open s) (hs' : is_connected s) 
  (hf : differentiable_on 𝕜 f s) (hg : differentiable_on 𝕜 g s) 
  (h : ∀ x ∈ s, fderiv 𝕜 f x = fderiv 𝕜 g x) :
  ∃ y₀, ∀ x ∈ s, f x = g x - y₀ :=
let ⟨x₀, hx₀⟩ := hs'.nonempty in ⟨- (f x₀ - g x₀), λ x hx, 
  by simpa [sub_neg, sub_add] using hs.eq_sub_add_of_fderiv_eq_fderiv hs' hf hg h hx₀ x hx⟩

-- lemma is_open.exists_of_fderiv_eq_fderiv_of_has_fderiv_at 
--   {E F 𝕜 : Type*} [normed_group E] [normed_space ℝ E] [is_R_or_C 𝕜] 
--   [normed_space 𝕜 E] [is_scalar_tower ℝ 𝕜 E] [normed_group F] [normed_space 𝕜 F] 
--   {f g : E → F} {f'} {s : set E} (hs : is_open s) (hs' : is_connected s) 
--   (hf : differentiable_on 𝕜 f s) (hg : differentiable_on 𝕜 g s) 
--   (h : ∀ x ∈ s, fderiv 𝕜 f x = fderiv 𝕜 g x) :
--   ∃ x₀ ∈ s, ∀ x ∈ s, f x = g x - g x₀ + f x₀ :=
-- begin

-- end

end diff_elementary

section diff_prep

variables {E F : Type*} [normed_group E] [normed_group F] 
  [normed_space ℝ E] [normed_space ℝ F] {f : E → F}

lemma D21 {y : E} {n : ℕ} (hf : times_cont_diff_at ℝ n.succ f y) :
  ∀ᶠ (x : E) in 𝓝 y, has_fderiv_at f (fderiv ℝ f x) x :=
begin
  rcases times_cont_diff_at_succ_iff_has_fderiv_at.mp hf with ⟨f', ⟨s, hs, hxs⟩, hf'⟩,
  have minor₁ : ∀ (x : E), x ∈ s → differentiable_at ℝ f x := λ x hx, ⟨f' x, hxs x hx⟩,
  have minor₂ : ∀ (x : E), x ∈ s → has_fderiv_at f (fderiv ℝ f x) x := 
    λ x hx, (minor₁ x hx).has_fderiv_at,
  rw filter.eventually_iff_exists_mem,
  exact ⟨s, hs, minor₂⟩
end

lemma D22 {y : E} {n : ℕ} (hf : times_cont_diff_at ℝ n.succ f y) :
  times_cont_diff_at ℝ n (fderiv ℝ f) y :=
begin
  have triv₁ : (n : with_top ℕ) ≤ n + 1 := 
    by { apply with_top.coe_le_coe.mpr, exact nat.le_succ _ },
  have triv₂ : (1 : with_top ℕ) ≤ n + 1 := 
    by { apply with_top.coe_le_coe.mpr, linarith },
  rcases times_cont_diff_at_succ_iff_has_fderiv_at.mp hf with ⟨f', ⟨s, hs, hxs⟩, hf'⟩,
  have minor₁ : ∀ (x : E), x ∈ s → differentiable_at ℝ f x := λ x hx, ⟨f' x, hxs x hx⟩,
  have minor₂ : set.eq_on (fderiv ℝ f) f' s,
  { intros x hxmem,
    have := (hf.differentiable_at triv₂).has_fderiv_at,
    exact (minor₁ x hxmem).has_fderiv_at.unique (hxs x hxmem) },
  exact hf'.congr_of_eventually_eq (filter.eventually_eq_of_mem hs minor₂)
end

lemma D23 {y : E} {n : ℕ} (hn : 0 < n) (hf : times_cont_diff_at ℝ (n + 1) f y) :
  differentiable_at ℝ (fderiv ℝ f) y :=
(D22 hf).differentiable_at (with_top.coe_le_coe.mpr $ nat.succ_le_of_lt hn)

lemma DD2 {y : E} {n : ℕ} (hn : 0 < n) (hf : times_cont_diff_at ℝ (n + 1) f y) (u : E) :
  differentiable_at ℝ (λ x, fderiv ℝ f x u) y :=
(apply ℝ F u).differentiable_at.comp _ (D23 hn hf)

lemma third_order_symmetric {x u v w : E} (hf' : ∀ᶠ x' in 𝓝 x, times_cont_diff_at ℝ 3 f x') :
  fderiv ℝ (fderiv ℝ $ fderiv ℝ f) x w u v = fderiv ℝ (fderiv ℝ $ fderiv ℝ f) x v u w :=
begin
  have minor₁ : ∀ᶠ x' in 𝓝 x, has_fderiv_at ((apply ℝ _ u) ∘ (fderiv ℝ f)) 
    ((apply ℝ _ u).comp $ fderiv ℝ (fderiv ℝ f) x') x' :=
    hf'.mono (λ y hy, (apply ℝ F u).has_fderiv_at.comp _ (D23 zero_lt_two hy).has_fderiv_at),
  have minor₂ : (λ x', (apply ℝ _ u).comp $ fderiv ℝ (fderiv ℝ f) x') =ᶠ[𝓝 x] λ x',
    (((apply ℝ (E →L[ℝ] F)) u) ∘ fderiv ℝ (fderiv ℝ f)) x' :=
  hf'.mono (λ y hy, begin
    ext1,
    simp only [coe_comp', function.comp_app, apply_apply],
    rw second_derivative_symmetric_of_eventually (D21 hy) (D23 zero_lt_two hy).has_fderiv_at
  end),
  have key := (apply ℝ (E →L[ℝ] F) u).has_fderiv_at.comp _
    (D23 zero_lt_one $ D22 hf'.self_of_nhds).has_fderiv_at,
  have := second_derivative_symmetric_of_eventually minor₁ (key.congr_of_eventually_eq minor₂) v w,
  simp only [coe_comp', function.comp_app, apply_apply] at this,
  rw this
end

end diff_prep

section tot_diff_eq
open submodule

variables {E F : Type*} [inner_product_space ℝ E] [inner_product_space ℝ F] {f : E → F}

lemma D' (u v w : E) {y : E} {n : ℕ} (hn : 0 < n) (hf : times_cont_diff_at ℝ (n + 1) f y)  :
  fderiv ℝ (λ x, ⟪fderiv ℝ f x u, fderiv ℝ f x v⟫) y w = 
  ⟪fderiv ℝ (fderiv ℝ f) y u w, fderiv ℝ f y v⟫ + 
  ⟪fderiv ℝ f y u, fderiv ℝ (fderiv ℝ f) y v w⟫ :=
begin
  rw [fderiv_inner_apply (DD2 hn hf _) (DD2 hn hf _)],
  simp only [congr_arg, DD1 (D21 hf) (D23 hn hf), congr_arg, add_comm]
end

variables {x : E} (hf : ∀ᶠ x' in 𝓝 x, conformal_at f x') {f' : E → (E →L[ℝ] F)} 
  (Hf : ∀ (x' : E), is_conformal_map $ f' x') (Heven : fderiv ℝ f =ᶠ[𝓝 x] f')

localized "notation `conf_diff` := eventually_is_conformal_map_of_eventually_conformal hf"
  in liouville_do_not_use
localized "notation `conf_diff'` := 
  (eventually_is_conformal_map_of_eventually_conformal hf).self_of_nhds" 
  in liouville_do_not_use

include hf

lemma D (hf' : times_cont_diff_at ℝ 2 f x) {u v w : E} 
  (huv : ⟪u, v⟫ = 0) (hwu : ⟪w, u⟫ = 0) (hwv : ⟪w, v⟫ = 0) :
  ⟪fderiv ℝ (fderiv ℝ f) x u v, fderiv ℝ f x w⟫ = 0 :=
begin
  rw real_inner_comm at hwv,
  have m₁ := D' u v w zero_lt_one hf',
  have m₂ := D' v w u zero_lt_one hf',
  have m₃ := D' w u v zero_lt_one hf',
  rw [(A' huv conf_diff).fderiv_eq] at m₁,
  rw [(A' hwv conf_diff).fderiv_eq] at m₂,
  rw [(A' hwu conf_diff).fderiv_eq] at m₃,
  rw [fderiv_const, pi.zero_apply, continuous_linear_map.zero_apply] at m₁ m₂ m₃,
  rw add_comm at m₁ m₃,
  nth_rewrite 0 real_inner_comm at m₃ m₁,
  nth_rewrite 1 real_inner_comm at m₁,
  rw [second_derivative_symmetric_of_eventually (D21 hf') (D23 zero_lt_one hf').has_fderiv_at v u,
      second_derivative_symmetric_of_eventually (D21 hf') (D23 zero_lt_one hf').has_fderiv_at w u] 
      at m₂,
  rw [second_derivative_symmetric_of_eventually (D21 hf') (D23 zero_lt_one hf').has_fderiv_at w v] 
      at m₃,
  have triv₂ : ∀ {a b c : ℝ}, a + b = 0 → b + c = 0 → a + c = 0 → a = 0 :=
  λ a b c hab hbc hac, begin
    rw [← hab, ← zero_add (a + b), ← hac, ← add_assoc, ← zero_add (b + c)] at hbc,
    nth_rewrite 3 add_comm at hbc,
    rw [add_assoc, add_assoc] at hbc,
    nth_rewrite 1 ← add_assoc at hbc,
    nth_rewrite 4 add_comm at hbc,
    exact (add_self_eq_zero.mp $ add_right_cancel hbc.symm)
  end,
  exact triv₂ m₃.symm m₁.symm m₂.symm
end

lemma G'' (hf' : times_cont_diff_at ℝ 2 f x)
  (h : function.surjective (fderiv ℝ f x)) {u v : E} (huv : ⟪u, v⟫ = 0) :
  fderiv ℝ (fderiv ℝ f) x u v ∈ span ℝ ({fderiv ℝ f x u} ∪ {fderiv ℝ f x v} : set F) := 
begin
  refine C h conf_diff' (λ t ht, _),
  rw mem_orthogonal at ht,
  have triv₁ : u ∈ span ℝ ({u} ∪ {v} : set E) := subset_span (or.intro_left _ $ mem_singleton _),
  have triv₂ : v ∈ span ℝ ({u} ∪ {v} : set E) := subset_span (or.intro_right _ $ mem_singleton _),
  have minor₁ := ht u triv₁,
  have minor₂ := ht v triv₂,
  rw real_inner_comm at minor₁ minor₂,
  exact D hf hf' huv minor₁ minor₂
end

lemma G' (hf' : times_cont_diff_at ℝ 2 f x) 
  (h : function.surjective (fderiv ℝ f x)) {u v : E} (huv : ⟪u, v⟫ = 0) : 
  fderiv ℝ (fderiv ℝ f) x u v = 
  (⟪fderiv ℝ f x u, fderiv ℝ (fderiv ℝ f) x u v⟫ / ↑∥fderiv ℝ f x u∥ ^ 2) • fderiv ℝ f x u +
  (⟪fderiv ℝ f x v, fderiv ℝ (fderiv ℝ f) x u v⟫ / ↑∥fderiv ℝ f x v∥ ^ 2) • fderiv ℝ f x v :=
begin
  rw [← orthogonal_projection_singleton, ← orthogonal_projection_singleton],
  have := G'' hf hf' h huv,
  rw [span_union, mem_sup] at this,
  rcases this with ⟨p₁, hp₁, p₂, hp₂, hp₁p₂⟩,
  have triv₁ : fderiv ℝ (fderiv ℝ f) x u v - p₂ = p₁ := 
    by rw [← hp₁p₂, ← add_sub, sub_self, add_zero],
  have triv₂ : fderiv ℝ (fderiv ℝ f) x u v - p₁ = p₂ := 
    by { rw [← hp₁p₂, add_comm], rw [← add_sub, sub_self, add_zero] },
  rcases mem_span_singleton.mp hp₁ with ⟨s₁, hs₁⟩,
  rcases mem_span_singleton.mp hp₂ with ⟨s₂, hs₂⟩,
  have key₁ : ∀ (w : F), w ∈  span ℝ ({fderiv ℝ f x u} : set F) →
    ⟪fderiv ℝ (fderiv ℝ f) x u v - p₁, w⟫ = 0 :=
  λ w hw, begin
    rcases mem_span_singleton.mp hw with ⟨s', hs'⟩,
    rw [← hs', triv₂, ← hs₂, real_inner_smul_left, real_inner_smul_right],
    rw [real_inner_comm, A conf_diff'] at huv,
    rw [huv, mul_zero, mul_zero]
  end,
  have key₂ : ∀ (w : F), w ∈  span ℝ ({fderiv ℝ f x v} : set F) →
    ⟪fderiv ℝ (fderiv ℝ f) x u v - p₂, w⟫ = 0 :=
  λ w hw, begin
    rcases mem_span_singleton.mp hw with ⟨s', hs'⟩,
    rw [← hs', triv₁, ← hs₁, real_inner_smul_left, real_inner_smul_right],
    rw [A conf_diff'] at huv,
    rw [huv, mul_zero, mul_zero]
  end,
  rw [eq_orthogonal_projection_of_mem_of_inner_eq_zero hp₁ key₁, 
      eq_orthogonal_projection_of_mem_of_inner_eq_zero hp₂ key₂],
  exact hp₁p₂.symm
end

include Hf Heven

lemma G [nontrivial E] (hf' : times_cont_diff_at ℝ 2 f x) (u v : E)  : 
  ⟪fderiv ℝ (fderiv ℝ f) x u v, fderiv ℝ f x u⟫ + 
  ⟪fderiv ℝ f x u, fderiv ℝ (fderiv ℝ f) x u v⟫ =
  2 * ((conformal_factor_sqrt conf_diff') * 
  (fderiv ℝ (λ y, conformal_factor_sqrt $ Hf y) x v) * ⟪u, u⟫) :=
begin
  rcases filter.eventually_eq_iff_exists_mem.mp Heven with ⟨s, hs, heq⟩,
  rw ← D' u u v zero_lt_one hf',
  have : (λ (y : E), ⟪fderiv ℝ f y u, fderiv ℝ f y u⟫) =ᶠ[𝓝 x] 
    (λ y, ⟪u, u⟫ * id y) ∘ (λ y, conformal_factor $ Hf y),
  { rw filter.eventually_eq_iff_exists_mem,
    refine ⟨s, hs, _⟩,
    intros z hz,
    simp only [function.comp_app, congr_arg],
    rw [mul_comm, heq hz],
    exact (conformal_factor_prop $ Hf z).2 u u },
  have minor₁ := (D22 hf').congr_of_eventually_eq Heven.symm,
  have minor₂ := (conformal_factor_times_cont_diff_at x Hf minor₁).differentiable_at 
    (le_of_eq rfl),
  have minor₃ := (conformal_factor_sqrt_times_cont_diff_at x Hf minor₁).differentiable_at 
    (le_of_eq rfl),
  rw [this.fderiv_eq, fderiv.comp _ (differentiable_at_id.const_mul _) minor₂, 
      fderiv_const_mul differentiable_at_id ⟪u, u⟫, fderiv_id],
  rw ← conformal_factor_sqrt_eq Hf,
  simp only [pow_two], 
  rw [fderiv_mul minor₃ minor₃, coe_comp'],
  simp only [function.comp_app, coe_add', pi.add_apply, 
             continuous_linear_map.smul_apply, smul_eq_mul, coe_id'],
  simp only [_root_.id],
  rw conformal_factor_sqrt_eq_of_eq conf_diff' Heven.self_of_nhds,
  ring
end

lemma GG' {u v : E} (hu : u ≠ 0) (hf' : times_cont_diff_at ℝ 2 f x) : 
  ⟪fderiv ℝ (fderiv ℝ f) x u v, fderiv ℝ f x u⟫ / ⟪u, u⟫ = 
  conformal_factor_sqrt conf_diff' * (fderiv ℝ (λ y, conformal_factor_sqrt $ Hf y) x v) :=
begin
  haveI : nontrivial E := nontrivial_of_ne u 0 hu,
  have key := G hf Hf Heven hf' u v,
  rw [real_inner_comm, ← two_mul, real_inner_comm] at key,
  have triv : ⟪u, u⟫ ≠ 0 := λ W, hu (inner_self_eq_zero.mp W),
  rw div_eq_iff_mul_eq triv,
  convert (mul_left_cancel' _ key).symm,
  exact two_ne_zero  
end

lemma GG1 {u v : E} (hu : u ≠ 0) (hf' : times_cont_diff_at ℝ 2 f x) : 
  ⟪fderiv ℝ f x u, fderiv ℝ (fderiv ℝ f) x u v⟫ / ∥fderiv ℝ f x u∥ ^ 2 =
  (fderiv ℝ (λ y, conformal_factor_sqrt $ Hf y) x v) *
  conformal_factor_sqrt_inv conf_diff' :=
begin
  rw [pow_two, ← real_inner_self_eq_norm_sq],
  have triv₁ : ⟪u, u⟫ ≠ 0 := λ W, hu (inner_self_eq_zero.mp W),
  rw [← div_mul_div_cancel _ triv₁,
      (conformal_factor_sqrt_inv_prop conf_diff').2,
      real_inner_comm, GG' hf Hf Heven hu hf'],
  simp only [conformal_factor_sqrt_inv, inv_inv', congr_arg],
  field_simp [triv₁, (conformal_factor_sqrt_prop conf_diff').1],
  ring
end

lemma GG2 {u v : E} (hv : v ≠ 0) (hf' : times_cont_diff_at ℝ 2 f x) :
  ⟪fderiv ℝ f x v, fderiv ℝ (fderiv ℝ f) x u v⟫ / ∥fderiv ℝ f x v∥ ^ 2 =
  (fderiv ℝ (λ y, conformal_factor_sqrt $ Hf y) x u) *
  conformal_factor_sqrt_inv conf_diff' :=
begin
  rw second_derivative_symmetric_of_eventually (D21 hf') (D23 zero_lt_one hf').has_fderiv_at u v,
  exact GG1 hf Hf Heven hv hf'
end

open filter
open_locale filter

lemma GGG_eventually_eq {u v : E} {s : set E} (hxs : x ∈ s) 
  (hs : is_open s) (hu : u ≠ 0) (hv : v ≠ 0) (huv : ⟪u, v⟫ = 0)
  (hf' : ∀ y ∈ s, times_cont_diff_at ℝ 2 f y) (h : ∀ y ∈ s, function.surjective (fderiv ℝ f y)) : 
  (λ x', (conformal_factor_sqrt_inv $ Hf x') • (fderiv ℝ (fderiv ℝ f) x' u v) +
  (fderiv ℝ (λ y, conformal_factor_sqrt_inv $ Hf y) x' v) • fderiv ℝ f x' u + 
  (fderiv ℝ (λ y, conformal_factor_sqrt_inv $ Hf y) x' u) • fderiv ℝ f x' v) =ᶠ[𝓝 x] 
  λ x', (0 : F) :=
begin
  haveI : nontrivial E := nontrivial_of_ne u 0 hu,
  rcases eventually_iff_exists_mem.mp hf with ⟨s₁, hs₁, hy₁⟩,
  rcases eventually_eq_iff_exists_mem.mp Heven with ⟨s₂, hs₂, hy₂⟩,
  have triv₁ : (s₁ ∩ s₂) ∩ s ∈ 𝓝 x := inter_mem (inter_mem hs₁ hs₂) 
    (hs.mem_nhds hxs),
  rcases mem_nhds_iff.mp triv₁ with ⟨t, ht, hxt₁, hxt₂⟩,
  refine eventually_eq_of_mem (hxt₁.mem_nhds hxt₂) (λ y hy, _),
  have minor₁ : ∀ᶠ x' in 𝓝 y, conformal_at f x' :=
    eventually_iff_exists_mem.mpr ⟨t, hxt₁.mem_nhds hy, λ y' hy', hy₁ y' (ht hy').1.1⟩,
  have minor₂ : fderiv ℝ f =ᶠ[𝓝 y] f' :=
    eventually_iff_exists_mem.mpr ⟨t, hxt₁.mem_nhds hy, λ y' hy', hy₂ (ht hy').1.2⟩,
  simp only [congr_arg],
  have key₁ := (hf' y (ht hy).2),
  have key₂ := h y (ht hy).2,
  have minor₃ := (D22 key₁).congr_of_eventually_eq minor₂.symm,
  have key := conformal_factor_sqrt_inv_fderiv y Hf zero_lt_one minor₃,
  rw [G' minor₁ key₁ key₂ huv, key],
  simp only [is_R_or_C.coe_real_eq_id, _root_.id],
  rw [GG1 minor₁ Hf minor₂ hu key₁, GG2 minor₁ Hf minor₂ hv key₁],
  simp only [smul_add, smul_smul, pi.neg_apply, pi.mul_apply, congr_arg],
  rw [← conformal_factor_sqrt_inv_eq', inv_pow', inv_inv', pow_two],
  rw conformal_factor_sqrt_inv_eq_of_eq (Hf y) minor₂.symm.self_of_nhds,
  nth_rewrite 1 add_comm,
  simp only [← add_assoc, ← add_smul, add_assoc, ← add_smul],
  rw [neg_mul_eq_neg_mul_symm, neg_add_eq_sub],
  simp only [mul_assoc, mul_comm, sub_self, zero_smul],
  simp
end

lemma J1 {u : E} (v w : E) (hu : u ≠ 0) (hf' : ∀ᶠ x' in 𝓝 x, times_cont_diff_at ℝ 3 f x') :
  fderiv ℝ (λ x, (fderiv ℝ (λ y, conformal_factor_sqrt_inv $ Hf y) x v) • 
  fderiv ℝ f x u) x w = fderiv ℝ (fderiv ℝ $ λ y, conformal_factor_sqrt_inv $ Hf y) x w v • 
  fderiv ℝ f x u + fderiv ℝ (λ y, conformal_factor_sqrt_inv $ Hf y) x v • 
  fderiv ℝ (fderiv ℝ f) x w u :=
begin
  haveI : nontrivial E := nontrivial_of_ne u 0 hu,
  have minor₀ := conformal_factor_sqrt_inv_times_cont_diff_at x Hf 
    ((D22 hf'.self_of_nhds).congr_of_eventually_eq Heven.symm),
  have minor₁ := hf.mono (λ x' hx', hx'.differentiable_at.has_fderiv_at),
  have minor₂ := D23 zero_lt_two hf'.self_of_nhds,
  have minor₃ : ∀ᶠ x' in 𝓝 x, times_cont_diff_at ℝ 2 (fderiv ℝ f) x' := hf'.mono (λ a ha, D22 ha),
  have minor₄ : ∀ᶠ x' in 𝓝 x, has_fderiv_at (λ y, conformal_factor_sqrt_inv $ Hf y) 
    (fderiv ℝ (λ y, conformal_factor_sqrt_inv $ Hf y) x') x' :=
    D21 (conformal_factor_sqrt_inv_times_cont_diff_at _ Hf $
    minor₃.self_of_nhds.congr_of_eventually_eq Heven.symm),
  have minor₅ := D23 zero_lt_one minor₀,
  rw fderiv_smul,
  simp only [continuous_linear_map.add_apply, continuous_linear_map.smul_apply, 
             continuous_linear_map.smul_right_apply, congr_arg],
  rw [DD1 minor₁ minor₂, DD1 minor₄ minor₅], 
  simp only [congr_arg],
  rw [second_derivative_symmetric_of_eventually minor₁ minor₂.has_fderiv_at,
      second_derivative_symmetric_of_eventually minor₄ minor₅.has_fderiv_at, add_comm],
  exact DD2 zero_lt_one (conformal_factor_sqrt_inv_times_cont_diff_at _ 
    Hf $ minor₃.self_of_nhds.congr_of_eventually_eq Heven.symm) v,
  exact DD2 zero_lt_two hf'.self_of_nhds u
end

lemma J2 {u : E} (v w : E) (hu : u ≠ 0) (hf' : times_cont_diff_at ℝ 4 f x) :
  fderiv ℝ (λ x', (conformal_factor_sqrt_inv $ Hf x') • fderiv ℝ (fderiv ℝ f) x' u v) x w 
  = fderiv ℝ (λ x', conformal_factor_sqrt_inv $ Hf x') x w • 
  fderiv ℝ (fderiv ℝ f) x u v + conformal_factor_sqrt_inv conf_diff' •
  fderiv ℝ (fderiv ℝ $ fderiv ℝ f) x w u v :=
begin
  haveI : nontrivial E := nontrivial_of_ne u 0 hu,
  have := conformal_factor_sqrt_inv_times_cont_diff_at x Hf 
    ((D22 hf').congr_of_eventually_eq Heven.symm),
  rw fderiv_smul,
  simp only [add_apply, smul_apply, smul_right_apply, congr_arg],
  rw [DD1' (D21 $ D22 hf') (D23 zero_lt_two $ D22 hf')],
  simp only [add_comm, congr_arg],
  rw conformal_factor_sqrt_inv_eq_of_eq _ Heven.self_of_nhds,
  exact this.differentiable_at (with_top.coe_le_coe.mpr $ nat.succ_le_succ zero_le_two),
  exact (apply ℝ F v).differentiable_at.comp _ 
    ((apply ℝ (E →L[ℝ] F) u).differentiable_at.comp _ $ D23 zero_lt_two $ D22 hf'),
end

lemma J2' {u : E} (v w : E) (hu : u ≠ 0) (hf' : ∀ᶠ x' in 𝓝 x, times_cont_diff_at ℝ 4 f x') :
  fderiv ℝ (λ x', (conformal_factor_sqrt_inv $ Hf x') • fderiv ℝ (fderiv ℝ f) x' u v) x w 
  = fderiv ℝ (λ x', conformal_factor_sqrt_inv $ Hf x') x w • 
  fderiv ℝ (fderiv ℝ f) x u v + conformal_factor_sqrt_inv conf_diff' •
  fderiv ℝ (fderiv ℝ $ fderiv ℝ f) x v u w :=
by rw [J2 hf Hf Heven v w hu hf'.self_of_nhds, 
       third_order_symmetric (hf'.mono $ λ a ha, ha.of_le $ 
       by { apply with_top.coe_le_coe.mpr, norm_num })]

lemma tot1 {u v w : E}
  (hw : w ≠ 0) (huv : ⟪u, v⟫ = 0) (huw : ⟪u, w⟫ = 0) (hwv : ⟪w, v⟫ = 0)
  (hf' : ∀ᶠ x' in 𝓝 x, times_cont_diff_at ℝ 4 f x') 
  (h : ∀ᶠ x' in 𝓝 x , function.surjective (fderiv ℝ f x')) :
  fderiv ℝ (fderiv ℝ $ λ y, conformal_factor_sqrt_inv $ Hf y) x v u = 0 :=
begin
  by_cases hv : v ≠ 0; by_cases hu : u ≠ 0,
  { have triv₁ : (2 : with_top ℕ) ≤ 4,
    { apply with_top.coe_le_coe.mpr,
      norm_num },
    have triv₂ : (3 : with_top ℕ) ≤ 4,
    { apply with_top.coe_le_coe.mpr,
      norm_num },
    have triv₃ : (1 : with_top ℕ) ≤ 3,
    { apply with_top.coe_le_coe.mpr,
      norm_num },
    haveI : nontrivial E := nontrivial_of_ne u 0 hu,
    have minor₁ := conformal_factor_sqrt_inv_times_cont_diff_at x Hf 
      ((D22 hf'.self_of_nhds).congr_of_eventually_eq Heven.symm),
    have minor₂ := hf.mono (λ x' hx', hx'.differentiable_at.has_fderiv_at),
    have minor₃ : ∀ᶠ x' in 𝓝 x, times_cont_diff_at ℝ 2 (fderiv ℝ f) x' := 
      hf'.mono (λ a ha, D22 $ ha.of_le triv₂),
    have minor₄ : ∀ᶠ x' in 𝓝 x, has_fderiv_at (λ y, conformal_factor_sqrt_inv $ Hf y) 
      (fderiv ℝ (λ y, conformal_factor_sqrt_inv $ Hf y) x') x' :=
      D21 (conformal_factor_sqrt_inv_times_cont_diff_at _ Hf $
      minor₃.self_of_nhds.congr_of_eventually_eq Heven.symm),
    rcases eventually_iff_exists_mem.mp hf' with ⟨s₁, hs₁, hy₁⟩,
    rcases eventually_iff_exists_mem.mp h with ⟨s₂, hs₂, hy₂⟩,
    rcases mem_nhds_iff.mp (inter_mem hs₁ hs₂) with ⟨t, ht, Ht₁, Ht₂⟩,
    have m₁ : fderiv ℝ _ _ w = (0 : F),
    { rw (GGG_eventually_eq hf Hf Heven Ht₂ Ht₁ hu hv huv 
      (λ y' hy', (hy₁ y' (ht hy').1).of_le triv₁) $ λ y' hy', hy₂ y' (ht hy').2).fderiv_eq,
      simp only [congr_arg, fderiv_const, pi.zero_apply, zero_apply] },
    have m₂ : fderiv ℝ _ _ v = (0 : F),
    { rw (GGG_eventually_eq hf Hf Heven Ht₂ Ht₁ hu hw huw
      (λ y' hy', (hy₁ y' (ht hy').1).of_le triv₁) $ λ y' hy', hy₂ y' (ht hy').2).fderiv_eq,
      simp only [congr_arg, fderiv_const, pi.zero_apply, zero_apply] },
    rw ← m₂ at m₁,
    have diff₁ := (apply ℝ ℝ u).differentiable_at.comp _ (D23 zero_lt_two minor₁),
    have diff₁' := (apply ℝ ℝ v).differentiable_at.comp _ (D23 zero_lt_two minor₁),
    have diff₁'' := (apply ℝ ℝ w).differentiable_at.comp _ (D23 zero_lt_two minor₁),
    have diff₂ := (apply ℝ F v).differentiable_at.comp _ 
      ((D22 hf'.self_of_nhds).differentiable_at triv₃),
    have diff₂' := (apply ℝ F u).differentiable_at.comp _ 
      ((D22 hf'.self_of_nhds).differentiable_at triv₃),
    have diff₂'' := (apply ℝ F w).differentiable_at.comp _ 
      ((D22 hf'.self_of_nhds).differentiable_at triv₃),
    have diff₃ := (apply ℝ F v).differentiable_at.comp _ 
      ((apply ℝ (E →L[ℝ] F) u).differentiable_at.comp _ $ D23 zero_lt_two $ D22 hf'.self_of_nhds),
    have diff₃' := (apply ℝ F w).differentiable_at.comp _ 
      ((apply ℝ (E →L[ℝ] F) u).differentiable_at.comp _ $ D23 zero_lt_two $ D22 hf'.self_of_nhds),
    have diff_mk₁ := diff₁.smul diff₂,
    have diff_mk₁' := diff₁.smul diff₂'',
    have diff_mk₂ := diff₁'.smul diff₂',
    have diff_mk₂' := diff₁''.smul diff₂',
    have diff_mk₃ := (minor₁.differentiable_at triv₃).smul diff₃,
    have diff_mk₃' := (minor₁.differentiable_at triv₃).smul diff₃',
    simp only [congr_arg, function.comp_app, apply_apply] at 
      diff_mk₁ diff_mk₁' diff_mk₂ diff_mk₂' diff_mk₃ diff_mk₃',
    have times₁ := hf'.mono (λ a ha, ha.of_le triv₂), 
    rw [fderiv_add (diff_mk₃.add diff_mk₂) diff_mk₁, fderiv_add diff_mk₃ diff_mk₂,
        fderiv_add (diff_mk₃'.add diff_mk₂') diff_mk₁', fderiv_add diff_mk₃' diff_mk₂'] at m₁,
    simp only [add_apply] at m₁,
    rw [J1 hf Hf Heven v w hu times₁, J1 hf Hf Heven u w hv times₁,
        J1 hf Hf Heven w v hu times₁, J1 hf Hf Heven u v hw times₁] at m₁,
    rw [J2' hf Hf Heven v w hu hf', J2 hf Hf Heven w v hu hf'.self_of_nhds] at m₁,
    rw [second_derivative_symmetric_of_eventually (D21 hf'.self_of_nhds) 
        (D23 zero_lt_three hf'.self_of_nhds).has_fderiv_at w u, 
        second_derivative_symmetric_of_eventually (D21 hf'.self_of_nhds) 
        (D23 zero_lt_three hf'.self_of_nhds).has_fderiv_at u v,
        second_derivative_symmetric_of_eventually (D21 hf'.self_of_nhds) 
        (D23 zero_lt_three hf'.self_of_nhds).has_fderiv_at w v] at m₁,
    rw second_derivative_symmetric_of_eventually minor₄ 
      (D23 zero_lt_two minor₁).has_fderiv_at at m₁,
    clear minor₁ minor₂ minor₃ minor₄ m₂ diff₁ diff₁' diff₁'' diff₂ diff₂' diff₂'' diff₃ 
      diff₃' diff_mk₁ diff_mk₁' diff_mk₂ diff_mk₂' diff_mk₃ diff_mk₃' times₁,
    -- if I don't make a `quick1` lemma the there will be a time-out failure.
    have key := quick1 m₁,
    clear m₁,
    have triv₄ : ⟪fderiv ℝ f x w, fderiv ℝ f x w⟫ ≠ 0 := 
      λ W, (hw $ inner_self_eq_zero.mp $ (A conf_diff').mpr W),
    rw [← mul_div_cancel 
        (fderiv ℝ (fderiv ℝ $ λ y, conformal_factor_sqrt_inv $ Hf y) x v u) triv₄],
    simp only [congr_arg] at key,
    rw [← real_inner_smul_right, ← key, real_inner_smul_right, 
        (A conf_diff').mp hwv, mul_zero, zero_div] },
  { rw not_not.mp hu,
    simp only [continuous_linear_map.map_zero] },
  { rw not_not.mp hv,
    simp only [continuous_linear_map.map_zero, continuous_linear_map.zero_apply] },
  { rw not_not.mp hu,
    simp only [continuous_linear_map.map_zero] }
end

end tot_diff_eq

section bilin_form_and_local_prop 
open continuous_linear_map filter

variables {E F : Type*} [inner_product_space ℝ E] [inner_product_space ℝ F] {f : E → F}
  {s : set E} (hs : is_open s) (hfs : ∀ x ∈ s, conformal_at f x) 
  (hf's : ∀ x ∈ s, times_cont_diff_at ℝ 4 f x) 
  (hsurj : ∀ x ∈ s , function.surjective (fderiv ℝ f x))
  {f' : E → (E →L[ℝ] F)} (Hf : ∀ (x' : E), is_conformal_map $ f' x')
  (Hevens : ∀ x ∈ s, fderiv ℝ f x = f' x)

def to_sym_bilin_form (x : E) : bilin_form ℝ E :=
{ bilin := λ u v, fderiv ℝ (fderiv ℝ $ λ y, conformal_factor_sqrt_inv $ Hf y) x v u,
  bilin_add_left := λ x y z, by simp only [map_add],
  bilin_smul_left := λ s x y, by simp only [map_smul, smul_eq_mul],
  bilin_add_right := λ x y z, by simp only [map_add, add_apply],
  bilin_smul_right := λ s x y, by simp only [map_smul, smul_apply, smul_eq_mul] }

include hs Hevens hf's

lemma is_sym_to_sym_bilin_form [nontrivial E] {x : E} (hx : x ∈ s) :
  sym_bilin_form.is_sym (to_sym_bilin_form Hf x) :=
λ u v, begin
  have Heven := eventually_eq_iff_exists_mem.mpr ⟨s, hs.mem_nhds hx, λ a ha, Hevens a ha⟩,
  have minor₁ := conformal_factor_sqrt_inv_times_cont_diff_at x Hf 
    ((D22 $ hf's x hx).congr_of_eventually_eq Heven.symm),
  have minor₂ : ∀ᶠ x' in 𝓝 x, has_fderiv_at (λ y, conformal_factor_sqrt_inv $ Hf y) 
    (fderiv ℝ (λ y, conformal_factor_sqrt_inv $ Hf y) x') x' :=
    D21 (conformal_factor_sqrt_inv_times_cont_diff_at _ Hf $
    (D22 $ hf's x hx).congr_of_eventually_eq Heven.symm),
  rw [to_sym_bilin_form, bilin_form.coe_fn_mk, 
      second_derivative_symmetric_of_eventually minor₂ (D23 zero_lt_two minor₁).has_fderiv_at]
end

include hfs hsurj

lemma hB (hrank3 : ∀ (u v : E), ∃ w, w ≠ 0 ∧ ⟪u, w⟫ = 0 ∧ ⟪w, v⟫ = 0) : 
  ∀ x' (hx' : x' ∈ s) u' v', ⟪u', v'⟫ = 0 → to_sym_bilin_form Hf x' u' v' = 0 :=
λ x' hx' u' v' huv', begin
  have hf := eventually_iff_exists_mem.mpr ⟨s, hs.mem_nhds hx', λ a ha, hfs a ha⟩,
  have Heven := eventually_eq_iff_exists_mem.mpr ⟨s, hs.mem_nhds hx', λ a ha, Hevens a ha⟩,
  have hf' := eventually_iff_exists_mem.mpr ⟨s, hs.mem_nhds hx', λ a ha, hf's a ha⟩,
  have h := eventually_iff_exists_mem.mpr ⟨s, hs.mem_nhds hx', λ a ha, hsurj a ha⟩,
  simp only [to_sym_bilin_form],
  rcases hrank3 u' v' with ⟨w', hw', huw', hwv'⟩,
  exact tot1 hf Hf Heven hw' huv' huw' hwv' hf' h
end

variables [complete_space E] [nontrivial E] 
  (hrank3 : ∀ (u v : E), ∃ w, w ≠ 0 ∧ ⟪u, w⟫ = 0 ∧ ⟪w, v⟫ = 0)

lemma diff_bilin {x : E} (hx : x ∈ s) :
  differentiable_at ℝ (λ x', bilin_form_factor (hB hs hfs hf's hsurj Hf Hevens hrank3) 
  (λ y hy, is_sym_to_sym_bilin_form hs hf's Hf Hevens hy) x') x :=
begin
  rcases hrank3 0 0 with ⟨w₀, hw₀, _⟩,
  have hb := hB hs hfs hf's hsurj Hf Hevens hrank3,
  have hb' := λ y hy, is_sym_to_sym_bilin_form hs hf's Hf Hevens hy,
  have triv₁ : ⟪w₀, w₀⟫ ≠ 0 := λ W, hw₀ (inner_self_eq_zero.mp W),
  have minor₁ : (λ x', to_sym_bilin_form Hf x' w₀ w₀ / ⟪w₀, w₀⟫) =ᶠ[𝓝 x] 
    λ x', (bilin_form_factor hb hb' x'),
  { refine eventually_eq_iff_exists_mem.mpr ⟨s, hs.mem_nhds hx, λ y hy, _⟩,
    simp only [congr_arg, bilin_form_factor_prop hb hb' hy],
    rw mul_div_cancel _ triv₁ },
  simp only [to_sym_bilin_form, bilin_form.coe_fn_mk] at minor₁,
  refine differentiable_at.congr_of_eventually_eq _ minor₁.symm,
  simp only [div_eq_mul_inv, ← smul_eq_mul],
  apply differentiable_at.smul_const,
  have Heven := eventually_eq_iff_exists_mem.mpr ⟨s, hs.mem_nhds hx, λ a ha, Hevens a ha⟩,
  have triv₂ : (λ x', fderiv ℝ (fderiv ℝ $ λ y, 
    conformal_factor_sqrt_inv $ Hf y) x' w₀ w₀) = (apply ℝ _ w₀) ∘ 
    (λ x', fderiv ℝ (fderiv ℝ $ λ y, conformal_factor_sqrt_inv $ Hf y) x' w₀),
  { ext1,
    simp only [apply_apply, function.comp_app] },
  rw triv₂,
  refine (apply ℝ ℝ w₀).differentiable_at.comp _ (DD2 zero_lt_one (D22 _) w₀),
  exact conformal_factor_sqrt_inv_times_cont_diff_at x Hf 
    ((D22 $ hf's x hx).congr_of_eventually_eq Heven.symm)
end

localized "notation `H₁` := hB hs hfs hf's hsurj Hf Hevens hrank3" in liouville_do_not_use
localized "notation `H₂` := λ y hy, is_sym_to_sym_bilin_form hs hf's Hf Hevens hy" 
  in liouville_do_not_use

lemma fderiv_fderiv_eq_bilin_form_factor_mul {x : E} (hx : x ∈ s) (u v : E) :
  (λ x', fderiv ℝ (fderiv ℝ $ λ y, conformal_factor_sqrt_inv $ Hf y) x' v u) =ᶠ[𝓝 x] 
  λ x', (bilin_form_factor H₁ H₂ x') * ⟪u, v⟫ :=
eventually_eq_iff_exists_mem.mpr ⟨s, hs.mem_nhds hx, λ y hy,
  by simpa [to_sym_bilin_form, bilin_form.coe_fn_congr] using bilin_form_factor_prop H₁ H₂ hy u v⟩

/-- Not sure if `is_connected s` is a correct hypothesis. But it seems that this argument is used
  to show that the `bilin_form_factor` is indeed a constant. -/
lemma is_const_bilin_form_factor (hs' : is_connected s) :
  ∃ (c : ℝ), ∀ x (hx : x ∈ s), bilin_form_factor H₁ H₂ x = c :=
begin
  rcases hs'.nonempty with ⟨x₀, hx₀⟩,
  refine ⟨bilin_form_factor H₁ H₂ x₀, λ x hx, _⟩,
  have : ∀ y ∈ s, fderiv ℝ (λ x', bilin_form_factor H₁ H₂ x') y = 0 :=
  λ y hy, begin
    have triv₁ : ∀ᶠ x' in 𝓝 y, 
      times_cont_diff_at ℝ 3 (λ y, conformal_factor_sqrt_inv $ Hf y) x' :=
      eventually_iff_exists_mem.mpr ⟨s, hs.mem_nhds hy, λ x' hx', 
      conformal_factor_sqrt_inv_times_cont_diff_at x' Hf 
      ((D22 $ hf's x' hx').congr_of_eventually_eq 
      (eventually_eq_iff_exists_mem.mpr ⟨s, hs.mem_nhds hx', λ a ha, Hevens a ha⟩).symm)⟩,
    have minor₁ := fderiv_fderiv_eq_bilin_form_factor_mul hs hfs hf's hsurj Hf Hevens hrank3 hy,
    have minor₂ := diff_bilin hs hfs hf's hsurj Hf Hevens hrank3 hy,
    have minor₃ : ∀ u v w, 
      fderiv ℝ (fderiv ℝ $ fderiv ℝ $ λ y, conformal_factor_sqrt_inv $ Hf y) y w u v =
      fderiv ℝ (λ x', bilin_form_factor H₁ H₂ x') y w * ⟪u, v⟫ :=
    λ u v w, begin
      have Heven := eventually_eq_iff_exists_mem.mpr ⟨s, hs.mem_nhds hy, λ a ha, Hevens a ha⟩,
      have subkey₁ := D21 (D22 $ conformal_factor_sqrt_inv_times_cont_diff_at _ Hf $
        (D22 $ hf's y hy).congr_of_eventually_eq Heven.symm),
      rw [← DD1' subkey₁ (D23 zero_lt_one $ D22 triv₁.self_of_nhds), (minor₁ v u).fderiv_eq, 
          fderiv_mul_const minor₂, smul_apply, real_inner_comm, smul_eq_mul, mul_comm]
    end,
    ext1 v,
    simp only [zero_apply],
    rcases hrank3 v v with ⟨w, hw, hvw, _⟩,
    have key_aux : fderiv ℝ (λ x', bilin_form_factor H₁ H₂ x') y w • v -
      fderiv ℝ (λ x', bilin_form_factor H₁ H₂ x') y v • w = 0 :=
    by rw [← inner_self_eq_zero, inner_sub_right, real_inner_smul_right, real_inner_smul_right,
           ← minor₃, ← minor₃, third_order_symmetric triv₁, sub_self],
    have key := eq_of_sub_eq_zero key_aux,
    have minor₅ : (fderiv ℝ (λ x', bilin_form_factor H₁ H₂ x') y v) *
      (fderiv ℝ (λ x', bilin_form_factor H₁ H₂ x') y v) * ⟪w, w⟫ = 0 :=
    by rw [mul_assoc, ← real_inner_smul_left, ← key, 
           real_inner_smul_left, hvw, mul_zero, mul_zero],
    exact mul_self_eq_zero.mp (eq_zero_of_ne_zero_of_mul_right_eq_zero 
      (λ W, hw $ inner_self_eq_zero.mp W) minor₅)
  end,
  exact hs.is_const_of_fderiv_eq_zero hs' (λ x' hx', 
    (diff_bilin hs hfs hf's hsurj Hf Hevens hrank3 hx').differentiable_within_at) this hx hx₀
end

end bilin_form_and_local_prop

section integrate

open continuous_linear_map filter

variables {E F : Type*} [inner_product_space ℝ E] [inner_product_space ℝ F] {f : E → F}
  {s : set E} (hs : is_open s) (hs' : is_connected s) (hfs : ∀ x ∈ s, conformal_at f x) 
  (hf's : ∀ x ∈ s, times_cont_diff_at ℝ 4 f x) 
  (hsurj : ∀ x ∈ s , function.surjective (fderiv ℝ f x))
  {f' : E → (E →L[ℝ] F)} (Hf : ∀ (x' : E), is_conformal_map $ f' x')
  (Hevens : ∀ x ∈ s, fderiv ℝ f x = f' x)

variables [complete_space E] [nontrivial E] 
  (hrank3 : ∀ (u v : E), ∃ w, w ≠ 0 ∧ ⟪u, w⟫ = 0 ∧ ⟪w, v⟫ = 0)

localized "notation `H₁` := hB hs hfs hf's hsurj Hf Hevens hrank3" in liouville_do_not_use
localized "notation `H₂` := λ y hy, is_sym_to_sym_bilin_form hs hf's Hf Hevens hy" 
  in liouville_do_not_use

include hs hs' hfs hf's hsurj Hf Hevens hrank3

open inner_product_space

lemma conformal_factor_sqrt_inv_eq_const_mul_dist_add_const 
  (hnonzero : ∀ x ∈ s, bilin_form_factor H₁ H₂ x ≠ 0) :
  ∃ (α β : ℝ) (hα : α ≠ 0) (x₀ : E), 
  ∀ x ∈ s, conformal_factor_sqrt_inv (Hf x) = α * ∥x - x₀∥ ^ 2 + β :=
begin
  rcases is_const_bilin_form_factor hs hfs hf's hsurj Hf Hevens hrank3 hs' with ⟨c, hc⟩,
  have key₁ : ∀ x ∈ s, 
    fderiv ℝ (fderiv ℝ $ λ y, conformal_factor_sqrt_inv $ Hf y) x =
    fderiv ℝ (λ y, c • to_dual y) x :=
  λ x hx, begin
    ext v u,
    have triv₁ := (fderiv_fderiv_eq_bilin_form_factor_mul hs hfs hf's hsurj Hf 
      Hevens hrank3 hx u v).self_of_nhds,
    simp only [congr_arg] at triv₁,
    rw [fderiv_const_smul (continuous_linear_equiv.differentiable_at _), smul_apply, 
        smul_apply, continuous_linear_equiv.fderiv, to_dual.coe_coe, to_dual_apply, 
        triv₁, smul_eq_mul, real_inner_comm, hc x hx]
  end,
  have triv₁ := λ y (hy : y ∈ s), 
    (D23 zero_lt_two $ conformal_factor_sqrt_inv_times_cont_diff_at _ Hf
    $ (D22 $ hf's y hy).congr_of_eventually_eq (eventually_eq_iff_exists_mem.mpr 
    ⟨s, hs.mem_nhds hy, λ a ha, Hevens a ha⟩).symm).differentiable_within_at,
  rcases hs.exists_of_fderiv_eq_fderiv hs' triv₁ 
    (λ y hy, (continuous_linear_equiv.differentiable_within_at _).const_smul _) key₁ with ⟨map, h⟩,
  simp only [congr_arg] at h,
  have Hc : c ≠ 0 :=
  λ W, begin
    rcases hs'.nonempty with ⟨x', hx'⟩,
    simp only [W] at hc,
    have := hnonzero x' hx',
    rw hc x' hx' at this,
    exact this rfl
  end,
  let x₀ := to_dual.symm (c⁻¹ • map),
  have triv₃ : c • to_dual x₀ = map := 
    by simp only [x₀, to_dual.apply_symm_apply, smul_inv_smul' Hc],
  simp only [← triv₃, ← smul_sub, ← to_dual.map_sub] at h,
  have key₂ : ∀ x ∈ s,
    fderiv ℝ (λ y, conformal_factor_sqrt_inv $ Hf y) x = 
    fderiv ℝ (λ y, c / 2 * ⟪id y - x₀, id y⟫ - (c / 2) * to_dual x₀ (y - x₀)) x :=
  λ x hx, begin
    ext1 v,
    rw [h x hx, fderiv_sub (((differentiable_at_id.sub_const x₀).inner 
        differentiable_at_id).const_mul _)]; 
        [skip, exact ((continuous_linear_map.differentiable_at _).comp _ 
        $ differentiable_at_id.sub_const _).const_mul (c / 2)],
    rw [fderiv_const_mul ((differentiable_at_id.sub_const x₀).inner differentiable_at_id)],
    rw [smul_apply, sub_apply, smul_apply, 
        fderiv_inner_apply (differentiable_at_id.sub_const x₀) differentiable_at_id],
    rw [fderiv_sub_const],
    simp only [fderiv_id], 
    simp only [id_apply, _root_.id],
    rw [fderiv_const_mul]; [skip, exact ((continuous_linear_map.differentiable_at _).comp _ 
        $ differentiable_at_id.sub_const _)],
    rw [fderiv.comp]; [skip, exact continuous_linear_map.differentiable_at _,
        exact differentiable_at_id.sub_const _],
    simp only [continuous_linear_map.fderiv, fderiv_sub_const, smul_apply, coe_comp',
        function.comp_app, to_dual_apply, fderiv_id', id_apply, smul_add],
    nth_rewrite 2 real_inner_comm,
    simp only [inner_sub_left, smul_sub, smul_eq_mul],
    ring
  end,
  have triv₄ := λ y hy, ((conformal_factor_sqrt_inv_times_cont_diff_at _ Hf
    $ (D22 $ hf's y hy).congr_of_eventually_eq (eventually_eq_iff_exists_mem.mpr 
    ⟨s, hs.mem_nhds hy, λ a ha, Hevens a ha⟩).symm).differentiable_at
    $ by apply with_top.coe_le_coe.mpr; norm_num).differentiable_within_at,
  rcases hs.exists_of_fderiv_eq_fderiv hs' triv₄ _ key₂ with ⟨β, H⟩,
  simp only [congr_arg, _root_.id] at H,
  refine ⟨c / 2, -β, div_ne_zero Hc two_ne_zero, x₀, λ x hx, _⟩,
  convert H x hx,
  simp only [smul_eq_mul, to_dual_apply],
  rw [real_inner_comm, ← mul_sub, ← inner_sub_left, real_inner_self_eq_norm_sq, pow_two],
  intros y hy,
  refine ((((differentiable_at_id.sub_const x₀).inner
    differentiable_at_id).const_mul _).sub _).differentiable_within_at,
  exact ((continuous_linear_map.differentiable_at _).comp _ 
    $ differentiable_at_id.sub_const _).const_mul (c / 2)  
end

lemma conformal_factor_sqrt_inv_eq_inner_add_const
  (hzero : ∃ x ∈ s, bilin_form_factor H₁ H₂ x = 0) :
  ∃ (β : ℝ) (x₀ : E), 
  ∀ x ∈ s, conformal_factor_sqrt_inv (Hf x) = ⟪x, x₀⟫ + β :=
begin
  rcases is_const_bilin_form_factor hs hfs hf's hsurj Hf Hevens hrank3 hs' with ⟨c, hc⟩,
  have key₁ : ∀ x ∈ s, 
    fderiv ℝ (fderiv ℝ $ λ y, conformal_factor_sqrt_inv $ Hf y) x =
    fderiv ℝ (λ y, c • to_dual y) x :=
  λ x hx, begin
    ext v u,
    have triv₁ := (fderiv_fderiv_eq_bilin_form_factor_mul hs hfs hf's hsurj Hf 
      Hevens hrank3 hx u v).self_of_nhds,
    simp only [congr_arg] at triv₁,
    rw [fderiv_const_smul (continuous_linear_equiv.differentiable_at _), smul_apply, 
        smul_apply, continuous_linear_equiv.fderiv, to_dual.coe_coe, to_dual_apply, 
        triv₁, smul_eq_mul, real_inner_comm, hc x hx]
  end,
  have triv₁ := λ y (hy : y ∈ s), 
    (D23 zero_lt_two $ conformal_factor_sqrt_inv_times_cont_diff_at _ Hf
    $ (D22 $ hf's y hy).congr_of_eventually_eq (eventually_eq_iff_exists_mem.mpr 
    ⟨s, hs.mem_nhds hy, λ a ha, Hevens a ha⟩).symm).differentiable_within_at,
  rcases hs.exists_of_fderiv_eq_fderiv hs' triv₁ 
    (λ y hy, (continuous_linear_equiv.differentiable_within_at _).const_smul _) key₁ with ⟨map, h⟩,
  simp only [congr_arg] at h,
  have Hc : c = 0 :=
  begin
    rcases hzero with ⟨x'', hx'', Hx''⟩,
    rwa hc x'' hx'' at Hx'',
  end,
  simp only [Hc, zero_smul, zero_sub] at h,
  have key₂ : ∀ x ∈ s,
    fderiv ℝ (λ y, conformal_factor_sqrt_inv $ Hf y) x =
    fderiv ℝ (-map : E →L[ℝ] ℝ) x :=
  λ x hx, by ext1 v; rw [h x hx, (-map).fderiv],
  have triv₄ := λ y hy, ((conformal_factor_sqrt_inv_times_cont_diff_at _ Hf
    $ (D22 $ hf's y hy).congr_of_eventually_eq (eventually_eq_iff_exists_mem.mpr 
    ⟨s, hs.mem_nhds hy, λ a ha, Hevens a ha⟩).symm).differentiable_at
    $ by apply with_top.coe_le_coe.mpr; norm_num).differentiable_within_at,
  rcases hs.exists_of_fderiv_eq_fderiv hs' triv₄ (continuous_linear_map.differentiable_on _) 
    key₂ with ⟨β, H⟩,
  refine ⟨-β, to_dual.symm (-map), λ x hx, _⟩,
  rw [real_inner_comm, ← to_dual_apply, to_dual.apply_symm_apply],
  exact H x hx
end

end integrate

section conformality_of_local_inverse

variables {E : Type*} [inner_product_space ℝ E] [complete_space E] [nontrivial E] 
  -- {f' : E → (E →L[ℝ] F)} (Hf : ∀ (x' : E), is_conformal_map $ f' x')
  -- (Hevens : ∀ x ∈ s, fderiv ℝ f x = f' x)

-- def def_helper (f : E → E) (s : set E) (x : E) :=
-- if x ∈ s then fderiv ℝ f x else id ℝ E

-- lemma def_helper_eq (f : local_homeomorph E E) (s : set E) {x : E} (hx : x ∈ s) :
--   fderiv ℝ f x = def_helper f s x :=
-- by simp only [def_helper, if_pos hx]

variables {f : local_homeomorph E E} {s : set E} (hs : is_open s) 
  (hs' : is_connected s) (hs'' : s ⊆ f.source) (hfs : ∀ x ∈ s, conformal_at f x) 
  (hf's : ∀ x ∈ s, times_cont_diff_at ℝ 4 f x) 
  (hsurj : ∀ x ∈ s , function.surjective (fderiv ℝ f x))

-- lemma def_helper_is_conformal_map {x : E} :
--   is_conformal_map (def_helper f s x) :=
-- begin
--   simp only [def_helper],
--   by_cases h : x ∈ s,
--   { rw if_pos h,
--     exact (conformal_at_iff_is_conformal_map_fderiv.mp $ hfs x h) },
--   { rw if_neg h,
--     exact is_conformal_map_id }
-- end

include hfs hsurj

def bijective_differentials {x : E} (hx : x ∈ s) : E ≃L[ℝ] E :=
continuous_linear_equiv.of_bijective (fderiv ℝ f x) 
(linear_map.ker_eq_bot.mpr (conformal_at_iff_is_conformal_map_fderiv.mp $ hfs x hx).injective)
(linear_map.range_eq_top.mpr $ hsurj x hx)

lemma bijective_differentials1 {x : E} (hx : x ∈ s) :
  (bijective_differentials hfs hsurj hx : E →L[ℝ] E) = fderiv ℝ f x :=
by simp only [bijective_differentials, continuous_linear_equiv.coe_of_bijective]

lemma bijective_differentials2 {x : E} (hx : x ∈ s) :
  has_fderiv_at f (bijective_differentials hfs hsurj hx : E →L[ℝ] E) x :=
begin
  rw bijective_differentials1 hfs hsurj hx,
  exact (hfs x hx).differentiable_at.has_fderiv_at
end

end conformality_of_local_inverse

-- h = u
-- k = v
-- l = w