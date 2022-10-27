function [fusionIDX, OGTrackFrame, connect1, connect2, trackNum] = getFusionFrame(track,trackNum)
    if nnz(track(trackNum).fusion)>0
        fusionTrack = track(trackNum).fusion(track(trackNum).fusion>0);
        fusionFrame = track(trackNum).frame(track(trackNum).fusion>0)+1;
        OGTrackFrame = track(fusionTrack).frame(track(fusionTrack).frame==fusionFrame);
        while isempty(OGTrackFrame) && fusionFrame < 10000
            fusionFrame = fusionFrame+1;
            OGTrackFrame = track(fusionTrack).frame(track(fusionTrack).frame==fusionFrame);
        end

        if fusionFrame == 10000
            fusionIDX = 0;
            OGTrackFrame = 0;
            connect1 = [0, 0];
            connect2 = [0, 0];
            return
        end
        fusionIDX = find(track(trackNum).fusion>0);

        interval_frame = OGTrackFrame - fusionIDX;
        
        if interval_frame < 5
            fusionIDX = 0;
            OGTrackFrame = 0;
            connect1 = [0, 0];
            connect2 = [0, 0];
            trackNum = 0;
            return;
        end
        
        OGTrackCentroid1 = track(fusionTrack).WeightedCentroid(find(track(fusionTrack).frame == OGTrackFrame)*2-1);
        OGTrackCentroid2 = track(fusionTrack).WeightedCentroid(find(track(fusionTrack).frame == OGTrackFrame)*2);
        connect1 = [track(trackNum).WeightedCentroid((fusionIDX)*2-1), OGTrackCentroid1];
        connect2 = [track(trackNum).WeightedCentroid((fusionIDX)*2), OGTrackCentroid2];
        
        
    else
        fusionIDX = 0;
        OGTrackFrame = 0;
        connect1 = [0, 0];
        connect2 = [0, 0];
        trackNum = 0;
    end
end