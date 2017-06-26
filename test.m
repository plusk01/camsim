clear, clc;

% Create some rotations that will be used to define coordinate frames
Ra_to_b = [0 1 0; -1 0 0; 0 0 1]; % From a to b
Rb_to_c = [0 1 0; -1 0 0; 0 0 1]; % From b to c
Rc_to_d = [0 1 0; -1 0 0; 0 0 1]; % From c to d

Ra_to_b = rotx(0)*roty(0)*rotz(pi/2);

% Create coordinate frame objects
Fa = Frame('a', [0 0 0], eye(3));
Fb = Frame('b', [-1 0 0], Ra_to_b, Fa);
Fc = Frame('c', [2 0 0], Rb_to_c, Fb);
Fd = Frame('d', [3 -5 -1], Rc_to_d, Fc);
    
figure(1), clf;

Fa.draw('r');
Fb.draw('g');
Fc.draw('b');
Fd.draw('y');

view(0, 90);