function output = neighbor_quad_traversed(x,y, quadrant, quadrants_traversed)     
QUADRANT1 = 1; %1 corresponds to top left
QUADRANT2 = 2; %2 corresponds to top right
QUADRANT3 = 3; %3 corresponds to bottom left
QUADRANT4 = 4; %4 corresponds to bottom right
output = 1;
switch (quadrant)
    case QUADRANT1
        if (x == 3 && y > 1)
            output = ismember(QUADRANT2, quadrants_traversed);
        elseif (x < 3 && y == 1)
            output = ismember(QUADRANT3, quadrants_traversed);
        elseif (x == 3 && y == 1)
            output = ismember(QUADRANT2, quadrants_traversed) && ismember(QUADRANT3, quadrants_traversed);
        end
    case QUADRANT2
        if (x == 1 && y > 1)
            output = ismember(QUADRANT1, quadrants_traversed);
        elseif (x > 1 && y == 1)
            output = ismember(QUADRANT4, quadrants_traversed);
        elseif (x == 1 && y == 1)
            output = ismember(QUADRANT1, quadrants_traversed) && ismember(QUADRANT4, quadrants_traversed);
        end
            
    case QUADRANT3
        if (x == 3 && y < 3)
            output = ismember(QUADRANT1, quadrants_traversed);
        elseif (x < 3 && y == 3)
            output = ismember(QUADRANT4, quadrants_traversed);
        elseif (x == 3 && y == 3)
            output = ismember(QUADRANT1, quadrants_traversed) && ismember(QUADRANT4, quadrants_traversed);
        end
    case QUADRANT4
        if (x == 1 && y < 3)
            output = ismember(QUADRANT3, quadrants_traversed);
        elseif (x > 1 && y == 3)
            output = ismember(QUADRANT2, quadrants_traversed);
        elseif (x == 1 && y == 3)
            output = ismember(QUADRANT2, quadrants_traversed) && ismember(QUADRANT3, quadrants_traversed);
        end
end