-- Deploy numbered_route_lines:nrls to pg
-- requires: revised_route_lines:tempseg_schema
-- requires: calvad_db_geoextensions:geoextensions

BEGIN;

create table tempseg.numbered_route_line_segments (
 refnum    numeric,
 direction  text
);
SELECT AddGeometryColumn( 'tempseg','numbered_route_line_segments',
                          'routeline', 4326, 'LINESTRING', 2);


COMMIT;
