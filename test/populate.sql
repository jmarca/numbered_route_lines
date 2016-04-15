SET client_min_messages TO warning;
CREATE EXTENSION IF NOT EXISTS pgtap;
RESET client_min_messages;

BEGIN;
SELECT no_plan();
-- SELECT plan(1);

SELECT pass('Test populate!');
SELECT is(
    (SELECT count(*)
          FROM tempseg.numbered_route_line_segments
    )::integer,
    2297,
    'The data got loaded okay'
);

SELECT finish();
ROLLBACK;
