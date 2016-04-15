-- Verify numbered_route_lines:nrls on pg

BEGIN;

SELECT refnum,direction,routeline
  FROM tempseg.numbered_route_line_segments
 WHERE FALSE;

ROLLBACK;
