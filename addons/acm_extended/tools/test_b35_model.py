"""B35 long-duration calibration scenarios plus SQF source contracts.

The mathematical oracle evaluates the documented normalized game equations; it
is not an SQF interpreter or an Arma runtime test. Scenarios assert the requested
clinical-gameplay outcomes over hours, including retained residual findings and
real causes of recurrence. Source contracts bind its coefficients/branches to
the pure SQF step so that algorithm edits cannot silently leave a stale oracle.
"""
from dataclasses import dataclass, replace
from pathlib import Path
import math
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


def source(name):
    return (ROOT / 'functions' / f'fn_{name}.sqf').read_text(encoding='utf-8')


@dataclass
class State:
    air: float = 1.0
    leak: float = .2
    stable: float = 0.0
    pressure: float = 0.0
    residual: float = 1.0
    tension: bool = False


@dataclass(frozen=True)
class Context:
    openings: int = 0
    outflow: float = 0.0
    blood: float = 0.0
    ppv: float = 1.0


def advance(state, context=Context(), dt=1, base=600, heal=600, stable=60):
    s = replace(state)
    dt = min(5, max(0, dt))
    if dt <= 0:
        return s
    base, heal = max(60, base), max(60, heal)
    stable = min(86400, max(0, stable))
    end_leak = max(0, s.leak - dt / (heal * (1 + .5 * min(1, max(0, context.blood)))))
    inflow = (s.leak + end_leak) * .5 * min(3, max(1, context.ppv)) + min(1.4, .35 * max(0, context.openings))
    net = inflow - max(0, context.outflow)
    previous_air = s.air
    if net > 0:
        s.air = min(32, s.air + 4 * net * dt / base)
        if s.air > 2:
            s.pressure = min(1, s.pressure + net * (s.air - 1) * dt / base)
        s.stable = 0
    else:
        s.air = max(s.residual, s.air + 4 * net * dt / 60)
        if not s.tension:
            s.pressure = max(0, s.pressure - dt / 60)
        elif net < -.000001:
            s.pressure = max(0, s.pressure - (-net) * dt / 15)
            if s.pressure <= .1 and s.air < 3:
                s.tension = False
        s.stable = min(stable, s.stable + dt) if not s.tension and s.air <= previous_air + .000001 else 0
    if s.pressure >= 1 and net > 0:
        s.tension = True
        s.stable = 0
    s.air, s.leak, s.pressure = min(32, max(0, s.air)), end_leak, min(1, max(0, s.pressure))
    return s


def run(state, context=Context(), seconds=14400, dt=1, **kwargs):
    ever_tension = state.tension
    maximum_air = state.air
    for _ in range(round(seconds / dt)):
        state = advance(state, context, dt, **kwargs)
        ever_tension |= state.tension
        maximum_air = max(maximum_air, state.air)
    return state, ever_tension, maximum_air


def ambient(state, factor, context=Context()):
    s = replace(state)
    factor = min(5, max(.2, factor))
    if abs(factor - 1) < .0000001 or s.air <= 0:
        return s
    inflow = s.leak * context.ppv + min(1.4, .35 * context.openings)
    if context.outflow > inflow + .05:
        return s
    old_air = s.air
    s.air = min(32, max(0, s.air * factor))
    s.residual = min(s.air, s.residual * factor)
    if factor > 1:
        s.stable = 0
        s.pressure = min(1, s.pressure + max(0, s.air - old_air) * .5)
        if old_air * factor > 4:
            s.pressure, s.tension = 1, True
    else:
        s.pressure = max(0, s.pressure - (old_air - s.air) * .5)
        if s.pressure <= .1 and s.air < 3:
            s.tension = False
    return s


