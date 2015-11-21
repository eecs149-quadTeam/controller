%Convert x,y from local coordinate system to global coordinate system
%using information of current quadrant and size of grid.
function [xg,yg] = convert_local_global(x,y,quadrant, size_x,size_y)
QUADRANT1 = 1; %1 corresponds to top left
QUADRANT2 = 2; %2 corresponds to top right
QUADRANT3 = 3; %3 corresponds to bottom left
QUADRANT4 = 4; %4 corresponds to bottom right
switch (quadrant)
    case QUADRANT1
        xg = x;
        yg = y + size_y/2;
    case QUADRANT2
        xg = x+size_x/2;
        yg = y + size_y/2;
    case QUADRANT3
        xg = x;
        yg = y;
    case QUADRANT4
        xg = x + size_x/2;
        yg = y;
end
        
end