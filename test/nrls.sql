SET client_min_messages TO warning;
CREATE EXTENSION IF NOT EXISTS pgtap;
RESET client_min_messages;

BEGIN;
SELECT no_plan();
-- SELECT plan(1);

SELECT pass('Test nrls!');
SELECT has_table( 'tempseg','numbered_route_line_segments','has nrls table' );

SELECT finish();
ROLLBACK;
