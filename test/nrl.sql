SET client_min_messages TO warning;
CREATE EXTENSION IF NOT EXISTS pgtap;
RESET client_min_messages;

BEGIN;
SELECT no_plan();
-- SELECT plan(1);

SELECT pass('Test nrl!');
SELECT is(
    (SELECT count(*)
          FROM tempseg.numbered_route_lines
    )::integer,
    444,
    'The data got loaded okay'
);

SELECT finish();
ROLLBACK;
