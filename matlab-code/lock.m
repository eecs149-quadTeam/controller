%Will return 1 if x or y is going to locked, 0 otherwise.
%being locked is defined as the scenario where all neighbors of (x,y) in the quadrant is traversed.  
function locked = lock(x, y, traversed, max_x, max_y)
if (isempty(traversed))
    locked = 0;
else
    i = 1;
    neighbor = [];
    min_x = 1;
    min_y = 1;
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
    j = 1;
    locked = 1;
    while (j <= size(neighbor,1))
        if (ismember(neighbor(j,:),traversed, 'rows') == 0)
            locked = 0;
        end
        j = j + 1;
    end
end
end