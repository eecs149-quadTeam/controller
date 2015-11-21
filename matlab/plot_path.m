function f = plot_path(path_taken);
i = 1;
while (i <= size(path_taken,1))
    if (i >= 2)
        plot(path_taken(i - 1,1), path_taken(i - 1,2), 'b.');
    end
    plot(path_taken(i,1), path_taken(i,2),'r.');
    title(i);
    axis([1 6 1 6])
    hold on;
    i = i + 1;
    pause
end
hold off