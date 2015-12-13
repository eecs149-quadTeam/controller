%Assume that we will have at least one untraversed quadrant. This is valid
%because this function is executed only when transitioning from STABLE to
%TRANSITION in 'quadrant_controller'. This happens when it is locked, which
%would happen only if there's an untraversed quadrant at the first place.
function [xout,yout,orientationout,quadrant_out] = next_location(x,y,quadrant,quadrants_traversed)
    options =[];
    QUADRANT1 = 1; %1 corresponds to top left
    QUADRANT2 = 2; %2 corresponds to top right
    QUADRANT3 = 3; %3 corresponds to bottom left
    QUADRANT4 = 4; %4 corresponds to bottom right
    [quadrants_exist, free_quadrant]= untraversed_quadrants_exist(quadrant,quadrants_traversed);
    %On the border with another quadrant
    if (switch_quadrant_possible(x,y,quadrant))
        [xout, yout, orientationout, quadrant_out] = switch_nearest_quadrant(x,y,quadrant,quadrants_traversed);
        %There are times when the current location is on the border of
        %traversed quadrant. In that case, this would force it to go to an
        %untraversed quadrant by potentially going over traversed location.
        if (ismember(quadrant_out, quadrants_traversed) == 1)
            switch(quadrant)
                case QUADRANT1
                    if (free_quadrant(1) == QUADRANT2)
                        xout = x + 1;
                        yout = y;
                        orientationout = 90;
                        quadrant_out = 1;
                    else
                        xout = x;
                        yout = y - 1;
                        orientationout = 180;
                        quadrant_out = 1;
                    end
                case QUADRANT2
                    if (free_quadrant(1) == QUADRANT1)
                        xout = x - 1;
                        yout = y;
                        orientationout = 270;
                        quadrant_out = 2;
                    else
                        xout = x;
                        yout = y - 1;
                        orientationout = 180;
                        quadrant_out = 2;
                    end
                case QUADRANT3
                    if (free_quadrant(1) == QUADRANT4)
                        xout = x + 1;
                        yout = y;
                        orientationout = 90;
                        quadrant_out = 3;
                    else
                        xout = x;
                        yout = y + 1;
                        orientationout = 0;
                        quadrant_out = 3;
                    end
                case QUADRANT4
                    if (free_quadrant(1) == QUADRANT3)
                        xout = x - 1;
                        yout = y;
                        orientationout = 270;
                        quadrant_out = 4;
                    else
                        xout = x;
                        yout = y + 1;
                        orientationout = 0;
                        quadrant_out = 4;
                    end
            end
        end
    else
        switch (quadrant)
            case QUADRANT1
                if (length(free_quadrant) == 2)
                    if (y == 3)
                        xout = x + 1;
                        yout = y;
                        orientationout = 90;
                        quadrant_out = 1;
                    else
                        xout = x;
                        yout = y - 1;
                        orientationout = 180;
                        quadrant_out = 1;
                    end
                elseif (free_quadrant(1) == QUADRANT2)
                    xout = x + 1;
                    yout = y;
                    orientationout = 90;
                    quadrant_out = 1;
                else
                    xout = x;
                    yout = y - 1;
                    orientationout = 180;
                    quadrant_out = 1;
                end
            case QUADRANT2
                if (length(free_quadrant) == 2)
                    if (y == 3)
                        xout = x - 1;
                        yout = y;
                        orientationout = 270;
                        quadrant_out = 2;
                    else
                        xout = x;
                        yout = y - 1;
                        orientationout = 180;
                        quadrant_out = 2;
                    end
                elseif (free_quadrant(1) == QUADRANT1)
                    xout = x - 1;
                    yout = y;
                    orientationout = 270;
                    quadrant_out = 2;
                else
                    xout = x;
                    yout = y - 1;
                    orientationout = 180;
                    quadrant_out = 2;
                end                
            case QUADRANT3
                if (length(free_quadrant) == 2)
                    if (y == 1)
                        xout = x + 1;
                        yout = y;
                        orientationout = 90;
                        quadrant_out = 3;
                    else
                        xout = x;
                        yout = y + 1;
                        orientationout = 0;
                        quadrant_out = 3;
                    end
                elseif (free_quadrant(1) == QUADRANT4)
                    xout = x + 1;
                    yout = y;
                    orientationout = 90;
                    quadrant_out = 3;
                else
                    xout = x;
                    yout = y + 1;
                    orientationout = 0;
                    quadrant_out = 3;
                end
            case QUADRANT4
                if (length(free_quadrant) == 2)
                    if (y == 1)
                        xout = x - 1;
                        yout = y;
                        orientationout = 270;
                        quadrant_out = 4;
                    else
                        xout = x;
                        yout = y + 1;
                        orientationout = 0;
                        quadrant_out = 4;
                    end
                elseif (free_quadrant(1) == QUADRANT3)
                    xout = x - 1;
                    yout = y;
                    orientationout = 270;
                    quadrant_out = 4;
                else
                    xout = x;
                    yout = y + 1;
                    orientationout = 0;
                    quadrant_out = 4;
                end
        end
        %find the quadrant untraversed.
        %move toward the quadrant.
    end
end