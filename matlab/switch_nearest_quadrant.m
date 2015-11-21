%todo: need to take care of cases where the points are on the corner and
%have two choices of quadrants. It should choose the quadrant that has not
%been traversed. If both traversed or untraversed, choose one by flipping a
%coin.
function [xout, yout, orientationout, quadout] = switch_nearest_quadrant(x,y,orientation,quadrant,quadrants_traversed)
QUADRANT1 = 1; %1 corresponds to top left
QUADRANT2 = 2; %2 corresponds to top right
QUADRANT3 = 3; %3 corresponds to bottom left
QUADRANT4 = 4; %4 corresponds to bottom right
switch (quadrant)
    case QUADRANT1
        if (x == 3)
            xout = 1;
            yout = y;
            orientationout = 90;
            quadout = QUADRANT2;
        else
            xout = x;
            yout = 3;
            orientationout = 180;
            quadout = QUADRANT3;
        end
        if (x == 3 && y == 1 && ismember(quadout, quadrants_traversed) == 1)
            xout = x;
            yout = 3;
            orientationout = 180;
            quadout = QUADRANT3;
        end
    case QUADRANT2
        if (x == 1)
            xout = 3;
            yout = y;
            orientationout = 270;
            quadout = QUADRANT1;
        else
            xout = x;
            yout = 3;
            orientationout = 180;
            quadout = QUADRANT4;
        end
        if (x == 1 && y == 1 && ismember(quadout, quadrants_traversed) == 1)
            xout = x;
            yout = 3;
            orientationout = 180;
            quadout = QUADRANT4;
        end
    case QUADRANT3
        if (x == 3)
            xout = 1;
            yout = y;
            orientationout = 90;
            quadout = QUADRANT4;
        else
            xout = x;
            yout = 1;
            orientationout = 0;
            quadout = QUADRANT1;
        end
        if (x == 3 && y == 3 && ismember(quadout, quadrants_traversed) == 1)
            xout = x;
            yout = 1;
            orientationout = 0;
            quadout = QUADRANT1;
        end
    case QUADRANT4
        if (x ==1)
            xout = 3;
            yout = y;
            orientationout = 270;
            quadout = QUADRANT3;
        else
            xout = x;
            yout = 1;
            orientationout = 0;
            quadout = QUADRANT2;
        end
        if (x == 1 && y == 3 && ismember(quadout, quadrants_traversed) == 1)
            xout = x;
            yout = 1;
            orientationout = 0;
            quadout = QUADRANT2;
        end
end
end