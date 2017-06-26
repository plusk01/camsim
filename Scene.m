classdef Scene < handle
    %SCENE An object that contains scene elements
    %   A scene can contain elements such as points, planes, spheres, and
    %   cubes.
    
    properties
        points = []     % [...; x y z id; ...] (Nx4)
        planes = []     % [...; tl tr br bl id; ...] (Nx[4*3+1])
    end
    
    properties (Access = private)
        F           % elements in the scene are defined w.r.t this frame
        offset
        next_id=1   % next value of id to store with a scene element
    end
    
    methods
        function scene = Scene(F, offset)
           scene.F = F;
           scene.offset = offset;
        end
        
        function generatePoints(scene, N)
            %GENERATEPOINTS Generate random 3D points for the scene
            % N     Number of points in the scene
                      
            X = (rand(N,1)-0.5)*10 + scene.offset(1);
            Y = (rand(N,1)-0.5)*10 + scene.offset(2);
            Z = (rand(N,1)-0.5)*20 + scene.offset(3);
            
            % Augment with each point's id
            pts = [X Y Z (scene.next_id:N)'];
            
            % Update next_id
            scene.next_id = scene.next_id + N;

            % Add to the list of scene points
            scene.points = [scene.points; pts];

        end
        
        function addPlane(scene, ptTL, ptTR, ptBR, ptBL)
            %ADDPLANE Add a ScenePlane to the scene
            
            % Offset the points and then express in the world frame
            pts = [ptTL; ptTR; ptBR; ptBL] + scene.offset;
            
            % Reshape to fit plane format (row of [tl tr br bl])
            pts = reshape(pts', 1, 12);
            
            % Augment with plane's id
            plane = [pts scene.next_id];
            
            % Update next_id
            scene.next_id = scene.next_id + 1;
            
            scene.planes = [scene.planes; plane];
        end
        
        function draw(scene)
            %DRAW Draw the scene
            
            hold on;
            
            wrtF = scene.F.getAnchor();
            
            % Get the origin vector and orientation matrix of
            % the scene frame defined in the wrtF frame.
            [t,R] = scene.F.express(wrtF);
            
            % =============================================================
            % Scene Points [...; x y z id; ...] (Nx4)
            % =============================================================
            if ~isempty(scene.points)
                
                % The fourth column is just the id
                pts = scene.points(:, 1:3);

                drawPoints(t, R, pts, scene.points(:,4));
            end
            % -------------------------------------------------------------
            
            % =============================================================
            % Scene Plane [...; tl tr br bl id; ...] (Nx[4*3+1])
            % =============================================================
            if ~isempty(scene.planes)
                for i = 1:size(scene.planes,1)
                    % Get plane vertices
                    vert = scene.planes(i, 1:12);
                    
                    % reshape to match format of [tl; tr; br; bl]
                    vert = reshape(vert, 3, 4)';
                    
                    % Get plane id
                    id = scene.planes(i, 5);
                    
                    drawPlane(t, R, vert, id);
                end
            end
            % -------------------------------------------------------------
        end
    end
    
end

function drawPoints(O, R, pts, ids)
%DRAWPOINTS Draws a set of points

    % Rotate and then translate so that the pts that were expressed in the
    % local scene coordinate frame are now expressed in the frame that we
    % are drawing in.
    pts = (R'*pts')' + repmat(O',length(pts),1);

    X = pts(:,1);
    Y = pts(:,2);
    Z = pts(:,3);

    scatter3(X,Y,Z,10);
    adjustAxis(X,Y,Z);

    printIDs(X,Y,Z,ids);
end

function drawPlane(O, R, vert, id)
%DRAWPLANE Draws one plane

    % Rotate and then translate so that the pts that were expressed in the
    % local scene coordinate frame are now expressed in the frame that we
    % are drawing in.
    vert = (R'*vert')' + repmat(O',4,1);

    Faces = [ 4 3 2 1 ];

    colors = [1 0 0];

    patch('Vertices', vert, 'Faces', Faces,'FaceVertexCData',colors,...
            'FaceColor','flat','FaceAlpha',0.05);
        
%     printIDs(x,y,z,id)
end

function printIDs(X,Y,Z,ids)
%PRINTIDS Print the id as a string in the given location

    % Plot the IDs next to the point
    b = num2str(ids); c = cellstr(b);
    % displacement so the text does not overlay the data points
    dx = 0.1; dy = 0.1; dz = 0.1;
    text(X+dx, Y+dy, Z+dz, c, 'FontSize', 6);
end