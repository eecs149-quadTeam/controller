clc;
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
quadrants_traversed_1 =[];
traversed1 = [];
area_sub_grid = size_x/2 * size_y/2;
state = STABLE;
count = 1;
path_stable = []; 
path_tran1 = [];
path_taken =[xg1,yg1,3];
local_path_taken = [x1,y1,quadrant1];
path_stable = [x1,y1,0];
while (count <= 50)
    count
    switch (state)
        case STABLE
            %create a random variable for robot1 to determine whether to
            %switch to another quadrant or not.
            random1 = randsample(100,1)/100 %need some check. might be giving out high numbers too often.
            %calculate which location and orientation to go to in the same
            %quadrant.
            quadrants_traversed_1=unique(cat(2,quadrants_traversed_1,quadrant1));
            if (size(quadrants_traversed_1, 2) >= 4)
                quadrants_traversed_1 = [];
            end
            [xg1, yg1, traversed1, orientation, quadrant1]= quadrant_controller(x1, y1, orientation, size_x, size_y, traversed1, quadrant1, quadrants_traversed_1); %x1 and y1 are local coordinates.
            
            %Convert x1 and y1 to global coordinate system. Used for output
            %to accessor and scenario which will switch to TRAN1.
            path_stable = cat(1,path_stable,[xg1,yg1,size(traversed1,1)]);
            %True if transitioning to TRAN1. update quandrants traversed
            %and reset if all quadrants are traversed. Calculate next
            %quadrant and destination.
%             if (random1 < (size(traversed1,1)/area_sub_grid)) %should check if point on edge and neighboring quadrant(s) is/are untraversed or if this is the last spot that is traversed.
%                 quadrants_traversed_1=unique(cat(2,quadrants_traversed_1,quadrant1));
%                 traversed1 = [];
%                 if (size(quadrants_traversed_1, 2) >= 4)
%                     quadrants_traversed_1 = [];
%                 end
%                 %[xg1, yg1, quadrant1] = next_quad_location(x, y, quadrant1, quadrants_traversed_1, size_x, size_y);
%                 [destination_quadrant, x_dest, y_dest] = calculate_next_quad(quadrant1, quadrants_traversed_1, size_x, size_y); %x_dest and y_dest are global coordinates.
%                 path_stable = cat(1,path_stable,[1000,1000, 2000]);
%             end
            [x1, y1, quadrant1] = convert_global_local(xg1,yg1,size_x, size_y);
    end
    local_path_taken(count + 1,:) = [x1, y1, quadrant1];
    path_taken(count + 1,:) = [xg1,yg1,quadrant1];
    count = count + 1;
end
plot_path(path_taken)