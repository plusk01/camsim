classdef Scene < handle
    %SCENE An object that contains scene elements
    %   A scene can contain elements such as points, planes, spheres, and
    %   cubes.
    
    properties
        points = []     % [...; x y z id; ...] (Nx4)
        planes = []     % [...; tl tr br bl id; ...] (Nx[4*3+1])
        spheres = []    % [...; center radius id; ...] (Nx5)
        
        F           % elements in the scene are defined w.r.t this frame
    end
    
    properties (Access = private)
        offset
        next_id=1   % next value of id to store with a scene element
    end
    
    methods
        function scene = Scene(F, offset)
           scene.F = F;
           scene.offset = offset;
        end
        
        function generatePoints(scene, N, spread)
            %GENERATEPOINTS Generate random 3D points for the scene
            % N         Number of points in the scene
            % spread    How much of a spread in [X Y Z]

            if nargin < 3, spread = [1 1 1]; end
            
            X = (rand(N,1)-0.5)*spread(1) + scene.offset(1);
            Y = (rand(N,1)-0.5)*spread(2) + scene.offset(2);
            Z = (rand(N,1)-0.5)*spread(3) + scene.offset(3);
            
            % Augment with each point's id
            pts = [X Y Z (scene.next_id:N)'];
            
            % Update next_id
            scene.next_id = scene.next_id + N;

            % Add to the list of scene points
            scene.points = [scene.points; pts];

        end
        
        function addPlane(scene, ptTL, ptTR, ptBR, ptBL)
            %ADDPLANE Add a plane to the scene
            
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
        
        function addSphere(scene, center, radius)
            %ADDSPHERE Add a sphere to the scene
            
            % Add in offset to center
            center = center + scene.offset;
            center = reshape(center, 1, 3);
            
            % Augment with plane's id
            sphere = [center radius scene.next_id];
            
            % Update next_id
            scene.next_id = scene.next_id + 1;
            
            scene.spheres = [scene.spheres; sphere];
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

                Scene.drawPoints(t, R, pts, scene.points(:,4));
            end
            % -------------------------------------------------------------
            
            % =============================================================
            % Scene Plane [...; tl tr br bl id; ...] (Nx[4*3+1])
            % =============================================================
            for i = 1:size(scene.planes,1)
                % Get plane vertices
                vert = scene.planes(i, 1:12);

                % reshape to match format of [tl; tr; br; bl]
                vert = reshape(vert, 3, 4)';

                % Get plane id
                id = scene.planes(i, 5);

                Scene.drawPlane(t, R, vert, id);
            end
            % -------------------------------------------------------------
            
            % =============================================================
            % Scene Sphere [...; center radius id; ...] (Nx5)
            % =============================================================
            for i = 1:size(scene.spheres,1)
                
                % Break out center/radius
                center = scene.spheres(i,1:3);
                radius = scene.spheres(i,4);
                id = scene.spheres(i,5);
                
                Scene.drawSphere(t, R, center, radius, id);
            end
        end
    end
    
    methods(Static)
        function drawPoints(O, R, pts, ids)
        %DRAWPOINTS Draws a set of points

            % Rotate and then translate so that the pts that were expressed in the
            % local scene coordinate frame are now expressed in the frame that we
            % are drawing in.
            pts = (R'*pts')' + repmat(O',length(pts),1);

            X = pts(:,1);
            Y = pts(:,2);
            
            if size(pts,2) == 3
                Z = pts(:,3);
            else
                Z = zeros(length(pts),1);
            end

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
        
        function drawSphere(O, R, center, radius, id)
            %DRAWSPHERE Draw a sphere
            
            % Rotate and then translate so that the pts that were expressed in the
            % local scene coordinate frame are now expressed in the frame that we
            % are drawing in.
            center = R'*center' + O;
            
            if length(center) == 3
                % Generate a sphere in the scene coordinate frame
                [X,Y,Z] = sphere;

                % Shift and scale so that sphere is parameterized by center and
                % radius given by user
                X = X*radius + center(1);
                Y = Y*radius + center(2);
                Z = Z*radius + center(3);

                surf(X,Y,Z, 'EdgeColor','interp');
            else
                th = 0:pi/50:2*pi;
                xunit = radius * cos(th) + center(1);
                yunit = radius * sin(th) + center(2);
                plot3(xunit, yunit, zeros(length(xunit),1));               
            end
        end
    end
    
end

function printIDs(X,Y,Z,ids)
%PRINTIDS Print the id as a string in the given location

    % Plot the IDs next to the point
    b = num2str(ids); c = cellstr(b);
    % displacement so the text does not overlay the data points
    dx = 0.1; dy = 0.1; dz = 0.1;
    text(X+dx, Y+dy, Z+dz, c, 'FontSize', 6);
end