class SustainedStability(unittest.TestCase):
    def test_uninjured_surface_wounds_cannot_seed_a_ptx_from_maintenance(self):
        tick = source('ptxTensionTick')
        self.assertIn('(_s select 6)==0', tick)
        self.assertIn('(_s select 1)<=0', tick)
        self.assertIn('(_s select 2)<=0', tick)
        self.assertLess(tick.index('(_s select 6)==0'), tick.index('call ACME_fnc_ptxStep'))

    def test_small_closed_leak_settles_for_four_hours_with_residual_impairment(self):
        end, tension, maximum = run(State())
        self.assertFalse(tension)
        self.assertEqual(end.leak, 0)
        self.assertEqual(end.stable, 60)
        self.assertGreaterEqual(end.air, 1)
        self.assertLess(maximum, 1.1)
        self.assertEqual(end.pressure, 0)

    def test_after_settling_another_eight_hours_do_not_increase_collapse(self):
        settled, _, _ = run(State(), seconds=1800)
        later, tension, _ = run(settled, seconds=28800)
        self.assertFalse(tension)
        self.assertEqual(settled, later)

    def test_complete_dry_vented_coverage_handles_a_sustained_leak(self):
        # Outflow 1.5 is complete vented coverage. High healing time keeps the
        # leak active throughout much of the trial, testing balance not healing.
        for leak in (.2, .6, 1):
            end, tension, maximum = run(State(air=2, leak=leak, residual=1), Context(outflow=1.5), heal=86400)
            self.assertFalse(tension)
            self.assertLessEqual(maximum, 2)
            self.assertEqual(end.air, 1)
            self.assertEqual(end.stable, 60)
            self.assertGreater(end.leak, 0)

    def test_adequate_ncd_drainage_keeps_successful_relief_durable(self):
        # Successful decompression leaves <=1 air and <=.5 residual collapse;
        # retained NCD patency supplies 1.4 normalized outflow indefinitely.
        for ppv in (1, 1.5, 3):
            end, tension, maximum = run(State(air=1, leak=.3, residual=.5), Context(outflow=1.4, ppv=ppv))
            self.assertFalse(tension)
            self.assertLessEqual(maximum, 1)
            self.assertEqual(end.air, .5)
            self.assertEqual(end.stable, 60)

    def test_patent_thoracostomy_controls_even_worst_bounded_inflow(self):
        end, tension, _ = run(State(air=4, leak=1, pressure=1, tension=True), Context(openings=6, outflow=5, ppv=3), seconds=300)
        self.assertFalse(end.tension)
        self.assertEqual(end.air, end.residual)
        self.assertEqual(end.pressure, 0)
        self.assertEqual(end.stable, 60)

    def test_missed_exit_remains_a_real_cause_of_progression(self):
        # One untreated communication: ingress .35, natural outlet .1 plus
        # only .15 from the incomplete seal arrangement.
        end, tension, _ = run(State(), Context(openings=1, outflow=.25), seconds=7200)
        self.assertTrue(tension)
        self.assertTrue(end.tension)
        self.assertGreaterEqual(end.air, 4)

    def test_untreated_severe_injury_can_reach_tension(self):
        end, tension, _ = run(State(air=3, leak=1), Context(openings=1, outflow=.1), seconds=1800)
        self.assertTrue(tension)
        self.assertTrue(end.tension)
        self.assertEqual(end.pressure, 1)

    def test_blocked_seal_cannot_manufacture_air_after_leak_stops(self):
        original = State(air=1.7, leak=0, stable=60, residual=1)
        for ppv in (1, 3):
            end, tension, maximum = run(original, Context(outflow=0, ppv=ppv))
            self.assertFalse(tension)
            self.assertEqual(end.air, original.air)
            self.assertEqual(maximum, original.air)
            self.assertEqual(end.pressure, 0)

    def test_both_low_and_high_ppv_allow_small_closed_injury_to_settle(self):
        outcomes = []
        for ppv in (1, 1.5, 3):
            end, tension, maximum = run(State(), Context(ppv=ppv))
            self.assertFalse(tension)
            self.assertLess(maximum, 1.3)
            self.assertEqual(end.stable, 60)
            outcomes.append(end.air)
        self.assertLess(outcomes[0], outcomes[-1])

    def test_high_ppv_can_overwhelm_a_small_outlet_when_a_large_leak_exists(self):
        start = State(air=3, leak=1, residual=.5)
        low, low_tension, _ = run(start, Context(outflow=1.4, ppv=1), heal=3600, seconds=1800)
        high, high_tension, _ = run(start, Context(outflow=1.4, ppv=3), heal=3600, seconds=600)
        self.assertFalse(low_tension)
        self.assertEqual(low.air, .5)
        self.assertTrue(high_tension)
        self.assertTrue(high.tension)

    def test_loss_of_drainage_matters_only_if_a_source_remains(self):
        sealed = State(air=1, leak=0, residual=.5, stable=60)
        end, tension, _ = run(sealed, Context(outflow=0))
        self.assertFalse(tension)
        self.assertEqual(end.air, 1)
        renewed = replace(sealed, air=3, leak=1, stable=0)
        injured, tension, _ = run(renewed, Context(openings=1, outflow=.1), seconds=1800)
        self.assertTrue(tension)
        self.assertTrue(injured.tension)

    def test_stability_is_not_immunity_to_a_new_chest_injury(self):
        original, _, _ = run(State())
        injured = replace(original, air=min(32, original.air + 3), leak=.75, stable=0)
        end, tension, _ = run(injured, Context(openings=2, outflow=.2), seconds=1800)
        self.assertTrue(tension)
        self.assertTrue(end.tension)
        self.assertEqual(end.stable, 0)

    def test_established_tension_never_quietly_clears_on_a_timer(self):
        original = State(air=4, leak=0, pressure=1, tension=True)
        end, tension, _ = run(original, Context())
        self.assertEqual(end, original)
        self.assertTrue(tension)
        self.assertEqual(end.stable, 0)

    def test_active_venting_can_resolve_established_tension(self):
        start = State(air=4, leak=0, pressure=1, residual=1, tension=True)
        end, _, _ = run(start, Context(outflow=1.4), seconds=120)
        self.assertFalse(end.tension)
        self.assertEqual(end.air, 1)
        self.assertEqual(end.stable, 60)

    def test_non_tension_pressure_debt_drains_after_accumulation_stops(self):
        start = State(air=2.5, leak=0, pressure=.9)
        end, tension, _ = run(start, seconds=60)
        self.assertFalse(tension)
        self.assertEqual(end.pressure, 0)
        self.assertEqual(end.stable, 60)
        self.assertEqual(end.air, 2.5)

    def test_blood_slows_leak_settling_without_creating_a_new_air_source(self):
        clean, _, _ = run(State(), Context(blood=0))
        bleeding, tension, _ = run(State(), Context(blood=1))
        self.assertFalse(tension)
        self.assertGreater(bleeding.air, clean.air)
        self.assertEqual(bleeding.leak, 0)
        no_leak, tension, _ = run(State(leak=0), Context(blood=1))
        self.assertFalse(tension)
        self.assertEqual(no_leak.air, 1)

    def test_stability_interval_changes_classification_without_healing_the_lung(self):
        for interval in (0, 30, 60, 120):
            end, tension, _ = run(State(leak=0), seconds=300, stable=interval)
            self.assertFalse(tension)
            self.assertEqual(end.stable, interval)
            self.assertEqual(end.air, 1)

    def test_supported_scheduler_steps_reach_the_same_settled_result(self):
        ends = [run(State(), seconds=1800, dt=dt)[0] for dt in (.25, 1, 5)]
        for end in ends:
            self.assertFalse(end.tension)
            self.assertEqual(end.stable, 60)
            self.assertEqual(end.leak, 0)
            self.assertAlmostEqual(end.air, ends[0].air, places=6)

    def test_scheduler_pause_cannot_fast_forward_a_patient_into_tension(self):
        start = State(air=2, leak=.5)
        self.assertEqual(advance(start, Context(openings=2), dt=900), advance(start, Context(openings=2), dt=5))
        self.assertEqual(advance(start, dt=-1), start)


