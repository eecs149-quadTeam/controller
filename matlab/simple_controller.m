
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
% Size of grid
UNTRAVERSED = 0;
TRAVERSED = 1;
min_x = 1;
min_y = 1;
max_x = 5;
max_y = 5;

%initial conditions
x = 1;
y = 1;
traversed_location = [];
path_taken = [];
n = 100;
orientation = 0;
count = 1;
while (size(traversed_location,1) < (max_x*max_y))
    if (isempty(traversed_location) || (ismember([x,y], traversed_location,'rows') == 0))
        traversed_location = cat(1,traversed_location,[x,y]);
    end
    random_gen = randsample(n,1);
    
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
    
    if (random_gen > [95])
        
        %choose traversed locations that are neighbors of current
        %location
        i = 1;
        j = 1;
        options = [];
        while (i <= size(neighbor,1))
            if (ismember(neighbor(i,:),traversed_location, 'rows') == 1)
                options(j,:) = neighbor(i,:);
                j = j + 1;
            end
            i = i + 1;
        end
        if (~isempty(options))
            %random number that will decide which orientation the robot
            %will go. High chance of maintaining current orientation.
            [x,y, orientation] = next_orientation(x, y, orientation, options);
        end
        
    else
        i = 1;
        j = 1;
        options = [];
        while (i <= size(neighbor,1))
            if (ismember(neighbor(i,:),traversed_location, 'rows') == 0)
                options(j,:) = neighbor(i,:);
                j = j + 1;
            end
            i = i + 1;
        end
        
        %random number that will decide which orientation the robot
        %will go. High chance of maintaining current orientation.
        if (~isempty(options))
            %random number that will decide which orientation the robot
            %will go. High chance of maintaining current orientation.
            [x,y, orientation] = next_orientation(x, y, orientation, options);
        end
    end
    path_taken(count,:) = [x,y];
    count = count + 1;
end
plot_path(path_taken);