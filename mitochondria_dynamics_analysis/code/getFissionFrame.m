function [OGTrackFrame, end_frame, connect1, connect2, trackNum] = getFissionFrame(track,trackNum)
    if nnz(track(trackNum).fission)>0
        fissionTrack = track(trackNum).fission(track(trackNum).fission>0);
        fissionFrame = track(trackNum).frame(track(trackNum).fission>0)-1;
        OGTrackFrame = track(fissionTrack).frame(track(fissionTrack).frame==fissionFrame);
        while isempty(OGTrackFrame)
            fissionFrame = fissionFrame-1;
            OGTrackFrame = track(fissionTrack).frame(track(fissionTrack).frame==fissionFrame);
        end

        interval_frame = track(trackNum).frame(1) - OGTrackFrame;
        end_frame = track(trackNum).frame(1);
        if interval_frame < 5
            OGTrackFrame = 0;
            end_frame = 0;
            connect1 = [0, 0];
            connect2 = [0, 0];
            trackNum = 0;
            return;
        end
        
        OGTrackCentroid1 = track(fissionTrack).WeightedCentroid(find(track(fissionTrack).frame == OGTrackFrame)*2-1);
        OGTrackCentroid2 = track(fissionTrack).WeightedCentroid(find(track(fissionTrack).frame == OGTrackFrame)*2);
        connect1 = [OGTrackCentroid1,track(trackNum).WeightedCentroid(1)];
        connect2 = [OGTrackCentroid2,track(trackNum).WeightedCentroid(2)];
    else
        OGTrackFrame = 0;
        end_frame = 0;
        connect1 = [0, 0];
        connect2 = [0, 0];
        trackNum = 0;
    end
end