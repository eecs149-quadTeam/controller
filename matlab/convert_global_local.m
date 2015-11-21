%Convert x,y from global coordinate system to local coordinate system
%using information of size of grid.
function [x,y, quadrant] = convert_global_local(xg,yg, size_x,size_y)
QUADRANT1 = 1; %1 corresponds to top left
QUADRANT2 = 2; %2 corresponds to top right
QUADRANT3 = 3; %3 corresponds to bottom left
QUADRANT4 = 4; %4 corresponds to bottom right
if (xg <= size_x/2 && yg <= size_y/2)
    x = xg;
    y = yg;
    quadrant = QUADRANT3;
elseif (xg <= size_x/2 && yg > size_y/2)
    quadrant = QUADRANT1;
    x = xg;
    y = yg - size_y/2;
elseif (xg > size_x/2 && yg > size_y/2)
    quadrant = QUADRANT2;
    x = xg - size_x/2;
    y = yg - size_y/2;
else
    quadrant = QUADRANT4;
    x = xg - size_x/2;
    y = yg;
end