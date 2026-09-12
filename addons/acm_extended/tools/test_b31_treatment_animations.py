"""B31 source/geometry contracts. These do not execute Arma's animation graph."""
from pathlib import Path
import math
import re
import unittest
from test_b29_narc_plunger import expression

ROOT = Path(__file__).resolve().parents[1]
START = (ROOT / 'functions/fn_treatmentPoseStart.sqf').read_text()
STOP = (ROOT / 'functions/fn_treatmentPoseStop.sqf').read_text()
SYNC = (ROOT / 'functions/fn_treatmentPoseSync.sqf').read_text()
CONTINUOUS = (ROOT / 'functions/fn_beginStethoscopeAction.sqf').read_text()
CONFIG = (ROOT / 'config.cpp').read_text()
PHASE = expression(re.search(r'private _phase = ([^;]+);', START)[1])


def class_block(name):
    match = re.search(r'\bclass ' + re.escape(name) + r'(?:\s*:\s*\w+)?\s*\{', CONFIG)
    start = match.end()
    depth = 1
    for index in range(start, len(CONFIG)):
        depth += (CONFIG[index] == '{') - (CONFIG[index] == '}')
        if not depth:
            return CONFIG[start:index]
    raise AssertionError('Unclosed class: ' + name)


class TreatmentAnimationContracts(unittest.TestCase):
    def test_source_time_is_exact_after_frame_overshoot(self):
        # Evaluate the actual SQF phase expression across source durations and frame
        # rates. A delay-only freeze would stop at the overshot frame instead.
        for duration in (0.8, 1.116, 3, 7.23, 12, 19.7):
            for fps in (13, 24, 30, 60, 144):
                sampled_time = math.ceil(.421 * fps) / fps
                self.assertGreaterEqual(sampled_time, .421)
                phase = PHASE({'_duration': duration})
                self.assertAlmostEqual(phase * duration, .421, places=12)
        self.assertIn('_medic getUnitMovesInfo 2', START)
        self.assertIn('_moveTime >= 0.421', START)
        self.assertIn('switchMove [_main, _phase, 1, false]', SYNC)
        self.assertLess(SYNC.index('setAnimSpeedCoef 0'), SYNC.index('switchMove [_main'))

    def test_native_motions_have_work_loops_and_real_crouch_exits(self):
        for child, native in (
            ('ACME_ChestInspectWork', 'AinvPknlMstpSnonWrflDr_medic4'),
            ('ACME_JunctionalWork', 'AinvPknlMstpSnonWnonDnon_medic4'),
            ('ACME_StethoscopeWork', 'UnconsciousReviveMedic_B'),
        ):
            self.assertIn('class ' + child + ': ' + native, CONFIG)
            block = class_block(child)
            self.assertIn('looped = 1;', block)
            self.assertRegex(block, r'interpolateFrom\[\].*AmovPknlMstpSnonWnonDnon')
            self.assertRegex(block, r'interpolateTo\[\].*AmovPknlMstpSnonWnonDnon.*Unconscious')

    def test_ace_has_no_competing_pose_for_owned_progress_actions(self):
        for action in ('ACME_InspectChest', 'ACME_PackJunctional', 'ACME_WrapJunctional'):
            block = class_block(action)
            for field in ('animationMedic', 'animationMedicProne', 'animationMedicSelf', 'animationMedicSelfProne'):
                self.assertIn(field + ' = "";', block)
        for action, stem in (('ACME_PackJunctional', 'Pack'), ('ACME_WrapJunctional', 'Wrap')):
            block = class_block(action)
            self.assertIn('ACME_fnc_junctional' + stem + 'SfxStart', block)
            self.assertIn('ACME_fnc_junctional' + stem + 'Done', block)
            self.assertEqual(block.count('ACME_fnc_treatmentPoseStop'), 2)

    def test_cancel_between_work_request_and_entry_cancels_pending_move(self):
        # Regress stage1: being in crouch does not mean no work is queued.
        self.assertIn('private _ownsEntry = _stage <= 1', STOP)
        self.assertIn('amovpknlmstpsnonwnondnon', STOP)
        self.assertIn('_current == toLower _main || {_ownsEntry}', STOP)
        self.assertIn('["_medic",', START)
        self.assertIn('[_medic, "AmovPknlMstpSnonWnonDnon", 1]', STOP)
        self.assertNotIn('call ACME_fnc_animQueue', START + STOP)

    def test_jip_waits_for_atomic_episode_and_retires_unique_hold(self):
        self.assertIn('["ACME_treatmentPoseEpisode", [_epoch, true], true]', START)
        self.assertIn('CBA_fnc_waitUntilAndExecute', SYNC)
        self.assertLess(SYNC.index('CBA_fnc_waitUntilAndExecute'), SYNC.index('["ACME_treatmentPoseRemote", [_epoch, "release"'))
        self.assertIn('local _medic &&', STOP)
        self.assertIn('isEqualTo [_currentEpoch, true]', STOP)
        self.assertIn('[_jip, _medic] call CBA_fnc_removeGlobalEventJIP', START)
        self.assertIn('CBA_fnc_removeGlobalEventJIP', STOP)
        self.assertIn('(_record select 0) > _epoch', SYNC)
        self.assertIn('(_record select 1) == "release"', SYNC)

    def test_fatigue_and_deleted_provider_cleanup_are_episode_scoped(self):
        self.assertIn('pushBackUnique _exclusion', START)
        self.assertIn('_args params ["_medic", "_epoch", "_exclusion"]', START)
        null_branch = START.split('if (isNull _medic) exitWith {', 1)[1].split('private _state', 1)[0]
        self.assertIn('removeGlobalEventJIP', null_branch)
        self.assertIn('setAnimExclusions deleteAt _index', null_branch)
        self.assertIn('if (_index >= 0)', null_branch)
        self.assertIn('if (_index >= 0)', STOP)
        self.assertIn('owner _medic != _owner', SYNC)
        self.assertIn('setAnimSpeedCoef 1', SYNC)

    def test_stethoscope_lifecycle_has_one_pose_owner_and_native_cleanup(self):
        self.assertNotRegex(CONTINUOUS, r'"ACM_GenericContinuous"')
        self.assertNotIn('call ace_common_fnc_doAnimation', CONTINUOUS)
        self.assertIn('ACME_fnc_treatmentPoseStart', CONTINUOUS)
        self.assertIn('ACME_fnc_treatmentPoseStop', CONTINUOUS)
        self.assertIn('_poseEnded', CONTINUOUS)
        self.assertIn('_enteredVehicle', CONTINUOUS)
        self.assertIn('call _onCancel', CONTINUOUS)
        self.assertIn('CBA_fnc_removeKeyHandler', CONTINUOUS)
        self.assertIn('ACM_core_openMedicalMenu', CONTINUOUS)
        steth = (ROOT / 'overrides/fn_useStethoscope.sqf').read_text()
        self.assertIn('call ACME_fnc_beginStethoscopeAction', steth)
        self.assertIn('ace_hearing_fnc_updateHearingProtection', steth)


if __name__ == '__main__':
    unittest.main()
