function metrics = compute_metrics(BI_original, BI_recovered, secret_bits_in, secret_bits_out)
% COMPUTE_METRICS  Compute evaluation metrics for the MRDHCBI scheme.
%
%   metrics = compute_metrics(BI_original, BI_recovered, secret_bits_in, secret_bits_out)
%
%   Returns a struct with fields:
%     .lossless_recovery  : logical, true if BI_recovered == BI_original exactly
%     .pixel_error_rate   : fraction of pixels that differ
%     .bit_error_rate     : BER of extracted vs. original secret bits
%     .embedding_rate_bpp : bits embedded per pixel of the ORIGINAL image

% Image recovery check
diff_pixels = sum(BI_original(:) ~= BI_recovered(:));
metrics.lossless_recovery = (diff_pixels == 0);
metrics.pixel_error_rate  = diff_pixels / numel(BI_original);

% Secret data extraction quality
nb = min(numel(secret_bits_in), numel(secret_bits_out));
bit_errors = sum(secret_bits_in(1:nb) ~= secret_bits_out(1:nb));
metrics.bit_error_rate = bit_errors / nb;

% Embedding rate: 1 bit embedded per original pixel per data hider
metrics.embedding_rate_bpp = 1.0; % bits per original-image pixel
end
