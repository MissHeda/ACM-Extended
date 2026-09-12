/* Pure gameplay view predicate: [lift fraction, blade depth quality, angle stage, target stage]. */
params ["_fraction", "_depthQuality", "_stage", "_target"];
private _liftGate = (missionNamespace getVariable ["ACME_laryngo_viewLiftGate", 0.80]) max 0.60 min 0.90;
private _tolerance = (missionNamespace getVariable ["ACME_laryngo_fulcTolerance", 1]) max 0 min 1;
private _angleOK = abs (_stage - _target) <= _tolerance;
private _depthOK = _depthQuality >= 0.90;
private _ready = _angleOK && {_depthOK} && {_fraction >= _liftGate};
private _lift = (_fraction / _liftGate) max 0 min 1;
private _reveal = if (_ready) then {1} else {
    // A partial view remains legible, but optimal depth and angle are still needed.
    ((0.66 + (if (_angleOK) then {0.24} else {0.10})) * _lift * _depthQuality) max 0 min 0.92
};
[_reveal, _ready]
