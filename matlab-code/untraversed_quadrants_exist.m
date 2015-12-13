%check if any neighbor quadrants are free. If free, report them in 'free
%quadrants'
function [quadrants_exist, free_quadrants] = untraversed_quadrants_exist(quadrant,quadrants_traversed)
QUADRANT1 = 1; %1 corresponds to top left
QUADRANT2 = 2; %2 corresponds to top right
QUADRANT3 = 3; %3 corresponds to bottom left
QUADRANT4 = 4; %4 corresponds to bottom right
free_quadrants = [];
switch (quadrant)
    case QUADRANT1
        neighbor_quadrants = [QUADRANT2, QUADRANT3];

    case QUADRANT2
        neighbor_quadrants = [QUADRANT1, QUADRANT4];
    case QUADRANT3
        neighbor_quadrants = [QUADRANT1, QUADRANT4];
    case QUADRANT4
        neighbor_quadrants = [QUADRANT2, QUADRANT3];
end
if ~ismember(neighbor_quadrants(1), quadrants_traversed)
    free_quadrants = cat(1,free_quadrants,neighbor_quadrants(1));
end
if ~ismember(neighbor_quadrants(2),quadrants_traversed)
    free_quadrants = cat(1,free_quadrants,neighbor_quadrants(2));
end
quadrants_exist = ~(ismember(neighbor_quadrants(1), quadrants_traversed) && ismember(neighbor_quadrants(2), quadrants_traversed));
end