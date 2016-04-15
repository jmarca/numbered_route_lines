-- Revert numbered_route_lines:populate from pg

BEGIN;

truncate tempseg.numbered_route_line_segments;

COMMIT;
