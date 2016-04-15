-- Deploy numbered_route_lines:nrl to pg
-- requires: populate

BEGIN;

select q.refnum,q.direction
       ,st_linemerge(st_collect(routeline )) as routeline
into  tempseg.numbered_route_lines
from tempseg.numbered_route_line_segments q
group by refnum,direction
;

COMMIT;
