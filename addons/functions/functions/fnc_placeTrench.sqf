/*
 * Author: Garth 'L-H' de Wet, Ruthberg, edited by commy2 for better MP and eventual AI support, esteldunedain
 * Starts the place process for trench.
 *
 * Arguments:
 * 0: unit <OBJECT>
 * 1: Trench class <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [ACE_player, "ACE_envelope_small"] call ace_trenches_fnc_placeTrench
 *
 * Public: No
 */
#include "script_component.hpp"

params ["_unit", "_trenchClass"];

//Load trench data
private _noGeoModel = getText (configFile >> "CfgVehicles" >> _trenchClass >> "ace_trenches_noGeoClass");
if(_noGeoModel == "") then {_noGeoModel = _trenchClass;};

ace_trenches_trenchClass = _trenchClass;
ace_trenches_trenchPlacementData = getArray (configFile >> "CfgVehicles" >> _trenchClass >> "ace_trenches_placementData");
TRACE_1("",ace_trenches_trenchPlacementData);

// prevent the placing unit from running
[_unit, "forceWalk", "ACE_Trenches", true] call ace_common_fnc_statusEffect_set;

// create the trench
private _trench = createVehicle [_noGeoModel, [0, 0, 0], [], 0, "NONE"];
ace_trenches_trench = _trench;

// prevent collisions with trench
["ace_common_enableSimulationGlobal", [_trench, false]] call CBA_fnc_serverEvent;

ace_trenches_digDirection = 0;

GVAR(currentSurface) = "";

// pfh that runs while the dig is in progress
ace_trenches_digPFH = [{
    (_this select 0) params ["_unit", "_trench"];

    // Cancel if the helper object is gone
    if (isNull _trench) exitWith {
        [_unit] call ace_trenches_fnc_placeCancel;
    };

    // Cancel if the place is no longer suitable
    if !([_unit] call ace_trenches_fnc_canDigTrench) exitWith {
        [_unit] call ace_trenches_fnc_placeCancel;
    };

    // Update trench position
    ace_trenches_trenchPlacementData params ["_dx", "_dy", "_offset"];
    private _basePos = eyePos _unit vectorAdd ([sin getDir _unit, +cos getDir _unit, 0] vectorMultiply 1.0);

    private _angle = (ace_trenches_digDirection + getDir _unit);

    // _v1 forward from the player, _v2 to the right, _v3 points away from the ground
    private _v3 = surfaceNormal _basePos;
    private _v2 = [sin _angle, +cos _angle, 0] vectorCrossProduct _v3;
    private _v1 = _v3 vectorCrossProduct _v2;

    // Stick the trench to the ground
    _basePos set [2, getTerrainHeightASL _basePos];
    private _minzoffset = 0;
    private ["_ix","_iy"];
    for [{_ix = -_dx/2},{_ix <= _dx/2},{_ix = _ix + _dx/3}] do {
        for [{_iy = -_dy/2},{_iy <= _dy/2},{_iy = _iy + _dy/3}] do {
            private _pos = _basePos vectorAdd (_v2 vectorMultiply _ix)
                                    vectorAdd (_v1 vectorMultiply _iy);
            _minzoffset = _minzoffset min ((getTerrainHeightASL _pos) - (_pos select 2));
            #ifdef DEBUG_MODE_FULL
                _pos set [2, getTerrainHeightASL _pos];
                _pos2 = +_pos;
                _pos2 set [2, getTerrainHeightASL _pos + 1];
                drawLine3D [ASLtoAGL _pos, ASLtoAGL _pos2, [1,1,0,1]];
            #endif
        };
    };
    _basePos set [2, (_basePos select 2) + _minzoffset + _offset];
    TRACE_2("",_minzoffset,_offset);
    _trench setPosASL _basePos;
    _trench setVectorDirAndUp [_v1, _v3];
    ace_trenches_trenchPos = _basePos;

    if(surfaceType (position _trench) != GVAR(currentSurface)) then {
        GVAR(currentSurface) = surfaceType (position _trench);
        _trench setObjectTextureGlobal [0, [_trench] call FUNC(getSurfaceTexturePath)];
    };
}, 0, [_unit, _trench]] call CBA_fnc_addPerFrameHandler;

// add mouse button action and hint
[localize "STR_ace_trenches_ConfirmDig", localize "STR_ace_trenches_CancelDig", localize "STR_ace_trenches_ScrollAction"] call ace_interaction_fnc_showMouseHint;

_unit setVariable ["ace_trenches_Dig", [
    _unit, "DefaultAction",
    {ace_trenches_digPFH != -1},
    {[_this select 0] call FUNC(placeConfirm)}
] call ace_common_fnc_addActionEventHandler];

_unit setVariable ["ace_trenches_isPlacing", true, true];
