-- Revert numbered_route_lines:nrls from pg

BEGIN;

drop table tempseg.numbered_route_line_segments;

COMMIT;
