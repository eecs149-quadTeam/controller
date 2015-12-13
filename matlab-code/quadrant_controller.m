%to give a next coordinate that will try its best to not lock itself up
%output global coordinates
function [xg,yg,traversedout,orientationout, quadrant_out, out_state] = quadrant_controller(x, y, orientation, size_x, size_y, traversed_location, quadrant, quadrants_traversed, state,x_prev,y_prev)
    STABLE = 1;
    TRANSITION = 2;
    traversedout = traversed_location;
    out_state = state;
    switch (state)
        case STABLE
            [x_next,y_next, traversed_next, orientation_next] = sub_controller(x, y, orientation, size_x/2, size_y/2, traversed_location,x_prev,y_prev);
            [x_next_2, y_next_2, traversed_next_2, orientation_next_2] = sub_controller(x_next, y_next, orientation_next, size_x/2, size_y/2, traversed_next,x,y)
            %if current location is locked, go to untraversed quadrant.
            %if not locked,go to next_x and next_Y,
            %if next 2 locations are locked and if there's untraversed quadrant, next_x and next_y.
            %if next 2 locations are locked and there's no untraversed quadrant, leave quadrant.
            if (lock(x,y, traversed_location, size_x/2, size_y/2))
                disp('currently locked')
                out_state = TRANSITION;
                [xout,yout,orientationout,quadrant_out]= next_location(x,y,quadrant,quadrants_traversed)
                traversedout = [];
                if (quadrant_out ~= quadrant)
                    out_state = STABLE;
                end
            elseif (~lock(x_next_2,y_next_2, traversed_next_2,size_x/2,size_y/2))
                disp('next 2 not locked')
                xout = x_next;
                yout = y_next;
                traversedout = traversed_next;
                orientationout = orientation_next;
                quadrant_out = quadrant;
            elseif (lock(x_next_2,y_next_2, traversed_next_2,size_x/2,size_y/2) || lock(x_next,y_next, traversed_next,size_x/2,size_y/2))
                disp('going to be locked')
                [quadrants_exist, free_quadrants] = untraversed_quadrants_exist(quadrant,quadrants_traversed);
                quadrants_exist;
                if (quadrants_exist == 1)
                    xout = x_next
                    yout = y_next
                    quadrant
                    traversedout = traversed_next;
                    orientationout = orientation_next;
                    quadrant_out = quadrant;
                else
                    [xout, yout, orientationout, quadrant_out] = switch_nearest_quadrant(x,y,orientation,quadrant, quadrants_traversed);
                    traversedout = [];
                end
            end
        case TRANSITION
            disp('transitioning')
            traversedout = [];
            [xout,yout,orientationout,quadrant_out]= next_location(x,y,quadrant,quadrants_traversed)
            if (quadrant_out ~= quadrant)
                quadrant_out
                quadrant
                out_state = STABLE;
            end
    end
    [xg,yg] = convert_local_global(xout,yout,quadrant_out, size_x,size_y);
end
% 2 problems: 1. If there's no choice but to lock itself, it will continue
% traversing in the grid instead of trying to get out.
%2            2. It locks itself up