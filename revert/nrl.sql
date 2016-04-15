-- Revert numbered_route_lines:nrl from pg

BEGIN;

drop table tempseg.numbered_route_lines;

COMMIT;
