%pick destination quadrants and destination locations that are not quadrant or not in quadrants_tranversed 
%with some probability; x_dest and y_dest are global coordinates
function [destination_quadrant, x_dest, y_dest] = calculate_next_quad(quadrant, quadrants_traversed, size_x, size_y)
QUADRANT1 = 1; %1 corresponds to top left
QUADRANT2 = 2; %2 corresponds to top right
QUADRANT3 = 3; %3 corresponds to bottom left
QUADRANT4 = 4; %4 corresponds to bottom right
quads = [QUADRANT1, QUADRANT2, QUADRANT3, QUADRANT4];
options = quads(~ismember(quads, [quadrants_traversed, quadrant]));
destination_quadrant= options(randsample(size(options,2),1));
dest_options = edge_destination(quadrant, destination_quadrant, size_x, size_y);
result = dest_options(randsample(size(dest_options,1),1),:);
x_dest = result(1);
y_dest = result(2);
end