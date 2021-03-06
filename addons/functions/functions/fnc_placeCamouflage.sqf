/*
    @Authors
        Christian 'chris5790' Klemm
    @Arguments
        ?
    @Return Value
        ?
    @Example
        ?
*/
#include "script_component.hpp"

params [
    ["_trench", objnull, [objnull]],
    ["_unit", objnull, [objnull]]
];

if (isNull _trench || {count getArray (configFile >> "CfgWorldsTextures" >> worldName >> "camouflageObjects") == 0}) exitWith {};

private _fnc_onFinish = {
    (_this select 0) params ["_unit", "_trench"];

    private _camouflageObjects = getArray (configFile >> "CfgWorldsTextures" >> worldName >> "camouflageObjects");
    private _placedObjects = [];

    {
        private _object = createSimpleObject [selectRandom _camouflageObjects, [0,0,0]];
        _object attachTo [_trench, getArray(_x)];

        if (is3DEN) then {
            _object setVariable [QGVAR(positionData), getArray(_x)];
        };

        _placedObjects pushBack _object;
    } forEach (configProperties [configFile >> "CfgVehicles" >> (typeof _trench) >> "CamouflagePositions"]);

    _trench setVariable [QGVAR(camouflageObjects), _placedObjects, true];

    // Reset animation
    [_unit, "", 1] call ace_common_fnc_doAnimation;
};

private _fnc_onFailure = {
    (_this select 0) params ["_unit"];
    // Reset animation
    [_unit, "", 1] call ace_common_fnc_doAnimation;
};

if (isNull _unit) exitWith {
    [[objnull, _trench]] call _fnc_onFinish;
};

[CAMOUFLAGE_DURATION, [_unit, _trench], _fnc_onFinish, _fnc_onFailure, localize LSTRING(placeCamouflageProgress)] call ace_common_fnc_progressBar;

[_unit, "AinvPknlMstpSnonWnonDnon_medic4"] call ace_common_fnc_doAnimation;
