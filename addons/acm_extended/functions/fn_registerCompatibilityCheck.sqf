// shout if anything we fork has moved. see fn_compatcheck. this addon forks 26 ACM and ACE functions, and every
// one of them fails silently when upstream changes. it runs ten seconds in, so other mods have finished
// loading.
[{ [] call ACME_fnc_compatCheck; }, [], 10] call CBA_fnc_waitAndExecute;
