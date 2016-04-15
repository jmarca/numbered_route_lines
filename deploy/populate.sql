-- Deploy numbered_route_lines:populate to pg
-- requires: nrls

BEGIN;

insert into tempseg.numbered_route_line_segments (refnum,direction,routeline)
select rr.refnum,rl.direction
       , (st_dump(routeline)).geom as routeline
from osm.route_relations rr
join tempseg.revised_route_lines rl on (rr.id = rl.relation_id)
where rl.direction != 'both'
;

-- now add those with "both" direction in revised_route_lines
CREATE TEMP TABLE both_directions (
 refnum    numeric,
 direction  text
)
ON COMMIT DROP;

INSERT INTO both_directions (refnum,direction)
SELECT distinct rr.refnum,rl.direction
FROM osm.route_relations rr
JOIN tempseg.revised_route_lines rl on (rr.id = rl.relation_id)
WHERE rl.direction != 'both';


INSERT INTO tempseg.numbered_route_line_segments (refnum,direction,routeline)
SELECT rr.refnum,bd.direction
       , (st_dump(routeline)).geom as routeline
FROM osm.route_relations rr
JOIN tempseg.revised_route_lines rl on (rr.id = rl.relation_id)
JOIN both_directions bd using (refnum)
WHERE rl.direction = 'both'
;


-- and now what about those lines that have no direction other than
-- both?  add them in too

INSERT INTO tempseg.numbered_route_line_segments (refnum,direction,routeline)
SELECT rr.refnum,rl.direction
       , (st_dump(routeline)).geom as dump_geom
FROM osm.route_relations rr
LEFT JOIN tempseg.revised_route_lines rl on (rr.id = rl.relation_id)
LEFT JOIN both_directions bd using (refnum)
WHERE rl.direction = 'both'
      AND bd.refnum is null;

COMMIT;
