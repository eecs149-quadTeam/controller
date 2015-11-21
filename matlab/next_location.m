function [xnext, ynext]= next_location(xg1,yg1,x_dest,y_dest)
    if (x_dest > xg1 + 1)
        xnext = xg1 + 1;
        ynext = yg1;
    elseif (x_dest + 1< xg1)
        xnext = xg1 -1;
        ynext = yg1;
    elseif (y_dest > yg1)
        xnext = xg1;
        ynext = yg1 + 1;
    elseif (y_dest < yg1)
        xnext = xg1;
        ynext = yg1 - 1;
    elseif (x_dest == xg1 + 1)
        xnext = xg1 + 1;
        ynext = yg1;
    elseif (x_dest == xg1 -1)
        xnext = xg1 - 1;
        ynext = yg1;
    else
        xnext = xg1;
        ynext = yg1;
    end
end