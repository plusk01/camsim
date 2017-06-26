classdef Frame
    %FRAME Create an object that represents a coordinate frame
    %   All created frames are with respect to the standard right-handed
    %   3-axis Euclidean coordinate frame, i.e., X-Y-Z with origin at
    %   (0,0,0)^T. Therefore, when creating a new coordinate frame object
    %   you must provide the ctor with the position of your new frame with
    %   respect to (0, 0, 0) and an orientation with respect to X-Y-Z.
    %
    %   For example:
    %
    %   To create a camera frame that is at (1,2,3) in the world frame, you
    %   would create a new Frame as
    %       Fc = Frame([1 2 3], [0 -1 0; 0 0 -1; 1 0 0]);
    %
    %   If you would like to create a new frame w.r.t a frame other than
    %   the standard Euclidean world frame, you may pass in a third
    %   parameter which is a Frame object that describes the frame you are
    %   expressing the origin position and orientation relative to.
    
    properties
        base    % If isempty(base), then this frame is the anchor/root
        name    % Name of this frame.
        
        k = 2 % size of axes
        
        % The following properties define how to get to the new frame from
        % the frame it was defined w.r.t (i.e., the world by default)
        O  	% Origin of frame w.r.t to base_frame
        R  	% Orientation of frame w.r.t base_frame: R_base2me
    end
    
    methods
        function F = Frame(name, position, orientation, wrtF)
            % Enforce column vectors
            if size(position) == size(zeros(1,3)), position=position'; end
            
            % If this frame is being defined w.r.t a base frame, store it.
            if nargin == 4, F.base = wrtF; end
            
            F.name = name;
            F.O = position;
            F.R = orientation;
        end
        
        function b = eq(A,B)
            %EQ Check if two frames are equal
            %   If two frames have the same origin, orientation, and base
            %   then they are considered equal.
            
            b = (all(A.O == B.O) && all(A.R(:) == B.R(:)));
            
            if ~isempty(A.base) && ~isempty(B.base)
                b = (A.base == B.base);
            elseif ~isempty(A.base) || ~isempty(B.base)
                b = 0;
            end
        end
        
        function [O, R] = express(F, wrtF)
            %EXPRESS Express the frame object w.r.t the given frame
            %   Returns the translation (O) and the orientation (R) of the
            %   frame F defined in frame wrtF.
            
            % If I'm trying to express myself w.r.t an empty frame, then
            % just return zeros.
            if isempty(wrtF)
                O = zeros(3, 1);
                R = eye(3);
                return;
            end
            
            % If wrtF is my parent
            if F.isparent(wrtF)
                [O,R] = F.expressWRTParent(wrtF);
                
            % If wrtF is myself
            elseif F == wrtF
                O = zeros(3,1);
                R = eye(3);
                
            % If wrtF is my child
            elseif wrtF.isparent(F)
                [t_pc, R_p2c] = wrtF.expressWRTParent(F);
                
                % Now we need to flip the vector to point from child (wrtF)
                % to parent (F), and then rotate into the child's
                % coordinate frame.
                O = R_p2c*(-t_pc);
                
                % The orientation was defined starting from parent to
                % child, but in this case we want the orientation of the
                % parent starting from the child's frame.
                R = R_p2c';
                
            % I'm not connected to wrtF
            else
                O = inf(3,1);
                R = eye(3);
            end
        end
        
        function anchor = getAnchor(F)
            %GETANCHOR Find the anchor of all the coordinate frames
            %   The anchor frame is the frame that has no base frame,
            %   i.e., base = []. The anchor frame is defined in the MATLAB
            %   world plotting frame. Anchor frame is also called root.
            anchor = F;
            while 1
                if ~isempty(anchor.base)
                    anchor = anchor.base;
                else
                    break;
                end
            end
        end
        
        function draw(F, varargin)
            %DRAW Plot the coordinate frame origin and orientation
            %   Draw the coordinate frame w.r.t the anchor/root frame            
            
            % Argument defaults
            wrtF = F.getAnchor();
            colorspec = 'k';
            
            % Parse arguments
            for i = 1:(nargin-1)
                if isa(varargin{i}, 'Frame'), wrtF = varargin{i}; end
                if ischar(varargin{i}), colorspec = varargin{i}; end
            end
            
            % Find the rotation from this frame to the wrt frame
            [origin, orientation] = F.express(wrtF);

            plotCoordinateFrame(wrtF.name, origin, orientation,...
                                    colorspec, F.k);
            adjustAxis(origin);
        end
    end
    
    methods (Access = private)
        function b = isparent(F, query)
            %ISPARENT Determine if query is a parent of the current frame
            %   Returns a logical
            
            % initialize to false
            b = 0;
            
            % initialize parent search variable
            parent = F.base;
            
            while 1
                % I've exhausted the tree and couldn't find query frame
                if isempty(parent), break; end

                if query == parent
                    b = 1;
                    break;
                else
                    parent = parent.base;
                end
            end
        end
        
        function [O, R] = expressWRTParent(F, wrtF)
            %EXPRESSWRTPARENT Express frame F w.r.t the given frame
            %   This method expects that wrtF is a parent (base) of F.
            %
            %   A translation (O) and orientation (R) is returned defined
            %   in the coordinate frame of the parent (wrtF) frame. If the
            %   opposite is wanted (i.e., wrtF defined in the F frame) then
            %   one can obtain this transformation by 
            %
            %       t_cp  = R_p2c*(-t_pc)   % flip the vector
            %       R_c2p = R_p2c'          % opposite orientation
            
            % =============================================================
            % Base Cases
            % =============================================================
            
            % If expressing myself w.r.t my base, just return my origin and
            % orientation because those are defined w.r.t my base.
            % Do the same if my base is empty -- meaning my base is the
            % MATLAB plotting world.
            if isempty(F.base) || wrtF == F.base
                O = F.O;
                R = F.R;
                return;
            end
            
            % =============================================================
            % Recursion
            % =============================================================
            
            % Get the rotation and translation from wrtF to my Frame's base
            [t,R] = F.base.express(wrtF);
            
            % Since my origin (i.e., the translation from my base to my
            % origin) is defined w.r.t to my base, I first rotate my
            % origin translation vector (F.O) into the coordinate frame of
            % wrtF and then add the translation (t) from wrtF to my base.
            O = R'*F.O + t;
            R = F.R*R;
        end
    end
    
