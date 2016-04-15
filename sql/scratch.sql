

drop table if exists  tempseg.both_directions;
select distinct rr.refnum,rl.direction
into tempseg.both_directions
from route_relations rr
join tempseg.revised_route_lines rl on (rr.id = rl.relation_id)
where rl.direction != 'both';


-- now populate a table with numbered route line segments that will be collected later




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
