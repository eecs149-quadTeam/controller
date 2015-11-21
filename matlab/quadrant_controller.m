%to give a next coordinate that will try its best to not lock itself up
%output global coordinates
function [xout,yout,traversedout,orientationout, quadrant_out] = quadrant_controller(x, y, orientation, size_x, size_y, traversed_location, quadrant, quadrants_traversed)

    [x_next,y_next, traversed_next, orientation_next] = sub_controller(x, y, orientation, size_x/2, size_y/2, traversed_location);
    [x_next_2, y_next_2, traversed_next_2, orientation_next_2] = sub_controller(x_next, y_next, orientation_next, size_x/2, size_y/2, traversed_next);
    
    %check if x_next2, y_next_2 is going to lock the robot. locking is
    %defined as the state where the robot has to go to the traversed
    %locations again to move anywhere.
    %if going to lock and can switch quadrants, then switch
    %if not, then go through these untraversed locations and then switch in
    %an "optimal" way.
    lock(x_next_2, y_next_2, traversed_next_2, size_x/2, size_y/2)
    switch_quadrant_possible(x, y, quadrant)
    neighbor_quad_traversed(x_next,y_next, quadrant, quadrants_traversed)
    ismember([x_next, y_next], traversed_next, 'rows')
    %will switch quadrant if next location is in its traversed space or it's going to lock itself in two steps and it
    %is still allowed to switch and its neighbor is not in quadrant.
    if (
        
        
    if (lock(x_next_2, y_next_2, traversed_next_2, size_x/2, size_y/2) && switch_quadrant_possible(x, y, quadrant) ...
            && (neighbor_quad_traversed(x_next,y_next, quadrant, quadrants_traversed)) || (ismember([x_next, y_next], traversed_next, 'rows') == 1))
        [xout, yout, orientationout, quadrant_out] = switch_nearest_quadrant(x,y,orientation,quadrant, quadrants_traversed);
        traversedout = [];
    else
        xout = x_next;
        yout = y_next;
        traversedout = traversed_next;
        orientationout = orientation_next;
        quadrant_out = quadrant;
    end
    [xout,yout]= convert_local_global(xout,yout,quadrant_out,size_x,size_y);
end
% 2 problems: 1. If there's no choice but to lock itself, it will continue
% traversing in the grid instead of trying to get out.
%2            2. It locks itself up