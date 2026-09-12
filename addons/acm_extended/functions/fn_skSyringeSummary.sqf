params [["_e",[],[[]]]];if(_e isEqualTo [])exitWith{"No syringe selected"};
_e params [["_med","",[""]],["_size",10,[0]],["_amt",0,[0]],["_label","",[""]],["_ns",0,[0]],["_components",[],[[]]]];
private _fn={params["_m"];private _n=localize(format["STR_ACM_Circulation_Medication_%1",_m]);if(_n==""||{_n==format["STR_ACM_Circulation_Medication_%1",_m]})then{_n=_m;};_n};
private _vol=(_amt+_ns) max 0; if(_vol<=0)then{_vol=_amt;};
if(!(_components isEqualTo []))exitWith{private _p=[];{_x params["_m","_ml"];private _d=_ml*getNumber(configFile>>"ACM_Medication">>"Concentration">>_m>>"concentration");private _u="mg";if(_d<1&&{_d>0})then{_d=_d*1000;_u="mcg"};_p pushBack format["%1 %2 %3",[_m]call _fn,_d toFixed 2,_u];}forEach _components;format["%1 in %2 mL",_p joinString " + ",(_amt+_ns) toFixed 2]};
private _dose=_amt*getNumber(configFile>>"ACM_Medication">>"Concentration">>_med>>"concentration");private _u="mg";if(_dose<1&&{_dose>0})then{_dose=_dose*1000;_u="mcg"};
format["%1 %2 %3 in %4 mL",[_med]call _fn,_dose toFixed 2,_u,_vol toFixed 2]
