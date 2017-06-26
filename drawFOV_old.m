% function to draw camera fov
function handle = drawFov(pn, pe, pd, phi, theta, psi, az, el, handle, fov_x, fov_y, t)

    % rotation from gimbal to camera
    R_g2c = [ 0  1  0
              0  0  1
              1  0  0];
                           
    % define unit vectors along fov in the camera frame
    % here R_b_to_g is not actually rotating anything from gimbal to body,
    % it is just a convenient rotation for rotating the optical axis vector
    % to the corners of the FOV
    pts = [ (R_b_to_g( fov_x/2, fov_y/2)'*R_g2c'*[0;0;1])'     % top-right
            (R_b_to_g(-fov_x/2, fov_y/2)'*R_g2c'*[0;0;1])'     % top-left
            (R_b_to_g(-fov_x/2,-fov_y/2)'*R_g2c'*[0;0;1])'     % bot-left
            (R_b_to_g( fov_x/2,-fov_y/2)'*R_g2c'*[0;0;1])' ]'; % bot-right
        
    % transform from gimbal coordinates to the vehicle coordinates
    pts = R_v_to_b(phi,theta,psi)'*R_b_to_g(az,el)'*pts;

    % first vertex is at center of MAV vehicle frame
    Vert = [pn, pe, pd]; 
    
    % project field of view lines onto ground plane and make correction
    % when the projection is above the horizon
    for i = 1:4
        
        % alpha is the angle that the field-of-view line makes with horizon
        alpha = atan2(pts(3,i),norm(pts(1:2,i)));
        
        if alpha > 0
            
            % fov line is below horizon and intersects ground plane
            Vert = [...
                Vert
                [pn-pd*pts(1,i)/pts(3,i), pe-pd*pts(2,i)/pts(3,i), 0]
                ];
            
        elseif alpha < 0
            
            % fov line is above horizon and intersects some high plane
            Vert = [...
                Vert
                [pn+pd*pts(1,i)/pts(3,i), pe+pd*pts(2,i)/pts(3,i), pd*2]
                ];
            
        else

            % fov line exactly on horizon and intersects no plane
            Vert = [...
                Vert
                [pn+999*cos(fov_x), pe+999*sin(fov_x), pd]
                ];
            
        end
    end

    Faces = [ 1  1  2  3    % top face
              1  1  2  5    % right face
              1  1  5  4    % bottom face
              1  1  4  3    % left face
              2  3  4  5 ]; % footprint face

    colors = [[1 1 1]; [1 1 1]; [1 1 1]; [1 1 1]; [0 1 0]];

  if t == 0
    handle = patch('Vertices', Vert, 'Faces', Faces,...
                 'FaceVertexCData',colors,'FaceColor','flat',...
                 'FaceAlpha',0.05);
  else
    set(handle,'Vertices',Vert,'Faces',Faces);
  end
  
end

%% Rotation Matrices
% rotation from vehicle to body coordinates
function R = R_v_to_b(phi,theta,psi)

    R_v_to_v1 = [ cos(psi)  sin(psi)  0
                 -sin(psi)  cos(psi)  0
                     0         0      1];
    
    R_v1_to_v2 = [ cos(theta)  0 -sin(theta)
                      0        1     0
                   sin(theta)  0  cos(theta)];
    
    R_v2_to_b = [ 1     0         0
                  0  cos(phi)  sin(phi)
                  0 -sin(phi)  cos(phi)];
    
    R = R_v2_to_b * R_v1_to_v2 * R_v_to_v1;
end


% rotation from body to gimbal coordinates
function R = R_b_to_g(az,el)

    R_b_to_g1 = [ cos(az)  sin(az)  0
                 -sin(az)  cos(az)  0
                     0        0     1];

    R_g1_to_g = [ cos(el)  0 -sin(el)
                     0     1     0
                  sin(el)  0  cos(el)];

    R = R_g1_to_g * R_b_to_g1;
end

% transform from gimbal to camera coordinates
function R = R_g_to_c()
    R = [0 1 0
         0 0 1
         1 0 0];
end