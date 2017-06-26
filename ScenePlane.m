classdef ScenePlane < SceneElement
    %SCENEPLANE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        pts
    end
     
    methods
        function plane = ScenePlane(pts)
            plane.pts = pts;
            
            % pts = [TL; TR; BR; BL]
        end
        
        function draw(plane, pts)
            
            if nargin == 1
                pts = plane.pts;
            end
              
            Faces = [ 4 3 2 1 ];

            colors = [1 0 0];

            patch('Vertices', pts, 'Faces', Faces,'FaceVertexCData',colors,...
                    'FaceColor','flat','FaceAlpha',0.05)
        end
        
    end
    
end

