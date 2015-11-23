function dest_options = edge_destination(quadrant, destination_quadrant, size_x, size_y)
QUADRANT1 = 1; %1 corresponds to top left
QUADRANT2 = 2; %2 corresponds to top right
QUADRANT3 = 3; %3 corresponds to bottom left
QUADRANT4 = 4; %4 corresponds to bottom right
switch (quadrant)
    case QUADRANT1
        switch(destination_quadrant)
           case QUADRANT2
               counter = 1;
               while (counter <= size_y/2)
                   dest_options(counter,:) = [size_x/2 + 1, size_y/2 + counter];
                   counter = counter + 1;
               end
           case QUADRANT3
               counter = 1;
               while (counter <= size_x/2)
                   dest_options(counter,:) = [counter, size_y/2];
                   counter = counter + 1;
               end
           case QUADRANT4
               counter = 1;
               while (counter <= size_x/2)
                   dest_options(counter,:) = [counter+size_x/2, size_y/2];
                   counter = counter + 1;
               end
               while (counter <= size_y/2 + size_x/2)
                   dest_options(counter,:) = [size_x/2 + 1, counter-size_x/2];
                   counter = counter + 1;
               end
               dest_options = unique(dest_options,'rows','stable');
        end
    case QUADRANT2
        switch(destination_quadrant)
           case QUADRANT1
               counter = 1;
               while (counter <= size_y/2)
                   dest_options(counter,:) = [size_x/2, size_y/2 + counter];
                   counter = counter + 1;
               end
           case QUADRANT3
               counter = 1;
               while (counter <= size_x/2)
                   dest_options(counter,:) = [counter, size_y/2];
                   counter = counter + 1;
               end
               while (counter <= size_y/2 + size_x/2)
                   dest_options(counter,:) = [size_x/2, counter-size_x/2];
                   counter = counter + 1;
               end
               dest_options = unique(dest_options,'rows','stable');
           case QUADRANT4
               counter = 1;
               while (counter <= size_x/2)
                   dest_options(counter,:) = [counter + size_x/2, size_y/2];
                   counter = counter + 1;
               end
        end
    case QUADRANT3
        switch(destination_quadrant)
            case QUADRANT1
                counter = 1;
                while (counter <= size_x/2)
                    dest_options(counter,:) = [counter, size_y/2 + 1];
                    counter = counter + 1;
                end
            case QUADRANT2
                counter = 1;
                while (counter <= size_x/2)
                    dest_options(counter,:) = [counter+size_x/2, size_y/2 + 1];
                    counter = counter + 1;
                end
                while (counter <= size_y/2 + size_x/2)
                    dest_options(counter,:) = [size_x/2 + 1, counter];
                    counter = counter + 1;
                end
                dest_options = unique(dest_options,'rows','stable');
            case QUADRANT4
                counter = 1;
                while (counter <= size_y/2)
                    dest_options(counter,:) = [size_x/2 + 1, counter];
                    counter = counter + 1;
                end
        end
    case QUADRANT4
        switch(destination_quadrant)
            case QUADRANT1
                counter = 1;
                while (counter <= size_x/2)
                    dest_options(counter,:) = [counter, size_y/2+1];
                    counter = counter + 1;
                end
                while (counter <= size_y/2 + size_x/2)
                    dest_options(counter,:) = [size_x/2, counter];
                    counter = counter + 1;
                end
                dest_options = unique(dest_options,'rows','stable');
            case QUADRANT2
                counter = 1;
                while (counter <= size_x/2)
                    dest_options(counter,:) = [counter + size_x/2, size_y/2 + 1];
                    counter = counter + 1;
                end
            case QUADRANT3
                counter = 1;
                while (counter <= size_y/2)
                    dest_options(counter,:) = [size_x/2, counter];
                    counter = counter + 1;
                end
        end
end
        