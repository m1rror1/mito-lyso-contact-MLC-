function [lyso, lyso_cell_num] = get_lyso_num_pos(csv_filter_table, cell, n)
    x0 = csv_filter_table(csv_filter_table(:, 1)==n, 2);
    y0 = csv_filter_table(csv_filter_table(:, 1)==n, 3);
    % get lysosome number and position in cell in every frame
    lyso_cell_num = 0;
    lyso = zeros(size(cell), class(cell));
    for i = 1:length(y0)
        lyso(y0(i), x0(i)) = 1;
        if cell(y0(i), x0(i)) > 0
            lyso_cell_num = lyso_cell_num + 1;
        end
    end
end