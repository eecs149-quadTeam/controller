function [xout,yout,traversedout,orientationout] = sub_controller(x, y, orientation, max_x, max_y, traversed_location)

%implement state diagrams for the controller with only one robot

%Algorithm
%set up the grid size
%Initialize states traversed for each robot to empty array
%initialize the location of the robot
%While traversal not complete
%  case untraversed
%    save current location to traversed
%    create a variable that has a high chance of being 1 and low chance of
%    being 0
%    stay in untraversed if 1, move to traversed otherwise. output next
%    position accordingly
%  case traversed
%     save current location to traversed
%     create a variable that has a high chance of being 1 and low chance of
%     being 0
%     move to untraversed if 1, 0 otherwise. output next accordingly
%
min_x = 1;
min_y = 1;
traversedout = unique(cat(1,traversed_location,[x,y]),'rows','stable');
% if (isempty(traversed_location) || (ismember([x,y], traversed_location,'rows') == 0))
%     traversedout = cat(1,traversed_location,[x,y]);
% else
%     traversedout = traversed_location;
% end
random_gen = randsample(100,1);
%finding neighbors of current location
i = 1;
neighbor = [];
if (y + 1 <= max_y)
    neighbor(i,:) = [x,y+1];
    i = i + 1;
end
if (x + 1 <= max_x)
    neighbor(i,:) = [x+1,y];
    i = i + 1;
end
if (y - 1 >= min_y)
    neighbor(i,:) = [x,y-1];
    i = i + 1;
end
if (x - 1 >= min_x)
    neighbor(i,:) = [x-1,y];
    i = i + 1;
end
if (random_gen > [100])
    %choose traversed locations that are neighbors of current
    %location
    i = 1;
    j = 1;
    options = [];
    while (i <= size(neighbor,1))
        if (ismember(neighbor(i,:),traversedout, 'rows') == 1)
            options(j,:) = neighbor(i,:);
            j = j + 1;
        end
        i = i + 1;
    end
    %random number that will decide which orientation the robot
    %will go. High chance of maintaining current orientation.
    [xout,yout, orientationout] = next_orientation(x, y, orientation, options, neighbor);
    
else
    i = 1;
    j = 1;
    options = [];
    while (i <= size(neighbor,1))
        if (ismember(neighbor(i,:),traversedout, 'rows') == 0)
            options(j,:) = neighbor(i,:);
            j = j + 1;
        end
        i = i + 1;
    end
    
    %random number that will decide which orientation the robot
    %will go. High chance of maintaining current orientation.
    [xout,yout, orientationout] = next_orientation(x, y, orientation, options, neighbor);
end
end