-- Verify numbered_route_lines:populate on pg

BEGIN;

SELECT 1/count(*)
  FROM tempseg.numbered_route_line_segments;


ROLLBACK;
