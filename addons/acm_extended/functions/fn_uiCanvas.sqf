/* Returns the centered, aspect-safe ACM UI canvas as [x,y,w,h].
 * 16:9 is unchanged; ultrawide gains side gutters instead of stretching authored controls.
 */
private _w = safeZoneW min (safeZoneH * (16 / 9));
private _x = safeZoneX + ((safeZoneW - _w) / 2);
[_x, safeZoneY, _w, safeZoneH]
