import analysis.complex.isometry
import analysis.complex.real_deriv

section fderiv

open continuous_linear_map

variables (π : Type*) [nondiscrete_normed_field π]
variables {π' : Type*} [nondiscrete_normed_field π'] [normed_algebra π π']
variables {E : Type*} [normed_group E] [normed_space π E] [normed_space π' E]
variables [is_scalar_tower π π' E]
variables {F : Type*} [normed_group F] [normed_space π F] [normed_space π' F]
variables [is_scalar_tower π π' F]
variables {f : E β F} {f' : E βL[π'] F} {s : set E} {x : E}

lemma has_fderiv_within_at_of_eq {s : set E} {g' : E βL[π] F} (h : has_fderiv_within_at f g' s x)
  (H : f'.restrict_scalars π = g') : has_fderiv_within_at f f' s x :=
by { simp only [has_fderiv_within_at, has_fderiv_at_filter] at h β’,
     rwa [β f'.coe_restrict_scalars', H] }

lemma has_fderiv_at_of_eq {g' : E βL[π] F} (h : has_fderiv_at f g' x)
  (H : f'.restrict_scalars π = g') : has_fderiv_at f f' x :=
by simp only [has_fderiv_at, has_fderiv_at_filter] at h β’; rwa [β f'.coe_restrict_scalars', H]

lemma fderiv_eq_fderiv (h : differentiable_at π' f x) :
  (fderiv π f x : E β F) = fderiv π' f x :=
by rw [(h.restrict_scalars π).has_fderiv_at.unique (h.has_fderiv_at.restrict_scalars π),
       coe_restrict_scalars']

lemma differentiable_within_at_iff_exists_linear_map {s : set E}
  (hf : differentiable_within_at π f s x) (hs : unique_diff_within_at π s x) :
  differentiable_within_at π' f s x β
  β (g' : E βL[π'] F), g'.restrict_scalars π = fderiv_within π f s x :=
begin
  split,
  { rintros β¨g', hg'β©,
    exact β¨g', hs.eq (hg'.restrict_scalars π) hf.has_fderiv_within_atβ©, },
  { rintros β¨f', hf'β©,
    exact β¨f', has_fderiv_within_at_of_eq π hf.has_fderiv_within_at hf'β©, },
end

lemma differentiable_at_iff_exists_linear_map (hf : differentiable_at π f x) :
  differentiable_at π' f x β β (g' : E βL[π'] F), g'.restrict_scalars π = fderiv π f x :=
by { rw [β differentiable_within_at_univ, β fderiv_within_univ],
     exact differentiable_within_at_iff_exists_linear_map π
     hf.differentiable_within_at unique_diff_within_at_univ, }

end fderiv

section complex_real_deriv
/-! ### Antiholomorphy of complex functions -/
open complex continuous_linear_map

variables {E : Type*} [normed_group E] [normed_space β E]
  {z : β} {f : β β E}

lemma has_fderiv_at_conj (z : β) : has_fderiv_at conj conj_cle.to_continuous_linear_map z :=
conj_cle.has_fderiv_at

lemma fderiv_conj_eq_conj_fderiv {z : β} (h : differentiable_at β f z) :
  (fderiv β f z).comp conj_cle.to_continuous_linear_map = fderiv β (f β conj) (conj z) :=
begin
  rw β conj_conj z at h,
  let p := fderiv.comp (conj z) h (has_fderiv_at_conj $ conj z).differentiable_at,
  rw [conj_conj, (has_fderiv_at_conj $ conj z).fderiv] at p,
  exact p.symm,
end

/-- A (real-differentiable) complex function `f` is antiholomorphic if and only if there exists some
    complex linear map `g'` that equals to the composition of `f`'s differential and the conjugate
    function -/
lemma antiholomorph_at_iff_exists_complex_linear_conj
  [normed_space β E] [is_scalar_tower β β E]
  (hf : differentiable_at β f z) : differentiable_at β (f β conj) (conj z) β
  β (g' : β βL[β] E), g'.restrict_scalars β =
  (fderiv β f z).comp conj_cle.to_continuous_linear_map :=
begin
  split,
  { intros h,
    rw β conj_conj z at hf,
    rcases (differentiable_at_iff_exists_linear_map β $
      hf.comp (conj z) (has_fderiv_at_conj $ conj z).differentiable_at).mp h with β¨f', hf'β©,
    rw conj_conj at hf,
    rw β fderiv_conj_eq_conj_fderiv hf at hf',
    exact β¨f', hf'β©, },
  { rintros β¨g', hg'β©,
    rw β conj_conj z at hf hg',
    exact β¨g', has_fderiv_at_of_eq β
      (hf.has_fderiv_at.comp (conj z) $ has_fderiv_at_conj $ conj z) hg'β©, },
end

end complex_real_deriv