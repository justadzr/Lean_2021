import analysis.complex.isometry
import analysis.complex.real_deriv
import analysis.calculus.conformal

noncomputable theory

open complex linear_isometry linear_isometry_equiv continuous_linear_map
     finite_dimensional linear_map

section A
  
variables (π : Type*) [nondiscrete_normed_field π]
variables {π' : Type*} [nondiscrete_normed_field π'] [normed_algebra π π']
variables {E : Type*} [normed_group E] [normed_space π E] [normed_space π' E]
variables [is_scalar_tower π π' E]
variables {F : Type*} [normed_group F] [normed_space π F] [normed_space π' F]
variables [is_scalar_tower π π' F]
variables {f : E β F} {f' : E βL[π'] F} {s : set E} {x : E}

lemma differentiable_at_iff_exists_linear_map (hf : differentiable_at π f x) :
  differentiable_at π' f x β β (g' : E βL[π'] F), g'.restrict_scalars π = fderiv π f x :=
sorry

end A

section B

variables {E : Type*} [normed_group E] [normed_space β E] [normed_space β E]
  [is_scalar_tower β β E] {z : β} {g : β βL[β] E} {f : β β E}

lemma is_conformal_map_of_complex_linear
  {map : β βL[β] E} (nonzero : map β  0) : is_conformal_map (map.restrict_scalars β) :=
sorry


lemma conformal_at_of_holomorph_or_antiholomorph_at_aux
  (hf : differentiable_at β f z) (hf' : fderiv β f z β  0)
  (h : differentiable_at β f z β¨ differentiable_at β (f β conj) (conj z)) :
  conformal_at f z :=
begin
  rw [conformal_at_iff_is_conformal_map_fderiv],
  cases h with hβ hβ,
  { rw [differentiable_at_iff_exists_linear_map β hf] at hβ;
       [skip, apply_instance, apply_instance, apply_instance],
    rcases hβ with β¨map, hmapβ©,
    have minorβ : fderiv β f z = map.restrict_scalars β := hmap.symm,
    rw minorβ,
    refine is_conformal_map_of_complex_linear _,},
end

end B