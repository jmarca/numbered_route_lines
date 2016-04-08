update osm.relations set tags = tags || ('network' => 'US:I') where tags->'network'='I';

-- a view for super relations, so as to blot them out for now easily.

create view osm.super_relations as
select a.relation_id, a.types from (
    select relation_id,array_agg(distinct member_type) as types
    from osm.relation_members
    group by relation_id
    ) a
join osm.relations b on (b.id = a.relation_id)
where 'R' = ANY ( a.types)
  and (b.tags->'network') is not null;

create view osm.relation_roles as
select a.relation_id, a.roles from (
    select relation_id, array_agg(distinct member_role) as roles
    from osm.relation_members
    where member_role is not null
      and member_role != ''  group by relation_id
    ) a
join osm.relations b on (b.id = a.relation_id)
where  (b.tags->'network') ~* '^I$|^US:'
  and (b.tags->'direction') is null;


-- \i blacklist-relations.sql

DROP TABLE IF EXISTS blacklist_relations CASCADE;
CREATE TABLE blacklist_relations (
       relation_id integer PRIMARY KEY, -- relation id
       reason TEXT
);

--- some relations are just ugly and not worth fixing
-- source blacklist.sql here


Drop view osm.route_relations;
create or replace view osm.route_relations as
SELECT r.*,
       r.tags->'network' AS network,
       r.tags->'ref' AS refstring,
       CASE
         WHEN (r.tags->'network') ~* '^I$|^US:' THEN CAST( SUBSTRING((r.tags->'ref') from E'\\d+') AS NUMERIC) ELSE NULL
       END AS refnum,
        CASE
         WHEN r.tags->'direction' ~* '^n' THEN 'north'
         WHEN r.tags->'direction' ~* '^s' THEN 'south'
         WHEN r.tags->'direction' ~* '^e'  THEN 'east'
         WHEN r.tags->'direction' ~* '^w'  THEN 'west'
         WHEN r.tags->'ref' ~* '(^n|north)' THEN 'north'
         WHEN r.tags->'ref' ~* '(^s|south)' THEN 'south'
         WHEN r.tags->'ref' ~* '(^e|east)'  THEN 'east'
         WHEN r.tags->'ref' ~* '(^w|west)'  THEN 'west'
         WHEN ARRAY['north','south','east','west'] && rr.roles THEN 'roles'
         ELSE r.tags->'direction'
        END
AS direction
FROM osm.relations r
   LEFT OUTER JOIN osm.super_relations sr on (r.id = sr.relation_id)
   LEFT OUTER JOIN osm.relation_roles rr on (r.id = rr.relation_id)
   LEFT OUTER JOIN osm.blacklist_relations br on (r.id = br.relation_id)
WHERE
   br.relation_id IS NULL
   AND sr.relation_id IS NULL
   AND (r.tags->'network') ~* '^I$|^US:'
   AND coalesce(r.tags->'addr:state', 'CA') = 'CA'
   AND coalesce( r.tags->'ref', r.tags->'direction' ) is not null;


drop table if exists  tempseg.both_directions;
select distinct rr.refnum,rl.direction
into tempseg.both_directions
from route_relations rr
join tempseg.revised_route_lines rl on (rr.id = rl.relation_id)
where rl.direction != 'both';

-- now populate a table with numbered route line segments that will be collected later
drop table if exists tempseg.numbered_route_line_segments ;
create table tempseg.numbered_route_line_segments (
 refnum    numeric,
 direction  text
);
SELECT AddGeometryColumn( 'tempseg','numbered_route_line_segments', 'routeline', 4326, 'LINESTRING', 2);

insert into tempseg.numbered_route_line_segments (refnum,direction,routeline)
  select rr.refnum,rl.direction, (st_dump(routeline)).geom as dump_geom
  from route_relations rr
  join tempseg.revised_route_lines rl on (rr.id = rl.relation_id)
  where rl.direction != 'both'
;
insert into tempseg.numbered_route_line_segments (refnum,direction,routeline)
  select rr.refnum,bd.direction, (st_dump(routeline)).geom as dump_geom
  from route_relations rr
  join tempseg.revised_route_lines rl on (rr.id = rl.relation_id)
  join tempseg.both_directions bd using (refnum)
  where rl.direction = 'both'
;
-- and now what about those lines that have no direction other than both?  add them in
insert into tempseg.numbered_route_line_segments (refnum,direction,routeline)
  select rr.refnum,rl.direction, (st_dump(routeline)).geom as dump_geom
  from route_relations rr
  left join tempseg.revised_route_lines rl on (rr.id = rl.relation_id)
  left join tempseg.both_directions bd using (refnum)
  where rl.direction = 'both'
        and bd.refnum is null;


drop table if exists tempseg.numbered_route_lines ;
select q.refnum,q.direction
       ,st_linemerge(st_collect(routeline )) as routeline
into  tempseg.numbered_route_lines
from
tempseg.numbered_route_line_segments q
group by refnum,direction
;