class AmbientModelStability(unittest.TestCase):
    def test_saturated_native_grade_does_not_destroy_trapped_gas(self):
        original = State(air=3, leak=0, residual=1)
        climbed = ambient(original, 2)
        self.assertEqual(climbed.air, 6)
        self.assertEqual(min(4, climbed.air), 4)
        self.assertTrue(climbed.tension)
        returned = ambient(climbed, .5)
        self.assertEqual(returned.air, original.air)
        self.assertEqual(returned.residual, original.residual)
        self.assertEqual(returned.leak, 0)

    def test_fixed_altitude_does_not_generate_more_air_or_pressure(self):
        climbed = ambient(State(air=1.5, leak=0), 1.3)
        original = replace(climbed)
        for _ in range(14400):
            climbed = ambient(climbed, 1)
        self.assertEqual(climbed, original)

    def test_repeated_unsaturated_climbs_return_the_same_gas_and_pressure(self):
        original = State(air=1.2, leak=0, residual=.5)
        current = replace(original)
        for _ in range(100):
            current = ambient(ambient(current, 1.5), 1 / 1.5)
        self.assertAlmostEqual(current.air, original.air, places=12)
        self.assertAlmostEqual(current.residual, original.residual, places=12)
        self.assertAlmostEqual(current.pressure, original.pressure, places=12)
        self.assertFalse(current.tension)

    def test_maximum_supported_altitude_change_stays_reversible(self):
        original = State(air=4, leak=0)
        climbed = ambient(original, 5)
        self.assertEqual(climbed.air, 20)
        self.assertLessEqual(climbed.air, 32)
        returned = ambient(climbed, .2)
        self.assertEqual(returned.air, original.air)
        self.assertEqual(returned.residual, original.residual)

    def test_subdivision_does_not_lose_air_above_native_grade_four(self):
        original = State(air=3, leak=0)
        direct = ambient(original, 5)
        staged = ambient(ambient(original, 2), 2.5)
        self.assertEqual(direct.air, staged.air)
        self.assertEqual(direct.residual, staged.residual)

    def test_adequate_venting_equalizes_without_a_new_leak(self):
        original = State(air=1, leak=.2, residual=.5)
        changed = ambient(original, 2, Context(outflow=1.4))
        self.assertEqual(changed, original)
        healthy = State(air=0, leak=0, residual=0)
        self.assertEqual(ambient(healthy, 5), healthy)

    def test_internal_cap_remains_finite_under_extreme_repeated_changes(self):
        current = State(air=4, leak=0)
        for _ in range(100):
            current = ambient(current, 5)
        self.assertEqual(current.air, 32)
        self.assertTrue(math.isfinite(current.air))
        self.assertLessEqual(current.residual, current.air)