end

function plotCoordinateFrame(name, O, R, cs, k)
%PLOTCOORDINATEFRAME Plot a coordinate frame origin and orientation
%   Coordinate frames have a origin and an orientation. This function draws
%   the coordinate axes in a common frame.

    % cs    Color spec of frame (filled sphere at origin)
    % k     Size of each axis

    if nargin == 1, R = eye(3); end

    % Create coordinate axes starting at 0
    kk = linspace(0,k,100);
    CX = [kk; zeros(1,length(kk)); zeros(1,length(kk))];
    CY = [zeros(1,length(kk)); kk; zeros(1,length(kk))];
    CZ = [zeros(1,length(kk)); zeros(1,length(kk)); kk];
    
    % First rotate the coordinate frame from the local frame to the
    % orientation of the desired frame in which we want to plot.
    CX = R'*CX;
    CY = R'*CY;
    CZ = R'*CZ;
    
    % Then translate this frame to its origin
    CX = repmat(O, 1, size(CX,2)) + CX;
    CY = repmat(O, 1, size(CY,2)) + CY;
    CZ = repmat(O, 1, size(CZ,2)) + CZ;
    
    % Plot the axes
    hold on; ls = '-';
    plot3(CX(1,:), CX(2,:), CX(3,:),'color','r','linewidth',2,'linestyle',ls);
    plot3(CY(1,:), CY(2,:), CY(3,:),'color','g','linewidth',2,'linestyle',ls);
    plot3(CZ(1,:), CZ(2,:), CZ(3,:),'color','b','linewidth',2,'linestyle',ls);
    scatter3(O(1), O(2), O(3), cs, 'filled');
    
    % Margin on axis
    adjustAxis(CX, CY, CZ);
    view(-30, 30); axis square; grid on;
    xlabel(sprintf('X^{%s}',name)); ylabel(sprintf('Y^{%s}',name)); zlabel(sprintf('Z^{%s}',name))

end