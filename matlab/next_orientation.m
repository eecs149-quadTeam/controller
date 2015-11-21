function [next_x,next_y,next_orientation] = next_orientation(x,y,orientation, option, neighbor)
rand_orientation = randsample(100,1);
%find positions that have the same and different orientation
i = 1;
if (orientation == 0)
    straight_x = x;
    straight_y = y + 1;
elseif (orientation == 90)
    straight_x = x + 1;
    straight_y = y;
elseif (orientation == 180)
    straight_x = x;
    straight_y = y - 1;
else
    straight_x = x - 1;
    straight_y = y;
end
non_straight = [];
j = 1;
while (i <= size(option,1))
    if (ismember([straight_x,straight_y],option(i,:), 'rows') == 0)
        non_straight(j,:) = option(i,:);
        j = j + 1;
    end
    i = i + 1;
end
if (isempty(option))
    if (ismember([straight_x,straight_y],neighbor, 'rows') == 1)
        next_x = straight_x;
        next_y = straight_y;
        next_orientation = orientation;
    else
        rand_index = randsample(size(neighbor,2),1);
        next_x = neighbor(rand_index,1); %should select a random neighbor in the future
        next_y = neighbor(rand_index,2);
        if (next_x > x)
            next_orientation = 90;
        elseif (next_x < x)
            next_orientation = 270;
        elseif (next_y > y)
            next_orientation = 0;
        elseif (next_y < y)
            next_orientation = 180;
        end
    end
else
    if (rand_orientation <= 90 && ismember([straight_x,straight_y],option,'rows') == 1)
        next_x = straight_x;
        next_y = straight_y;
        next_orientation = orientation;
    elseif (~isempty(non_straight))
        random_index = randsample(size(non_straight,1),1);
        if (non_straight(random_index, 1) == x)
            if(non_straight(random_index,2) == y + 1)
                next_orientation = 0;
            else
                next_orientation = 180;
            end
        else
            if (non_straight(random_index, 1) == x + 1)
                next_orientation = 90;
            else
                next_orientation = 270;
            end
        end
        next_x = non_straight(random_index,1);
        next_y = non_straight(random_index,2);
    else
        if (ismember([straight_x,straight_y],option,'rows') == 1)
            next_x = straight_x;
            next_y = straight_y;
            next_orientation = orientation;
        else %it should not get in here ever.
            next_x = 1000;
            next_y = 1000;
            next_orientation = orientation;
        end
    end
end
end