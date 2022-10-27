function flag = plotFusionEventsApp(track,trackNum)
if nnz(track(trackNum).fusion)>0
    fusionTrack = track(trackNum).fusion(track(trackNum).fusion>0);
    fusionFrame = track(trackNum).frame(track(trackNum).fusion>0)+1;
    OGTrackFrame = track(fusionTrack).frame(track(fusionTrack).frame==fusionFrame);
    while isempty(OGTrackFrame) && fusionFrame < 10000
        fusionFrame = fusionFrame+1;
        OGTrackFrame = track(fusionTrack).frame(track(fusionTrack).frame==fusionFrame);
    end

    if fusionFrame == 10000
        return
    end

    fusionIDX = find(track(trackNum).fusion>0);
    OGTrackCentroid1 = track(fusionTrack).WeightedCentroid(find(track(fusionTrack).frame == OGTrackFrame)*2-1);
    OGTrackCentroid2 = track(fusionTrack).WeightedCentroid(find(track(fusionTrack).frame == OGTrackFrame)*2);
    connect1 = [OGTrackCentroid1,track(trackNum).WeightedCentroid((fusionIDX)*2-1)];
    connect2 = [OGTrackCentroid2,track(trackNum).WeightedCentroid((fusionIDX)*2)];
    
    interval_frame = OGTrackFrame - fusionIDX;
    if interval_frame < 5
        flag = 0;
        return;
    end
    plot(connect1,connect2,':h','LineWidth',4,'Color','#77AC30')
    flag = 1;
else
    flag = 0;
end
end