class ModelSourceContracts(unittest.TestCase):
    def test_internal_air_and_native_projection_have_distinct_bounds(self):
        s = source('ptxPublish')
        self.assertIn('_state set [1,(_state select 1) max 0 min 32]', s)
        self.assertIn('else {(_state select 1) min 4}', s)
        self.assertIn('_state set [7,_native]', s)
        ambient_source = source('ptxAmbientChange')
        self.assertIn('_factor=_factor max 0.2 min 5;', ambient_source)
        self.assertIn('(_air*_factor) max 0 min 32', ambient_source)
        self.assertIn('((_s select 8)*_factor) min _new', ambient_source)
        self.assertIn('if ((_c select 2)>_in+0.05) exitWith', ambient_source)
        self.assertNotIn('call ACME_fnc_ptxInjury', ambient_source)

    def test_step_is_pure_and_contains_no_provider_disclosures(self):
        s = source('ptxStep')
        code = re.sub(r'/\*.*?\*/|//[^\n]*', '', s, flags=re.S)
        for token in ('getVariable', 'setVariable', 'random', 'CBA_missionTime', 'uiNamespace', 'hint', 'systemChat', 'diag_log', 'addPerFrameHandler'):
            self.assertNotIn(token, code)
        self.assertIn('_state=+_state;', code)

    def test_oracle_coefficients_and_tension_release_branches_match_live_step(self):
        s = re.sub(r'\s+', '', source('ptxStep'))
        for expression in (
            '_dt=_dtmax0min5;',
            '_healSec=_healSecmax60;',
            '_endLeak=(_leak-(_dt/(_healSec*(1+0.5*(_bloodmax0min1)))))max0;',
            '_meanLeak=(_leak+_endLeak)*0.5;',
            '_in=_meanLeak*_ppv+((0.35*(_openmax0))min1.4);',
            '_air=(_air+4*_net*_dt/_baseSec)min32;',
            '_air=(_air+4*_net*_dt/60)max_residual;',
            '_pressure=(_pressure+_net*(_air-1)*_dt/_baseSec)min1;',
            'if(_net<-0.000001)then',
            'if(_pressure<=0.1&&{_air<3})then{_tension=false;};',
            'if(_pressure>=1&&{_net>0})then{_tension=true;_stable=0;};',
        ):
            self.assertIn(expression, s)

    def test_one_owner_controller_uses_real_elapsed_time_and_pure_model(self):
        s = source('ptxTensionTick')
        self.assertIn('!local _patient', s)
        self.assertIn('!alive _patient', s)
        self.assertEqual(s.count('call ACME_fnc_ptxStep'), 1)
        self.assertIn('call ACME_fnc_clinicalTickDelta', s)
        self.assertIn('call ACME_fnc_ptxContext', s)
        self.assertIn('call ACME_fnc_ptxPublish', s)
        self.assertNotIn('random', s)
        self.assertNotIn('addPerFrameHandler', s)

    def test_stable_and_leak_state_never_appear_in_ui_or_provider_logs(self):
        for name in ('ptxStep', 'ptxEnsure', 'ptxPublish', 'ptxInjury', 'ptxTreat', 'ptxAmbientChange', 'ptxContext', 'ptxTensionTick'):
            s = source(name)
            self.assertNotRegex(s, r'\b(?:hint|hintSilent|systemChat|cutText|diag_log|displayTextStructured|addToLog)\b', name)

    def test_stopped_leak_and_existing_tension_have_separate_paths(self):
        s = source('ptxStep')
        self.assertIn('if (!_tension) then {_pressure=(_pressure-_dt/60) max 0;} else', s)
        self.assertIn('if (_net < -0.000001) then', s)
        self.assertIn('if (!_tension && {_air<=_oldAir+0.000001})', s)


if __name__ == '__main__':
    unittest.main()
