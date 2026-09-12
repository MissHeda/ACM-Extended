// the semantic color router for the client-side accessibility modes of ACM extended.
// use it as ["role", alpha] call ACME_fnc_a11yColor.
// the roles are intentionally semantic, so every minigame and HUD can stay consistent.
params [ ["_role", "white"], ["_alpha", -1] ];

private _mode = toLower (missionNamespace getVariable ["ACME_a11y_colorblindMode", "normal"]);
private _r = toLower _role;
private _family = "normal";
if (_mode in ["deuteranomaly", "deuteranopia", "protanomaly", "protanopia"]) then { _family = "redgreen"; };
if (_mode in ["tritanomaly", "tritanopia"]) then { _family = "tritan"; };
if (_mode isEqualTo "achromatopsia") then { _family = "mono"; };

private _col = switch (_family) do {
    case "redgreen": {
        switch (_r) do {
            case "danger":      {[0.90, 0.50, 0.00, 1]};  // orange
            case "danger2":     {[0.95, 0.62, 0.10, 1]};
            case "warning":     {[0.95, 0.88, 0.25, 1]};
            case "success":     {[0.00, 0.45, 0.70, 1]};  // blue
            case "success2":    {[0.18, 0.58, 0.82, 1]};
            case "info":        {[0.35, 0.70, 0.90, 1]};
            case "oxygen":      {[0.35, 0.70, 0.90, 1]};
            case "capno":       {[0.00, 0.45, 0.70, 1]};
            case "cyan":        {[0.35, 0.70, 0.90, 1]};
            case "warm":        {[0.88, 0.50, 0.00, 1]};
            case "hot":         {[0.95, 0.88, 0.25, 1]};
            case "blood":       {[0.90, 0.50, 0.00, 1]};
            case "cool":        {[0.35, 0.70, 0.90, 1]};
            case "selected":    {[0.00, 0.45, 0.70, 1]};
            case "inactive":    {[0.48, 0.50, 0.55, 1]};
            default              {[1, 1, 1, 1]};
        };
    };
    case "tritan": {
        switch (_r) do {
            case "danger":      {[0.82, 0.18, 0.45, 1]};  // magenta-red
            case "danger2":     {[0.95, 0.35, 0.58, 1]};
            case "warning":     {[0.95, 0.58, 0.12, 1]};
            case "success":     {[0.00, 0.62, 0.55, 1]};  // teal
            case "success2":    {[0.20, 0.76, 0.68, 1]};
            case "info":        {[0.90, 0.60, 0.95, 1]};
            case "oxygen":      {[0.00, 0.62, 0.55, 1]};
            case "capno":       {[0.00, 0.62, 0.55, 1]};
            case "cyan":        {[0.00, 0.62, 0.55, 1]};
            case "warm":        {[0.90, 0.42, 0.10, 1]};
            case "hot":         {[0.95, 0.58, 0.12, 1]};
            case "blood":       {[0.82, 0.18, 0.45, 1]};
            case "cool":        {[0.90, 0.60, 0.95, 1]};
            case "selected":    {[0.00, 0.62, 0.55, 1]};
            case "inactive":    {[0.48, 0.50, 0.55, 1]};
            default              {[1, 1, 1, 1]};
        };
    };
    case "mono": {
        switch (_r) do {
            case "danger":      {[0.92, 0.92, 0.92, 1]};
            case "danger2":     {[0.78, 0.78, 0.78, 1]};
            case "warning":     {[1.00, 1.00, 1.00, 1]};
            case "success":     {[0.35, 0.35, 0.35, 1]};
            case "success2":    {[0.52, 0.52, 0.52, 1]};
            case "info":        {[0.70, 0.70, 0.70, 1]};
            case "oxygen":      {[0.70, 0.70, 0.70, 1]};
            case "capno":       {[0.85, 0.85, 0.85, 1]};
            case "cyan":        {[0.70, 0.70, 0.70, 1]};
            case "warm":        {[0.78, 0.78, 0.78, 1]};
            case "hot":         {[1.00, 1.00, 1.00, 1]};
            case "blood":       {[0.86, 0.86, 0.86, 1]};
            case "cool":        {[0.55, 0.55, 0.55, 1]};
            case "selected":    {[0.62, 0.62, 0.62, 1]};
            case "inactive":    {[0.42, 0.42, 0.42, 1]};
            default              {[1, 1, 1, 1]};
        };
    };
    default {
        switch (_r) do {
            case "danger":      {[0.85, 0.20, 0.20, 1]};
            case "danger2":     {[1.00, 0.28, 0.28, 1]};
            case "warning":     {[1.00, 0.85, 0.16, 1]};
            case "success":     {[0.20, 1.00, 0.30, 1]};
            case "success2":    {[0.20, 0.65, 0.20, 1]};
            case "info":        {[0.30, 0.55, 1.00, 1]};
            case "oxygen":      {[0.18, 0.60, 0.96, 1]};
            case "capno":       {[0.64, 0.92, 0.20, 1]};
            case "cyan":        {[0.30, 0.95, 1.00, 1]};
            case "warm":        {[1.00, 0.45, 0.12, 1]};
            case "hot":         {[1.00, 0.92, 0.70, 1]};
            case "blood":       {[0.95, 0.55, 0.55, 1]};
            case "cool":        {[0.45, 0.62, 0.75, 1]};
            case "selected":    {[0.15, 0.40, 0.55, 1]};
            case "inactive":    {[0.45, 0.48, 0.52, 1]};
            default              {[1, 1, 1, 1]};
        };
    };
};

_col = +_col;
if ((_alpha isEqualType 0) && {_alpha >= 0}) then { _col set [3, _alpha]; };
_col
