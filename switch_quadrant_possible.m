%check if this can allow (x,y) in 'quadrant' to switch to another quadrant.
function quad_possible = switch_quadrant_possible(x, y, quadrant)
QUADRANT1 = 1; %1 corresponds to top left
QUADRANT2 = 2; %2 corresponds to top right
QUADRANT3 = 3; %3 corresponds to bottom left
QUADRANT4 = 4; %4 corresponds to bottom right
quad_possible = 0;
switch (quadrant)
    case QUADRANT1
        quad_possible = (x == 3) || (y == 1);
    case QUADRANT2
        quad_possible = (x == 1) || (y == 1);
    case QUADRANT3
        quad_possible = (x == 3) || (y == 3);
    case QUADRANT4
        quad_possible = (x == 1) || (y == 3);
end
end