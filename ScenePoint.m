classdef ScenePoint < SceneElement
    %SCENEPOINT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        id, X, Y, Z, pt
    end
    
    methods
        function spt = ScenePoint(pt, id)
            spt.id = id;
            
            spt.pt = pt;
            
            spt.X = pt(1);
            spt.Y = pt(2);
            spt.Z = pt(3);
        end
    end
    
end

