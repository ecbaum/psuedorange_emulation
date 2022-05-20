clear all; clc; close all


gt_LLH = readtable('ground_truth_llh.csv');

gt_ECEF = gt_LLH;

for i = 1:size(gt_LLH,1)
    gt_ECEF{i,2:end} = GeodeticToECEF(gt_LLH{i,2:end});
end

%%

GNSS_msg = readtable('2021-05-17_HK_GNSS_Message_m8t_clk_corr');

GNSS_msg.GT_x = nan(size(GNSS_msg,1),1);
GNSS_msg.GT_y = nan(size(GNSS_msg,1),1);
GNSS_msg.GT_z = nan(size(GNSS_msg,1),1);

%%

for i = 1:size(GNSS_msg,1)
    [~,idx] = min(abs(GNSS_msg{i,2}-gt_ECEF{:,1}));
    GNSS_msg{i,14:16} = gt_ECEF{idx,2:4};
end

%%

GNSS_normalized = GNSS_msg;

for i = 1:size(GNSS_msg,1)
    gt_pos = GNSS_normalized{i,14:16};
    GNSS_normalized{i,10:12} = GNSS_normalized{i,10:12} - gt_pos;
end

GNSS_normalized(:,14:16) = [];
GNSS_normalized(:,7:9) = [];
GNSS_normalized(:,5) = []; 


%%

rec_bias = [];

for i = 1:size(GNSS_normalized,1)
    sat_pos = GNSS_normalized{i,6:8};
    pr = GNSS_normalized{i,4};
    rec_bias = [rec_bias, norm(sat_pos)-pr];
end