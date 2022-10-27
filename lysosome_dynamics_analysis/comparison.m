clc; clear; close all;

load('control_msd.mat');

indices = 1 : numel(ma.msd);
n_spots = numel(indices);
colors = jet(n_spots);

ma = ma.fitLogLogMSD(0.5);

r2fits = ma.loglogfit.r2fit;
alphas = ma.loglogfit.alpha;

figure;
ha = gca;
hold(ha, 'on');
for ii = 1 : 10%n_spots
    i = randi(n_spots);
    index = indices(i);
    
    msd_spot = ma.msd{index};
    if isempty( msd_spot )
        continue
    end
    
    trackName = sprintf('Track %d', index );
    
    t = msd_spot(:,1);
    m = msd_spot(:,2);
    
    
    track = ma.tracks{index};
    trackName = sprintf('Track %d', index );

    hps(i) = plot(ha, t, m, ...
            'Color', colors(i,:), ...
            'DisplayName', trackName );
    text(t(31-ii), m(31-ii)+0.1, num2str(ii), 'Color', colors(i,:), 'FontSize', 24);
    alphas(index)
end
xlim([0 5]);
ma.labelPlotMSD(ha);

load('starvation_msd.mat');

indices = 1 : numel(ma.msd);
n_spots = numel(indices);
colors = jet(n_spots);

ma = ma.fitLogLogMSD(0.5);

r2fits = ma.loglogfit.r2fit;
alphas = ma.loglogfit.alpha;

figure;
ha = gca;
hold(ha, 'on');
for ii = 1 : 10%n_spots
    i = randi(n_spots);
    index = indices(i);
    
    msd_spot = ma.msd{index};
    if isempty( msd_spot )
        continue
    end
    
    trackName = sprintf('Track %d', index );
    
    t = msd_spot(:,1);
    m = msd_spot(:,2);
    
    track = ma.tracks{index};
    trackName = sprintf('Track %d', index );

    hps(i) = plot(ha, t, m, ...
            'Color', colors(i,:), ...
            'DisplayName', trackName );
    text(t(31-ii), m(31-ii)+0.1, num2str(ii), 'Color', colors(i,:), 'FontSize', 24);
    alphas(index)
end
xlim([0 5]);
ma.labelPlotMSD(ha);