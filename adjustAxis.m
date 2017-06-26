function adjustAxis(x, y, z)
%ADJUSTAXIS Just keep the size of the axes big enough for current data

    if nargin == 1
        z = x(3);
        y = x(2);
        x = x(1);
    end

    ax = axis;
    x = [min(x(:)) max(x(:)) ax(1) ax(2)];
    y = [min(y(:)) max(y(:)) ax(3) ax(4)];
    if length(ax) == 6
        z = [min(z(:)) max(z(:)) ax(5) ax(6)];
    end

    % Margin on axis
    m = 2;
    axis([min(x(:))-m  max(x(:))+m  min(y(:))-m  max(y(:))+m  min(z(:))-m  max(z(:))+m]);
    axis equal;

end
