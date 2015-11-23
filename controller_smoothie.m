clc;
clear;
%state definitions
STABLE = 1;
TRAN1 = 2;
TRAN2 = 3;
TRAN1_2 = 4;
QUADRANT1 = 1; %1 corresponds to top left
QUADRANT2 = 2; %2 corresponds to top right
QUADRANT3 = 3; %3 corresponds to bottom left
QUADRANT4 = 4; %4 corresponds to bottom right

%controller for patrolling in quadrants.
%arguments
size_x = 6;
size_y = 6;
number_of_robots = 1;
%local origin at quadrant1
x1 = 1;
y1 = 1;
%global coordinates. will be set as output to accessors.
xg1 = 1;
yg1 = 1;
orientation = 0;
%initial quadrant of robot1
quadrant1 = QUADRANT3; %bottom_left_corner
%quandrants traversed for this robot.
quadrants_traversed_1 =[];
%local locations traversed for particular. in [x,y] pairs in local
%coordinates.
traversed1 = [];
area_sub_grid = size_x/2 * size_y/2;
state = STABLE;
state_quad = STABLE;
count = 1;
path_taken = [1,1];
x_prev = 0;
y_prev = 0;
while (count <= 200)
    count
    switch (state)
        case STABLE
            %concatenate quadrant1 to quandrants_traversed_1
            quadrants_traversed_1=unique(cat(2,quadrants_traversed_1,quadrant1))
            %if it has finished traversing, clean up all quadrants
            %traversed
            if (size(quadrants_traversed_1, 2) >= 4)
                path_taken = cat(1,path_taken,[0,0]);
                quadrants_traversed_1 = [];
            end
            %quadrant controller will return next set of coordinates,
            %orientation, quadrant and update traversed locations with current
            %location
            quadrant_temp = quadrant1;
            [xg1, yg1, traversed1, orientation, quadrant1, state_quad]= quadrant_controller(x1, y1, orientation, size_x, size_y, traversed1, quadrant1, quadrants_traversed_1,state_quad,x_prev,y_prev); %x1 and y1 are local coordinates.
            if (quadrant_temp ~= quadrant1)
                x_prev = 0;
                y_prev = 0;
            else
                x_prev = x1;
                y_prev = y1;
            end
            %Convert x1 and y1 to global coordinate system. Used for output
            %to accessor and scenario which will switch to TRAN1.
            [x1, y1, quadrant1] = convert_global_local(xg1,yg1,size_x, size_y);
            path_taken = cat(1,path_taken,[xg1,yg1]);
    end
    count = count + 1;
end
plot_path(path_taken)