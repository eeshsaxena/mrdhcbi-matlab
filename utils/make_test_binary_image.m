function BI = make_test_binary_image(type, X, Y)
% MAKE_TEST_BINARY_IMAGE  Generate a synthetic binary test image.
%
%   BI = make_test_binary_image(type, X, Y)
%
%   type : 'checkerboard' | 'random' | 'text' | 'gradient'
%   X, Y : image dimensions (rows, cols)

switch lower(type)
    case 'checkerboard'
        [cols, rows] = meshgrid(1:Y, 1:X);
        block = 8;
        BI = uint8(mod(floor((rows-1)/block) + floor((cols-1)/block), 2));
    case 'random'
        BI = uint8(randi([0,1], X, Y));
    case 'gradient'
        [cols, ~] = meshgrid(1:Y, 1:X);
        BI = uint8(cols > Y/2);
    case 'text'
        % Simple letter 'A' pattern at low resolution
        BI = uint8(zeros(X, Y));
        cx = round(X/2); cy = round(Y/2);
        r  = round(min(X,Y) * 0.35);
        for x = 1:X
            for y = 1:Y
                dx = x - cx; dy = y - cy;
                if abs(dx) <= r && abs(dy) <= r
                    if abs(dx) > r*0.6 || abs(dy) < r*0.05
                        BI(x,y) = 1;
                    end
                end
            end
        end
    otherwise
        error('Unknown type: %s', type);
end
end
