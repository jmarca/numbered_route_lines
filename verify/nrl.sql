-- Verify numbered_route_lines:nrl on pg

BEGIN;

SELECT refnum,direction,routeline
  FROM tempseg.numbered_route_lines
 WHERE FALSE;

ROLLBACK;
