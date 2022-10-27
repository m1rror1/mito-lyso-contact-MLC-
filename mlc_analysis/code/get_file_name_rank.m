function rank = get_file_name_rank(N)
    if N < 10
        rank = ['000', num2str(N)];
    elseif N < 100
        rank = ['00', num2str(N)];
    elseif N < 1000
        rank = ['0', num2str(N)];
    else
        rank = num2str(N);
    end
end